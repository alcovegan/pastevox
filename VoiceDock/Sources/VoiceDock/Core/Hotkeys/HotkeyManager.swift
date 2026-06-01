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
    private var modeSwitchDuringHold = false

    private init() {}

    func start() {
        guard !isRunning else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
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

        isRunning = true
        statusMessage = "Hotkey monitor running: hold Fn/Globe to record."
        LocalLogger.shared.info("Hotkey monitor started kind=fnHold")
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        maxRecordingTask?.cancel()
        maxRecordingTask = nil
        isRunning = false
        isPressed = false
        statusMessage = "Hotkey monitor stopped."
        LocalLogger.shared.info("Hotkey monitor stopped")
    }

    private func handleKeyDown(_ event: NSEvent) {
        guard isPressed || event.modifierFlags.contains(.function) else { return }
        guard let mode = promptMode(for: event.charactersIgnoringModifiers ?? "") else { return }

        modeSwitchDuringHold = true
        AppSettings.shared.promptMode = mode
        statusMessage = "Prompt mode switched to \(mode.title)."
        FloatingHUDController.shared.show(.modeChanged, message: "Mode: \(mode.shortTitle)")

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

    private func handleFlagsChanged(_ event: NSEvent) {
        let fnIsDown = event.modifierFlags.contains(.function)
        if fnIsDown && !isPressed {
            isPressed = true
            lastEvent = .pressed
            Task { await handlePress() }
        } else if !fnIsDown && isPressed {
            isPressed = false
            lastEvent = .released
            Task { await handleRelease() }
        }
    }

    private func handlePress() async {
        hotkeyPressedAt = Date()
        lastError = ""
        lastTranscript = ""
        lastProcessedText = ""
        statusMessage = "Fn pressed: starting recording…"

        do {
            LocalLogger.shared.info("recording_start requested mic_status=\(PermissionsManager.shared.microphonePermissionDescription().replacingOccurrences(of: " ", with: "_"))")
            try await AudioRecorder.shared.startRecording()
            recordingStartedAt = Date()
            FeedbackService.shared.recordingStarted()
            FloatingHUDController.shared.show(.listening)
            statusMessage = "Recording while Fn is held…"
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
            return
        }
        var metrics = DictationMetrics()
        let pasteTarget = AppSettings.shared.logPasteTargetApp ? PasteTarget.current : nil
        let effectivePromptMode = AppAwareModeResolver.mode(for: pasteTarget) ?? AppSettings.shared.promptMode
        if let explanation = AppAwareModeResolver.explanation(for: pasteTarget, resolvedMode: effectivePromptMode), effectivePromptMode != AppSettings.shared.promptMode {
            LocalLogger.shared.info("app_aware_mode_switch \(explanation)")
            FloatingHUDController.shared.show(.modeChanged, message: effectivePromptMode.shortTitle)
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
        guard settings.postProcessingEnabled, promptMode != .rawDictation else {
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
            model: settings.postProcessingModel.rawValue,
            maxOutputTokens: settings.postProcessingMaxOutputTokens
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
