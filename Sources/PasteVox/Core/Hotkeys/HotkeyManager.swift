import AppKit
import Foundation

@MainActor
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    @Published private(set) var isRunning = false
    @Published private(set) var isPressed = false
    @Published private(set) var statusMessage = "Hotkey monitor stopped."
    @Published private(set) var lastEvent: HotkeyEvent?
    @Published private(set) var lastTranscript = ""
    @Published private(set) var lastProcessedText = ""
    @Published private(set) var lastError = ""
    @Published private(set) var lastPasteStatus = "No paste yet."
    @Published private(set) var lastTranscriptionModeStatus = "No transcription yet."

    private var lastDeliverableText = ""
    private var lastDeliverableWasRisky = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var keyEventTap: CFMachPort?
    private var keyEventTapRunLoopSource: CFRunLoopSource?
    private var hotkeyHealthTask: Task<Void, Never>?
    private var maxRecordingTask: Task<Void, Never>?
    private let transcriber = OpenAIFileTranscriber()
    private let realtimeTranscriber = OpenAIRealtimeTranscriber()
    private let postProcessor = PromptPostProcessor()

    private let minimumRecordingDurationMs = 300
    private let silencePeakLevelThreshold = 0.14
    private let maximumRecordingDurationSeconds: UInt64 = 120
    private var hotkeyPressedAt: Date?
    private var hotkeyReleasedAt: Date?
    private var recordingStartedAt: Date?
    private var effectiveTranscriptionMode: TranscriptionMode = .fileUploadAfterRelease
    private var currentPasteTarget: PasteTarget?
    private var currentEffectivePromptMode: PromptMode?
    private var modeSwitchDuringHold = false

    private init() {}

    func start() {
        guard !isRunning else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            if event.type == .keyDown,
               Task.isCancelled == false,
               let self,
               MainActor.assumeIsolated({ self.shouldConsumeModeSwitchKey(event) })
            {
                Task { @MainActor in self.handleKeyDown(event) }
                return nil
            }

            Task { @MainActor in
                if event.type == .flagsChanged {
                    self?.handleFlagsChanged(event)
                } else if event.type == .keyDown {
                    self?.handleKeyDown(event)
                }
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            Task { @MainActor in
                if event.type == .flagsChanged {
                    self?.handleFlagsChanged(event)
                } else if event.type == .keyDown {
                    self?.handleKeyDown(event)
                }
            }
        }

        installKeyEventTap()
        startHotkeyHealthWatchdog()

        isRunning = true
        statusMessage = AppSettings.shared.fnHoldToRecordEnabled
            ? "Hotkey monitor running: hold \(AppSettings.shared.holdHotkeyKind.shortTitle) to record."
            : "Hold-to-record paused. Press Fn+` to resume."
        LocalLogger.shared.info("Hotkey monitor started kind=fnHold")
    }

    func resetTransientModeState() {
        currentPasteTarget = nil
        currentEffectivePromptMode = nil
        modeSwitchDuringHold = false
        LocalLogger.shared.info("hotkey transient mode state reset")
    }

    func restart() {
        stop()
        start()
        LocalLogger.shared.info("hotkey monitor restarted")
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let keyEventTapRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), keyEventTapRunLoopSource, .commonModes)
        }
        if let keyEventTap {
            CGEvent.tapEnable(tap: keyEventTap, enable: false)
        }
        globalMonitor = nil
        localMonitor = nil
        keyEventTap = nil
        keyEventTapRunLoopSource = nil
        hotkeyHealthTask?.cancel()
        hotkeyHealthTask = nil
        maxRecordingTask?.cancel()
        maxRecordingTask = nil
        isRunning = false
        isPressed = false
        currentPasteTarget = nil
        currentEffectivePromptMode = nil
        modeSwitchDuringHold = false
        statusMessage = "Hotkey monitor stopped."
        LocalLogger.shared.info("Hotkey monitor stopped")
    }

    private func installKeyEventTap() {
        guard keyEventTap == nil else { return }
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: HotkeyManager.keyEventTapCallback,
            userInfo: userInfo
        ) else {
            LocalLogger.shared.error("key_event_tap install_failed accessibility_trusted=\(PermissionsManager.shared.isAccessibilityTrusted(prompt: false))")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        keyEventTap = tap
        keyEventTapRunLoopSource = source
        LocalLogger.shared.info("key_event_tap installed purpose=consume_fn_shortcuts_and_hold_flags")
    }

    private func startHotkeyHealthWatchdog() {
        hotkeyHealthTask?.cancel()
        hotkeyHealthTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard isRunning else { continue }
                repairKeyEventTapIfNeeded()
            }
        }
    }

    private func repairKeyEventTapIfNeeded() {
        if let keyEventTap, !CFMachPortIsValid(keyEventTap) {
            LocalLogger.shared.error("key_event_tap invalid restarting accessibility_trusted=\(PermissionsManager.shared.isAccessibilityTrusted(prompt: false))")
            if let keyEventTapRunLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), keyEventTapRunLoopSource, .commonModes)
            }
            self.keyEventTap = nil
            self.keyEventTapRunLoopSource = nil
            installKeyEventTap()
            return
        }

        if let keyEventTap {
            CGEvent.tapEnable(tap: keyEventTap, enable: true)
        } else if PermissionsManager.shared.isAccessibilityTrusted(prompt: false) {
            LocalLogger.shared.info("key_event_tap missing reinstalling accessibility_trusted=true")
            installKeyEventTap()
        }
    }

    private func reenableKeyEventTap(reason: CGEventType) {
        guard let keyEventTap else {
            installKeyEventTap()
            return
        }
        CGEvent.tapEnable(tap: keyEventTap, enable: true)
        LocalLogger.shared.info("key_event_tap reenabled reason=\(reason.rawValue)")
    }

    nonisolated private static let shortcutKeyCodes: Set<CGKeyCode> = [
        18, 19, 20, 21,       // 1…4 modes
        23, 22, 26, 28, 25, 29, 27, // 5…0 and - styles
        50                    // ` / ~ hold-to-record toggle
    ]

    nonisolated private static let rightCommandDeviceFlag = CGEventFlags(rawValue: 0x00000010)
    nonisolated private static let rightOptionDeviceFlag = CGEventFlags(rawValue: 0x00000040)

    nonisolated private static func isShortcutKeyCode(_ keyCode: CGKeyCode) -> Bool {
        shortcutKeyCodes.contains(keyCode)
    }

    nonisolated private static func shortcutModifierMatches(flags: CGEventFlags) -> Bool {
        if flags.contains(.maskSecondaryFn) { return true }
        let holdHotkeyKind = UserDefaults.standard.string(forKey: "holdHotkeyKind") ?? HotkeyKind.fnHold.rawValue
        switch HotkeyKind(rawValue: holdHotkeyKind) ?? .fnHold {
        case .fnHold:
            return false
        case .rightOptionHold:
            return flags.contains(rightOptionDeviceFlag)
        case .rightCommandHold:
            return flags.contains(rightCommandDeviceFlag)
        }
    }

    private func shortcutModifierMatches(event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.function) { return true }
        switch AppSettings.shared.holdHotkeyKind {
        case .fnHold:
            return false
        case .rightOptionHold:
            return UInt64(event.modifierFlags.rawValue) & Self.rightOptionDeviceFlag.rawValue != 0
        case .rightCommandHold:
            return UInt64(event.modifierFlags.rawValue) & Self.rightCommandDeviceFlag.rawValue != 0
        }
    }

    nonisolated private static let keyEventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let userInfo {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
                Task { @MainActor in manager.reenableKeyEventTap(reason: type) }
            }
            return Unmanaged.passUnretained(event)
        }

        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .flagsChanged {
            Task { @MainActor in
                manager.handleFlagsChangedFromEventTap(keyCode: keyCode, flags: flags)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown, isShortcutKeyCode(keyCode), shortcutModifierMatches(flags: flags) else {
            return Unmanaged.passUnretained(event)
        }

        Task { @MainActor in
            manager.handleModeSwitchKeyCode(keyCode)
        }
        return nil
    }

    private func shouldConsumeModeSwitchKey(_ event: NSEvent) -> Bool {
        guard shortcutModifierMatches(event: event) else { return false }
        let key = event.charactersIgnoringModifiers ?? ""
        return isHoldToRecordToggleKey(event) || promptMode(for: key) != nil || writingStyle(for: key) != nil
    }

    private func handleKeyDown(_ event: NSEvent) {
        guard shouldConsumeModeSwitchKey(event) else { return }
        let key = event.charactersIgnoringModifiers ?? ""
        if isHoldToRecordToggleKey(event) {
            toggleFnHoldToRecord()
        } else if let mode = promptMode(for: key) {
            switchPromptMode(mode)
        } else if let style = writingStyle(for: key) {
            switchWritingStyle(style)
        }
    }

    private func handleModeSwitchKeyCode(_ keyCode: CGKeyCode) {
        if isHoldToRecordToggleKeyCode(keyCode) {
            toggleFnHoldToRecord()
        } else if let mode = promptMode(forKeyCode: keyCode) {
            switchPromptMode(mode)
        } else if let style = writingStyle(forKeyCode: keyCode) {
            switchWritingStyle(style)
        }
    }

    private func isHoldToRecordToggleKey(_ event: NSEvent) -> Bool {
        event.keyCode == 50 || event.charactersIgnoringModifiers == "`" || event.charactersIgnoringModifiers == "~"
    }

    private func isHoldToRecordToggleKeyCode(_ keyCode: CGKeyCode) -> Bool {
        keyCode == 50 // ANSI grave / tilde
    }

    private func toggleFnHoldToRecord() {
        modeSwitchDuringHold = true
        let isEnabled = !AppSettings.shared.fnHoldToRecordEnabled
        AppSettings.shared.fnHoldToRecordEnabled = isEnabled
        statusMessage = isEnabled
            ? "Hold-to-record resumed: \(AppSettings.shared.holdHotkeyKind.shortTitle)."
            : "Hold-to-record paused. Press Fn+` to resume."

        if AudioRecorder.shared.state == .recording {
            _ = try? AudioRecorder.shared.stopRecording()
            AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: false)
        }

        FloatingHUDController.shared.show(.modeChanged, message: isEnabled ? "Fn recording on" : "Fn recording off")
        LocalLogger.shared.info("fn_hold_to_record_toggled enabled=\(isEnabled)")
    }

    private func switchPromptMode(_ mode: PromptMode) {
        modeSwitchDuringHold = true
        currentPasteTarget = nil
        currentEffectivePromptMode = mode
        AppSettings.shared.promptMode = mode
        statusMessage = "Prompt mode switched to \(mode.title)."
        FloatingHUDController.shared.show(.modeChanged, message: "Mode: \(hudModeStyleLabel(for: mode))")

        if AudioRecorder.shared.state == .recording {
            _ = try? AudioRecorder.shared.stopRecording()
            AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: false)
        }

        LocalLogger.shared.info("prompt_mode_switched source=fn_number mode=\(mode.rawValue)")
    }

    private func promptMode(for key: String) -> PromptMode? {
        switch key {
        case "1": .rawDictation
        case "2": .agentPrompt
        case "3": .ralphPrompt
        case "4": .terminalCommand
        default: nil
        }
    }

    private func promptMode(forKeyCode keyCode: CGKeyCode) -> PromptMode? {
        switch keyCode {
        case 18: .rawDictation      // ANSI 1
        case 19: .agentPrompt      // ANSI 2
        case 20: .ralphPrompt      // ANSI 3
        case 21: .terminalCommand  // ANSI 4
        default: nil
        }
    }

    private func writingStyle(for key: String) -> WritingStyle? {
        switch key {
        case "5": .default
        case "6": .concise
        case "7": .friendly
        case "8": .formal
        case "9": .codingAgent
        case "0": .chat
        case "-": .email
        default: nil
        }
    }

    private func writingStyle(forKeyCode keyCode: CGKeyCode) -> WritingStyle? {
        switch keyCode {
        case 23: .default      // ANSI 5
        case 22: .concise      // ANSI 6
        case 26: .friendly     // ANSI 7
        case 28: .formal       // ANSI 8
        case 25: .codingAgent  // ANSI 9
        case 29: .chat         // ANSI 0
        case 27: .email        // ANSI -
        default: nil
        }
    }

    private func switchWritingStyle(_ style: WritingStyle) {
        modeSwitchDuringHold = true
        AppSettings.shared.writingStyle = style
        statusMessage = "Writing style switched to \(style.title)."
        let mode = AppSettings.shared.promptMode
        let suffix = styleApplies(to: mode) ? "" : " inactive"
        FloatingHUDController.shared.show(.modeChanged, message: "Style: \(style.shortTitle)\(suffix)")

        if AudioRecorder.shared.state == .recording {
            _ = try? AudioRecorder.shared.stopRecording()
            AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: false)
        }

        LocalLogger.shared.info("writing_style_switched source=fn_number style=\(style.rawValue)")
    }

    private func styleApplies(to mode: PromptMode) -> Bool {
        let settings = AppSettings.shared
        return settings.postProcessingEnabled
            && settings.postProcessingEnabledModes.contains(mode)
            && mode != .rawDictation
            && settings.writingStyle != .default
    }

    private func hudModeStyleLabel(for mode: PromptMode) -> String {
        let style = AppSettings.shared.writingStyle
        guard style != .default else { return mode.shortTitle }
        if styleApplies(to: mode) {
            return "\(mode.shortTitle) · \(style.shortTitle)"
        }
        return "\(mode.shortTitle) · style off"
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard let holdHotkeyIsDown = holdHotkeyState(from: event) else { return }
        applyHoldHotkeyState(holdHotkeyIsDown)
    }

    private func handleFlagsChangedFromEventTap(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let holdHotkeyIsDown = holdHotkeyState(keyCode: keyCode, flags: flags) else { return }
        applyHoldHotkeyState(holdHotkeyIsDown)
    }

    private func applyHoldHotkeyState(_ holdHotkeyIsDown: Bool) {
        if holdHotkeyIsDown && !isPressed {
            guard AppSettings.shared.fnHoldToRecordEnabled else {
                statusMessage = "Hold-to-record paused. Press Fn+` to resume."
                return
            }
            isPressed = true
            lastEvent = .pressed
            Task { await handlePress() }
        } else if !holdHotkeyIsDown && isPressed {
            isPressed = false
            lastEvent = .released
            Task { await handleRelease() }
        }
    }

    private func holdHotkeyState(from event: NSEvent) -> Bool? {
        switch AppSettings.shared.holdHotkeyKind {
        case .fnHold:
            return event.modifierFlags.contains(.function)
        case .rightOptionHold:
            guard event.keyCode == 61 else { return nil }
            return event.modifierFlags.contains(.option)
        case .rightCommandHold:
            guard event.keyCode == 54 else { return nil }
            return event.modifierFlags.contains(.command)
        }
    }

    private func holdHotkeyState(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool? {
        switch AppSettings.shared.holdHotkeyKind {
        case .fnHold:
            return flags.contains(.maskSecondaryFn)
        case .rightOptionHold:
            guard keyCode == 61 else { return nil }
            return flags.contains(Self.rightOptionDeviceFlag)
        case .rightCommandHold:
            guard keyCode == 54 else { return nil }
            return flags.contains(Self.rightCommandDeviceFlag)
        }
    }

    private func handlePress() async {
        hotkeyPressedAt = Date()
        lastError = ""
        lastTranscript = ""
        lastProcessedText = ""
        statusMessage = "\(AppSettings.shared.holdHotkeyKind.shortTitle) pressed: starting recording…"

        do {
            currentPasteTarget = PasteTarget.current
            currentEffectivePromptMode = AppAwareModeResolver.mode(for: currentPasteTarget) ?? AppSettings.shared.promptMode
            if let explanation = AppAwareModeResolver.explanation(for: currentPasteTarget, resolvedMode: currentEffectivePromptMode), currentEffectivePromptMode != AppSettings.shared.promptMode {
                LocalLogger.shared.info("app_aware_mode_switch \(explanation)")
            }

            LocalLogger.shared.info("recording_start requested mic_status=\(PermissionsManager.shared.microphonePermissionDescription().replacingOccurrences(of: " ", with: "_"))")
            try await AudioRecorder.shared.startRecording()
            recordingStartedAt = Date()
            FeedbackService.shared.recordingStarted()
            FloatingHUDController.shared.show(.listening, message: hudModeStyleLabel(for: currentEffectivePromptMode ?? AppSettings.shared.promptMode))
            statusMessage = "Recording while \(AppSettings.shared.holdHotkeyKind.shortTitle) is held…"
            scheduleMaximumRecordingTimeout()

            if AppSettings.shared.transcriptionMode == .realtimeMicrophoneStreaming {
                Task { @MainActor in
                    do {
                        try await realtimeTranscriber.startRealtimeMicrophone(
                            context: TranscriptionContext(promptMode: AppSettings.shared.promptMode, model: AppSettings.shared.sttModel.rawValue)
                        )
                        lastTranscriptionModeStatus = "Realtime microphone streaming started."
                    } catch {
                        lastTranscriptionModeStatus = "Realtime start failed; will use file upload fallback."
                        LocalLogger.shared.error("realtime_microphone_streaming start_failed fallback=file_upload error=\(error.localizedDescription)")
                    }
                }
            }
        } catch {
            lastError = error.localizedDescription
            statusMessage = error.localizedDescription
            LocalLogger.shared.error("recording_start failed error=\(error.localizedDescription)")
            FeedbackService.shared.error()
            FloatingHUDController.shared.show(.error, message: "Recording error")
        }
    }

    private func handleRelease() async {
        maxRecordingTask?.cancel()
        maxRecordingTask = nil
        hotkeyReleasedAt = Date()

        if modeSwitchDuringHold {
            modeSwitchDuringHold = false
            isPressed = false
            currentPasteTarget = nil
            currentEffectivePromptMode = nil
            return
        }
        var metrics = DictationMetrics()
        let targetAtPress = currentPasteTarget ?? PasteTarget.current
        let pasteTarget = AppSettings.shared.logPasteTargetApp ? targetAtPress : nil
        let effectivePromptMode = currentEffectivePromptMode ?? AppAwareModeResolver.mode(for: targetAtPress) ?? AppSettings.shared.promptMode
        defer {
            currentPasteTarget = nil
            currentEffectivePromptMode = nil
        }
        metrics.promptMode = effectivePromptMode
        effectiveTranscriptionMode = AppSettings.shared.transcriptionMode
        metrics.transcriptionMode = AppSettings.shared.transcriptionMode
        metrics.model = AppSettings.shared.sttModel.rawValue
        if let hotkeyPressedAt, let recordingStartedAt {
            metrics.hotkeyDownToRecordingStartedMs = Int(recordingStartedAt.timeIntervalSince(hotkeyPressedAt) * 1000)
        }

        do {
            let stopStartedAt = Date()
            let url = try AudioRecorder.shared.stopRecording()
            metrics.hotkeyUpToAudioFinalizedMs = Int(Date().timeIntervalSince(stopStartedAt) * 1000)
            metrics.recordingDurationMs = AudioRecorder.shared.lastRecordingDurationMs
            metrics.audioFileSizeBytes = AudioRecorder.shared.lastRecordingSizeBytes
            FeedbackService.shared.recordingEnded()
            FloatingHUDController.shared.show(.transcribing)

            guard let url else {
                statusMessage = "No active recording; ignored."
                metrics.errorType = "no_recording_ignored"
                MetricsStore.shared.add(metrics)
                addHistory(transcript: "", output: "", status: .ignored, statusMessage: "No active recording", target: pasteTarget, metrics: metrics)
                LocalLogger.shared.info("dictation ignored reason=no_recording")
                return
            }

            if AudioRecorder.shared.lastRecordingDurationMs < minimumRecordingDurationMs {
                statusMessage = "Recording too short; ignored."
                FloatingHUDController.shared.show(.modeChanged, message: "Too short")
                AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: AppSettings.shared.keepLastAudioForDebugging)
                metrics.errorType = "recording_too_short_ignored"
                MetricsStore.shared.add(metrics)
                addHistory(transcript: "", output: "", status: .ignored, statusMessage: "Recording too short", target: pasteTarget, metrics: metrics)
                LocalLogger.shared.info("dictation ignored reason=recording_too_short duration_ms=\(AudioRecorder.shared.lastRecordingDurationMs)")
                return
            }

            if AudioRecorder.shared.lastRecordingPeakLevel < silencePeakLevelThreshold {
                statusMessage = "No voice detected; ignored."
                FloatingHUDController.shared.show(.modeChanged, message: "No voice")
                AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: AppSettings.shared.keepLastAudioForDebugging)
                metrics.errorType = "no_voice_detected_ignored"
                MetricsStore.shared.add(metrics)
                addHistory(transcript: "", output: "", status: .ignored, statusMessage: "No voice detected", target: pasteTarget, metrics: metrics)
                LocalLogger.shared.info("dictation ignored reason=no_voice_detected duration_ms=\(AudioRecorder.shared.lastRecordingDurationMs) peak=\(String(format: "%.3f", AudioRecorder.shared.lastRecordingPeakLevel)) threshold=\(silencePeakLevelThreshold)")
                return
            }

            statusMessage = "Transcribing hotkey recording…"
            let transcriptionStartedAt = Date()
            let context = TranscriptionContext(promptMode: effectivePromptMode, model: AppSettings.shared.sttModel.rawValue)
            let result = try await transcribe(audioURL: url, context: context)
            metrics.transcriptionDurationMs = Int(Date().timeIntervalSince(transcriptionStartedAt) * 1000)
            LocalLogger.shared.info("dictation transcription_success chars=\(result.text.count) duration_ms=\(result.durationMs) effective_mode=\(effectiveTranscriptionMode.rawValue)")
            metrics.transcriptionMode = effectiveTranscriptionMode

            lastTranscript = result.text
            statusMessage = "Transcribed in \(result.durationMs) ms."

            let postprocessStartedAt = Date()
            let output: PostProcessingResult
            if let match = SnippetStore.shared.match(for: result.text) {
                output = PostProcessingResult(
                    text: match.outputText,
                    durationMs: 0,
                    model: "snippet",
                    mode: effectivePromptMode,
                    isRiskyTerminalCommand: false
                )
                LocalLogger.shared.info("snippet_matched reason=\(match.reason) confidence=\(String(format: "%.2f", match.confidence)) matched_trigger_chars=\(match.matchedTrigger.count) replacement_chars=\(match.snippet.replacement.count)")
            } else {
                output = try await finalOutput(from: result.text, promptMode: effectivePromptMode)
            }
            metrics.postprocessDurationMs = Int(Date().timeIntervalSince(postprocessStartedAt) * 1000)
            LocalLogger.shared.info("dictation final_output_success chars=\(output.text.count) postprocess_duration_ms=\(metrics.postprocessDurationMs ?? 0) mode=\(output.mode.rawValue) risky=\(output.isRiskyTerminalCommand)")
            let textToDeliver = output.isRiskyTerminalCommand ? SafetyClassifier.riskyPreview(command: output.text) : output.text
            lastDeliverableText = textToDeliver
            lastDeliverableWasRisky = output.isRiskyTerminalCommand
            lastProcessedText = textToDeliver

            if output.isRiskyTerminalCommand {
                try ClipboardPasteService.shared.copyOnly(textToDeliver)
                lastPasteStatus = "Risky terminal command copied for preview; not auto-pasted."
                metrics.errorType = "risky_terminal_command"
                addHistory(transcript: result.text, output: textToDeliver, status: .copied, statusMessage: "Risky command copied", target: pasteTarget, metrics: metrics)
                FloatingHUDController.shared.show(.error)
            } else if AppSettings.shared.pasteAutomatically {
                do {
                    let pasteStartedAt = Date()
                    try await ClipboardPasteService.shared.pasteText(textToDeliver)
                    metrics.pasteDurationMs = Int(Date().timeIntervalSince(pasteStartedAt) * 1000)
                    lastPasteStatus = "Pasted automatically; clipboard restored."
                    metrics.success = true
                    addHistory(transcript: result.text, output: textToDeliver, status: .pasted, statusMessage: "Pasted automatically", target: pasteTarget, metrics: metrics)
                    FeedbackService.shared.success()
                    FloatingHUDController.shared.show(.pasted)
                } catch {
                    lastPasteStatus = "Auto-paste failed; copied to clipboard. \(error.localizedDescription)"
                    metrics.errorType = String(describing: type(of: error))
                    metrics.success = true
                    LocalLogger.shared.error("dictation paste_failed copied_to_clipboard=true accessibility_trusted=\(PermissionsManager.shared.isAccessibilityTrusted(prompt: false)) error=\(error.localizedDescription)")
                    addHistory(transcript: result.text, output: textToDeliver, status: .copied, statusMessage: "Auto-paste failed; copied", target: pasteTarget, metrics: metrics)
                    FeedbackService.shared.success()
                    FloatingHUDController.shared.show(.pasted, message: "Copied")
                }
            } else {
                try ClipboardPasteService.shared.copyOnly(textToDeliver)
                metrics.pasteDurationMs = 0
                metrics.success = true
                lastPasteStatus = "Copied to clipboard. Paste manually."
                addHistory(transcript: result.text, output: textToDeliver, status: .copied, statusMessage: "Copied to clipboard", target: pasteTarget, metrics: metrics)
                FeedbackService.shared.success()
                FloatingHUDController.shared.show(.pasted)
            }

            if let releasedAt = hotkeyReleasedAt {
                metrics.totalReleaseToPasteMs = Int(Date().timeIntervalSince(releasedAt) * 1000)
            }
            MetricsStore.shared.add(metrics)
            AudioRecorder.shared.deleteLastRecordingIfNeeded(keepForDebugging: AppSettings.shared.keepLastAudioForDebugging)
        } catch {
            lastError = error.localizedDescription
            statusMessage = error.localizedDescription
            metrics.errorType = String(describing: type(of: error))
            LocalLogger.shared.error("dictation failed stage=record_transcribe_or_postprocess error_type=\(String(describing: type(of: error))) error=\(error.localizedDescription)")
            FeedbackService.shared.error()
            if let releasedAt = hotkeyReleasedAt {
                metrics.totalReleaseToPasteMs = Int(Date().timeIntervalSince(releasedAt) * 1000)
            }
            MetricsStore.shared.add(metrics)
            addHistory(transcript: lastTranscript, output: lastProcessedText, status: .error, statusMessage: error.localizedDescription, target: pasteTarget, metrics: metrics)
            FloatingHUDController.shared.show(.error)
        }
    }

    func copyLastResult() {
        do {
            guard !lastDeliverableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PasteError.emptyText
            }
            try ClipboardPasteService.shared.copyOnly(lastDeliverableText)
            lastPasteStatus = lastDeliverableWasRisky ? "Risky preview copied to clipboard." : "Last result copied to clipboard."
        } catch {
            lastPasteStatus = error.localizedDescription
            FloatingHUDController.shared.show(.error)
        }
    }

    func pasteLastResult() async {
        do {
            guard !lastDeliverableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PasteError.emptyText
            }
            if lastDeliverableWasRisky {
                try ClipboardPasteService.shared.copyOnly(lastDeliverableText)
                lastPasteStatus = "Risky preview copied, not pasted."
                FloatingHUDController.shared.show(.error)
                return
            }
            try await ClipboardPasteService.shared.pasteText(lastDeliverableText)
            lastPasteStatus = "Last result pasted; clipboard restored."
            FloatingHUDController.shared.show(.pasted)
        } catch {
            lastPasteStatus = error.localizedDescription
            FloatingHUDController.shared.show(.error)
        }
    }

    private func addHistory(
        transcript: String,
        output: String,
        status: DictationHistoryStatus,
        statusMessage: String,
        target: PasteTarget?,
        metrics: DictationMetrics
    ) {
        DictationHistoryStore.shared.add(DictationHistoryEntry(
            transcript: transcript,
            output: output,
            promptMode: metrics.promptMode ?? AppSettings.shared.promptMode,
            transcriptionMode: metrics.transcriptionMode ?? effectiveTranscriptionMode,
            model: metrics.model ?? AppSettings.shared.sttModel.rawValue,
            status: status,
            statusMessage: statusMessage,
            target: target,
            durationMs: metrics.totalReleaseToPasteMs
        ))
    }

    private func transcribe(audioURL: URL, context: TranscriptionContext) async throws -> TranscriptionResult {
        switch AppSettings.shared.transcriptionMode {
        case .fileUploadAfterRelease:
            effectiveTranscriptionMode = .fileUploadAfterRelease
            lastTranscriptionModeStatus = "File upload after release."
            return try await transcriber.transcribe(audioURL: audioURL, context: context)
        case .streamingCompletedRecording:
            do {
                effectiveTranscriptionMode = .streamingCompletedRecording
                lastTranscriptionModeStatus = "Streaming completed recording experimental."
                return try await realtimeTranscriber.transcribeCompletedRecording(audioURL: audioURL, context: context)
            } catch {
                LocalLogger.shared.error("streaming_completed_recording failed fallback=file_upload error=\(error.localizedDescription)")
                effectiveTranscriptionMode = .fileUploadAfterRelease
                lastTranscriptionModeStatus = "Streaming completed recording failed; used file upload fallback."
                return try await transcriber.transcribe(audioURL: audioURL, context: context)
            }
        case .realtimeMicrophoneStreaming:
            do {
                effectiveTranscriptionMode = .realtimeMicrophoneStreaming
                lastTranscriptionModeStatus = "Finalizing realtime microphone streaming…"
                return try await realtimeTranscriber.finishRealtimeMicrophone()
            } catch {
                LocalLogger.shared.error("realtime_microphone_streaming failed fallback=file_upload error=\(error.localizedDescription)")
                effectiveTranscriptionMode = .fileUploadAfterRelease
                lastTranscriptionModeStatus = "Realtime microphone streaming failed; used file upload fallback."
                return try await transcriber.transcribe(audioURL: audioURL, context: context)
            }
        }
    }

    private func finalOutput(from transcript: String, promptMode: PromptMode) async throws -> PostProcessingResult {
        let settings = AppSettings.shared
        guard settings.postProcessingEnabled, settings.postProcessingEnabledModes.contains(promptMode), promptMode != .rawDictation else {
            return PostProcessingResult(
                text: transcript,
                durationMs: 0,
                model: "none",
                mode: promptMode,
                isRiskyTerminalCommand: promptMode == .terminalCommand && SafetyClassifier.isRiskyTerminalCommandOutput(transcript)
            )
        }

        statusMessage = "Post-processing \(promptMode.title)…"
        let processed = try await postProcessor.process(
            text: transcript,
            mode: promptMode,
            style: settings.writingStyle,
            model: settings.postProcessingModel.rawValue,
            maxOutputTokens: settings.postProcessingMaxOutputTokens,
            language: settings.resolvedPromptLanguage,
            override: settings.promptOverride(for: promptMode)
        )
        statusMessage = "Post-processed in \(processed.durationMs) ms."
        return processed
    }

    private func scheduleMaximumRecordingTimeout() {
        maxRecordingTask?.cancel()
        let timeoutSeconds = maximumRecordingDurationSeconds
        maxRecordingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.isPressed else { return }
                self.isPressed = false
                self.statusMessage = "Maximum recording duration reached; stopping…"
                Task { await self.handleRelease() }
            }
        }
    }
}
