import AppKit
import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case workflow = "Workflow"
    case permissions = "Permissions"
    case hotkey = "Hotkey"
    case metrics = "Metrics"
    case debug = "Debug"
    case openAI = "OpenAI"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .workflow: "slider.horizontal.3"
        case .permissions: "checkmark.shield"
        case .hotkey: "keyboard"
        case .metrics: "speedometer"
        case .debug: "wrench.and.screwdriver"
        case .openAI: "key"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var hudController: FloatingHUDController
    @ObservedObject private var audioRecorder = AudioRecorder.shared
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    @ObservedObject private var metricsStore = MetricsStore.shared

    @State private var selectedSection: SettingsSection = .workflow
    @State private var apiKeyInput = ""
    @State private var apiKeyStatus = T("Keychain status unknown")
    @State private var savedAPIKeyMask = AppSettings.shared.savedAPIKeyMask
    @State private var testStatus = T("Not tested")
    @State private var transcriptionStatus = T("No audio selected")
    @State private var transcriptPreview = ""
    @State private var microphoneStatus = PermissionsManager.shared.microphonePermissionDescription()
    @State private var accessibilityStatus = PermissionsManager.shared.accessibilityPermissionDescription()
    @State private var recordingTranscriptionStatus = T("No recording transcribed yet")
    @State private var metricsCopyStatus = ""
    @State private var isBusy = false

    private let transcriber = OpenAIFileTranscriber()

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.allowsFloats = false
        formatter.minimum = 256
        formatter.maximum = 4000
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    content
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(SettingsButtonStyle())
            .background(SettingsPalette.background)
        }
        .frame(minWidth: 860, idealWidth: 980, minHeight: 680, idealHeight: 760)
        .onAppear {
            savedAPIKeyMask = settings.savedAPIKeyMask
            apiKeyStatus = T("Keychain not checked on startup to avoid password prompts. Use Check Keychain or Test OpenAI.")
            refreshMicrophoneStatus()
            refreshAccessibilityStatus()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SettingsPalette.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PasteVox")
                        .font(.headline)
                    Text("0.0.10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 14)

            ForEach(SettingsSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .frame(width: 18)
                        Text(T(section.rawValue))
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(selectedSection == section ? SettingsPalette.ink.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(selectedSection == section ? SettingsPalette.ink : SettingsPalette.muted)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text(T("Fn/Globe → STT → post-process → paste"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(width: 220)
        .background(SettingsPalette.surfaceSecondary)
        .overlay(Rectangle().fill(SettingsPalette.line).frame(width: 1), alignment: .trailing)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(T(selectedSection.rawValue))
                .font(.system(size: 34, weight: .semibold))
            Text(subtitle(for: selectedSection))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedSection {
        case .workflow: workflowSection
        case .permissions: permissionsSection
        case .hotkey: hotkeySection
        case .metrics: metricsSection
        case .debug: debugSection
        case .openAI: openAISection
        }
    }

    private var workflowSection: some View {
        VStack(spacing: 14) {
            SettingsCard(T("Dictation")) {
                settingRow(T("Hold key")) {
                    Picker("", selection: $settings.holdHotkeyKind) {
                        ForEach(HotkeyKind.allCases) { kind in Text(kind.title).tag(kind) }
                    }
                    .labelsHidden()
                    .frame(width: 220, alignment: .leading)
                }

                HStack(alignment: .top, spacing: 12) {
                    workflowControlCard(T("Prompt mode"), subtitle: T("Fn+1…4")) {
                        Picker("", selection: $settings.promptMode) {
                            ForEach(PromptMode.allCases) { mode in Text(mode.title).tag(mode) }
                        }
                        .labelsHidden()
                        .frame(width: 230)
                    }
                    workflowControlCard(T("Writing style"), subtitle: T("Fn+5…0, Fn+-")) {
                        Picker("", selection: $settings.writingStyle) {
                            ForEach(WritingStyle.allCases) { style in Text(style.title).tag(style) }
                        }
                        .labelsHidden()
                        .frame(width: 210)
                    }
                }

                HStack(spacing: 8) {
                    shortcutChip(T("Fn+1 Raw"))
                    shortcutChip(T("Fn+2 Agent"))
                    shortcutChip(T("Fn+3 RALPH"))
                    shortcutChip(T("Fn+4 Command"))
                }
                HStack(spacing: 8) {
                    shortcutChip(T("Fn+5 Default"))
                    shortcutChip(T("Fn+6 Concise"))
                    shortcutChip(T("Fn+7 Friendly"))
                    shortcutChip(T("Fn+8 Formal"))
                    shortcutChip(T("Fn+9 Coding"))
                    shortcutChip(T("Fn+0 Chat"))
                    shortcutChip(T("Fn+- Email"))
                }

                Text(T("Styles apply only when post-processing is enabled for the active mode. Raw Dictation stays raw."))
                    .font(.caption)
                    .foregroundStyle(SettingsPalette.muted)
                    .padding(.top, 2)

                Divider().padding(.vertical, 2)

                settingRow(T("OpenAI STT model")) {
                    Picker("", selection: $settings.sttModel) {
                        ForEach(STTModel.allCases) { model in Text(model.rawValue).tag(model) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .frame(width: 260, alignment: .leading)
                }
                settingRow(T("Transcription mode")) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(TranscriptionMode.fileUploadAfterRelease.title)
                            .foregroundStyle(SettingsPalette.ink)
                        Text(T("Recommended default. Experimental modes are hidden in Debug."))
                            .font(.caption)
                            .foregroundStyle(SettingsPalette.muted)
                    }
                }
            }

            SettingsCard(T("Behavior")) {
                settingRow(T("Language")) {
                    Picker("", selection: $settings.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }
                    .labelsHidden()
                    .frame(width: 220, alignment: .leading)
                }
                Toggle(T("Show PasteVox in Dock"), isOn: $settings.showInDock)
                Toggle(T("Hold-to-record enabled"), isOn: $settings.fnHoldToRecordEnabled)
                    .help(T("Temporarily pause the hold recording trigger when using modifier keys for code navigation. Quick toggle: Fn+`."))
                Toggle(T("Paste automatically"), isOn: $settings.pasteAutomatically)
                Toggle(T("App-aware mode switching"), isOn: $settings.appAwareModeSwitchingEnabled)
                    .help(T("Experimental: Cursor/VS Code/Xcode → Agent, Terminal/iTerm → Command, chats/mail → Raw."))
                    .onChange(of: settings.appAwareModeSwitchingEnabled) { _ in
                        HotkeyManager.shared.restart()
                    }
                Toggle(T("Prefer speed over quality"), isOn: $settings.preferSpeedOverQuality)
                    .help(T("Uses file upload + gpt-4o-mini-transcribe. Post-processing is controlled per mode below."))
                Toggle(T("Sound feedback"), isOn: $settings.soundFeedbackEnabled)
                    .help(T("Uses short custom PasteVox tones, not macOS system sounds."))
                Toggle(T("Haptic feedback"), isOn: $settings.hapticFeedbackEnabled)
                    .help(T("Subtle haptic only on release/success/error; no haptic on recording start."))
                Toggle(T("Keep last audio for debugging"), isOn: $settings.keepLastAudioForDebugging)
                Toggle(T("Log paste target app"), isOn: $settings.logPasteTargetApp)
                    .help(T("Stores target app name/bundle in local history for debugging and repeat paste."))
                Toggle(T("Log target window title"), isOn: $settings.logPasteTargetWindowTitle)
                    .help(T("Optional and off by default. Requires Accessibility and may expose document/window names in local history."))
            }

            SettingsCard(T("Post-processing")) {
                HStack(alignment: .center, spacing: 10) {
                    Toggle("", isOn: $settings.postProcessingEnabled)
                        .labelsHidden()
                        .toggleStyle(SettingsCheckboxToggleStyle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(T("Enable post-processing globally"))
                            .font(.system(size: 15, weight: .semibold))
                        Text(T("Then choose which modes are rewritten after transcription."))
                            .font(.caption)
                            .foregroundStyle(SettingsPalette.muted)
                    }
                    Spacer()
                    Text(settings.postProcessingEnabled ? T("Enabled") : T("Off"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SettingsPalette.muted)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(SettingsPalette.surfaceSecondary, in: Capsule())
                }

                postProcessingModeGrid

                postProcessingControls
            }
        }
    }

    private var permissionsSection: some View {
        SettingsCard(T("System Permissions")) {
            statusLine(T("Microphone"), microphoneStatus)
            statusLine(T("Accessibility"), accessibilityStatus)

            HStack {
                Button(T("Request Microphone")) { Task { await requestMicrophonePermission() } }
                    .disabled(isBusy)
                Button(T("Request Accessibility")) {
                    PermissionsManager.shared.openAccessibilityPrompt()
                    refreshAccessibilityStatus()
                }
                .disabled(isBusy)
                Button(T("Refresh")) {
                    refreshMicrophoneStatus()
                    refreshAccessibilityStatus()
                }
            }
        }
    }

    private var hotkeySection: some View {
        VStack(spacing: 14) {
            SettingsCard(T("Hold-to-record")) {
                Text(T("Hold Fn/Globe to record. Release to transcribe and paste/copy."))
                    .foregroundStyle(.secondary)

                HStack {
                    Button(hotkeyManager.isRunning ? T("Restart Monitor") : T("Start Monitor")) {
                        hotkeyManager.stop()
                        hotkeyManager.start()
                    }
                    Button(T("Stop Monitor")) { hotkeyManager.stop() }
                        .disabled(!hotkeyManager.isRunning)
                }

                HStack {
                    Button(T("Copy Last Result")) { hotkeyManager.copyLastResult() }
                        .disabled(hotkeyManager.lastProcessedText.isEmpty)
                    Button(T("Paste Last Result")) { Task { await hotkeyManager.pasteLastResult() } }
                        .disabled(hotkeyManager.lastProcessedText.isEmpty)
                }

                statusLine(T("Monitor"), hotkeyManager.isRunning ? T("running") : T("stopped"))
                statusLine(T("Pressed"), hotkeyManager.isPressed ? T("yes") : T("no"))
                statusLine(T("Status"), hotkeyManager.statusMessage)
                statusLine(T("Transcription"), hotkeyManager.lastTranscriptionModeStatus)
                statusLine(T("Paste"), hotkeyManager.lastPasteStatus)
                if !hotkeyManager.lastError.isEmpty {
                    statusLine(T("Last error"), hotkeyManager.lastError)
                }
            }

            if !hotkeyManager.lastProcessedText.isEmpty {
                SettingsCard(hotkeyManager.lastProcessedText.hasPrefix("# RISKY_COMMAND_PREVIEW") ? T("Risky command preview") : T("Last final output")) {
                    if hotkeyManager.lastProcessedText.hasPrefix("# RISKY_COMMAND_PREVIEW") {
                        Text(T("Blocked from auto-paste. Preview is shell-commented and safe to paste, but review manually."))
                            .font(.caption)
                            .foregroundStyle(SettingsPalette.danger)
                    }
                    previewText(hotkeyManager.lastProcessedText, height: 130)
                }
            }

            if !hotkeyManager.lastTranscript.isEmpty {
                SettingsCard(T("Last raw transcript")) {
                    previewText(hotkeyManager.lastTranscript, height: 90)
                }
            }
        }
    }

    private var metricsSection: some View {
        SettingsCard(T("Latency")) {
            if let stats = metricsStore.totalReleaseToPasteStats() {
                Text(String(format: T("successful total_release_to_paste min/avg/max: %d/%d/%d ms"), stats.min, stats.avg, stats.max))
                    .font(.headline)
            } else {
                Text(T("No successful sessions yet."))
                    .foregroundStyle(.secondary)
            }

            modeStatsBlock(title: T("Total by mode"), stats: metricsStore.totalStatsByTranscriptionMode())
            modeStatsBlock(title: T("STT by mode"), stats: metricsStore.sttStatsByTranscriptionMode())

            HStack {
                Button(T("Copy Metrics Report")) { copyMetricsReport() }
                    .disabled(metricsStore.sessions.isEmpty)
                Button(T("Clear Metrics")) {
                    metricsStore.clear()
                    metricsCopyStatus = ""
                }
            }
            if !metricsCopyStatus.isEmpty {
                Text(metricsCopyStatus)
                    .font(.caption)
                    .foregroundStyle(SettingsPalette.ink)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(metricsStore.sessions.prefix(12)) { metric in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(metric.summary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(metric.success ? SettingsPalette.ink : SettingsPalette.danger)
                        Text("mode=\(metric.transcriptionMode?.title ?? "n/a")  model=\(metric.model ?? "n/a")  record=\(metric.recordingDurationMs.map(String.init) ?? "n/a")ms  audio=\(metric.audioFileSizeBytes.map(String.init) ?? "n/a")B  stt=\(metric.transcriptionDurationMs.map(String.init) ?? "n/a")ms  post=\(metric.postprocessDurationMs.map(String.init) ?? "n/a")ms  paste=\(metric.pasteDurationMs.map(String.init) ?? "n/a")ms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SettingsPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SettingsPalette.line, lineWidth: 1))
                }
            }
        }
    }

    private var debugSection: some View {
        VStack(spacing: 14) {
            SettingsCard(T("Manual recording")) {
                HStack {
                    Button(T("Start Recording")) { Task { await startRecording() } }
                        .disabled(isBusy || audioRecorder.state == .recording)
                    Button(T("Stop Recording")) { stopRecording() }
                        .disabled(audioRecorder.state != .recording)
                    Button(T("Play Last")) { playLastRecording() }
                        .disabled(audioRecorder.lastRecordingURL == nil || audioRecorder.state == .recording)
                    Button(T("Transcribe Last")) { Task { await transcribeLastRecording() } }
                        .disabled(audioRecorder.lastRecordingURL == nil || audioRecorder.state == .recording || isBusy)
                }
                statusLine(T("Recorder"), "\(audioRecorder.state.rawValue) — \(audioRecorder.statusMessage)")
                statusLine(T("Last recording"), lastRecordingDescription)
                statusLine(T("Transcription"), recordingTranscriptionStatus)
            }

            SettingsCard(T("Experimental transcription modes")) {
                settingRow(T("Mode")) {
                    Picker("", selection: $settings.transcriptionMode) {
                        ForEach(TranscriptionMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }
                    .labelsHidden()
                    .frame(width: 360)
                }
                Text(T("File upload is recommended. Completed-recording stream is not true live microphone streaming. Realtime remains unstable for Russian/short phrases and falls back to file upload."))
                    .font(.caption)
                    .foregroundStyle(settings.transcriptionMode == .fileUploadAfterRelease ? SettingsPalette.muted : SettingsPalette.danger)
            }

            SettingsCard(T("Sample audio")) {
                HStack {
                    Button(T("Transcribe Sample Audio…")) { Task { await transcribeSampleAudio() } }
                        .disabled(isBusy)
                    if isBusy { ProgressView().controlSize(.small) }
                }
                statusLine(T("Status"), transcriptionStatus)
                if !transcriptPreview.isEmpty { previewText(transcriptPreview, height: 130) }
            }

            SettingsCard(T("HUD states")) {
                HStack {
                    ForEach([HUDState.listening, .transcribing, .pasted, .error, .modeChanged]) { state in
                        Button(state.title) { hudController.show(state) }
                    }
                    Button(T("Hide")) { hudController.hide() }
                }
            }

            SettingsCard(T("Feedback test")) {
                HStack {
                    Button(T("Start Haptic")) { FeedbackService.shared.recordingStarted() }
                    Button(T("Release")) { FeedbackService.shared.recordingEnded() }
                    Button(T("Success")) { FeedbackService.shared.success() }
                    Button(T("Error")) { FeedbackService.shared.error() }
                }
                Text(T("If sounds play but haptics do not, macOS/device may not expose haptic feedback to this app/session. Sounds remain independent."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsCard(T("Logs")) {
                settingRow(T("Local log")) {
                    Text(LocalLogger.shared.logFilePath())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                Button(T("Copy Log Path")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(LocalLogger.shared.logFilePath(), forType: .string)
                }
            }

            SettingsCard(T("Reset")) {
                Text(T("Reset local app settings. OpenAI key is kept unless you delete it in OpenAI section."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(T("Reset App Settings")) {
                    settings.resetToDefaults()
                    NSApp.delegate.flatMap { $0 as? AppDelegate }?.applyActivationPolicy()
                }
            }
        }
    }

    private var openAISection: some View {
        SettingsCard(T("API Key")) {
            SettingsSecureInputField(T("OpenAI API key"), text: $apiKeyInput)

            HStack {
                Button(T("Save API Key")) { saveAPIKey() }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
                Button(T("Check Keychain")) { refreshAPIKeyStatus() }
                    .disabled(isBusy)
                Button(T("Delete Key")) { deleteAPIKey() }
                    .disabled(isBusy)
                Button(T("Test OpenAI")) { Task { await testOpenAI() } }
                    .disabled(isBusy)
            }

            settingRow(T("Saved key")) {
                Text(savedAPIKeyMask)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
            statusLine(T("Keychain"), apiKeyStatus)
            statusLine(T("Test"), testStatus)
        }
    }

    private func modeStatsBlock(
        title: String,
        stats: [(mode: TranscriptionMode, count: Int, min: Int, avg: Int, max: Int)]
    ) -> some View {
        Group {
            if !stats.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    ForEach(stats, id: \.mode) { stat in
                        Text(String(format: T("%@: n=%d, min/avg/max %d/%d/%d ms"), stat.mode.title, stat.count, stat.min, stat.avg, stat.max))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func copyMetricsReport() {
        let report = metricsStore.metricsReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        metricsCopyStatus = T("Metrics report copied to clipboard.")
    }

    private func subtitle(for section: SettingsSection) -> String {
        switch section {
        case .workflow: T("Main dictation, paste and post-processing options.")
        case .permissions: T("Microphone and Accessibility permissions.")
        case .hotkey: T("Fn/Globe hold-to-record status and last outputs.")
        case .metrics: T("Latency for recent dictation sessions.")
        case .debug: T("Manual recording, sample audio and HUD controls.")
        case .openAI: T("API key storage and connection test.")
        }
    }

    private func bindingForPostProcessingMode(_ mode: PromptMode) -> Binding<Bool> {
        Binding(
            get: { settings.postProcessingEnabledModes.contains(mode) },
            set: { enabled in
                if enabled {
                    settings.postProcessingEnabledModes.insert(mode)
                } else {
                    settings.postProcessingEnabledModes.remove(mode)
                }
            }
        )
    }

    private func workflowControlCard<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SettingsPalette.muted)
                    .tracking(0.8)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsPalette.muted)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SettingsPalette.line, lineWidth: 1))
    }

    private func shortcutChip(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(SettingsPalette.ink)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(SettingsPalette.control, in: Capsule())
            .overlay(Capsule().stroke(SettingsPalette.line, lineWidth: 1))
    }

    private var postProcessingModeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(PromptMode.allCases) { mode in
                postProcessingModeCard(mode)
            }
        }
    }

    private func postProcessingModeCard(_ mode: PromptMode) -> some View {
        let isRaw = mode == .rawDictation
        return HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: bindingForPostProcessingMode(mode))
                .labelsHidden()
                .toggleStyle(SettingsCheckboxToggleStyle())
                .disabled(isRaw)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(isRaw ? SettingsPalette.faint : SettingsPalette.ink)
                Text(postProcessingDescription(for: mode))
                    .font(.caption)
                    .foregroundStyle(isRaw ? SettingsPalette.faint : SettingsPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(SettingsPalette.surfaceSecondary.opacity(isRaw ? 0.55 : 1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SettingsPalette.line, lineWidth: 1))
    }

    private func postProcessingDescription(for mode: PromptMode) -> String {
        switch mode {
        case .rawDictation: T("Left untouched so raw transcription stays raw.")
        case .agentPrompt: T("Rewrite rough speech into a coding-agent task.")
        case .ralphPrompt: T("Structure output as role, goal, context and criteria.")
        case .terminalCommand: T("Generate commands with a safety gate for risky output.")
        }
    }

    private var postProcessingControls: some View {
        VStack(spacing: 0) {
            inlineControlRow(T("Rewrite model"), subtitle: T("Used only after transcription")) {
                Picker("", selection: $settings.postProcessingModel) {
                    ForEach(PostProcessingModel.allCases) { model in Text(model.rawValue).tag(model) }
                }
                .labelsHidden()
                .frame(width: 180, alignment: .leading)
            }

            Divider().padding(.leading, 170)

            inlineControlRow(T("Max output tokens"), subtitle: T("256–4000")) {
                HStack(spacing: 0) {
                    tokenStepButton("−", delta: -100)
                    Rectangle()
                        .fill(SettingsPalette.line)
                        .frame(width: 1, height: 22)
                    TextField("1200", value: tokenLimitBinding, formatter: Self.integerFormatter)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 90, height: 34)
                    Rectangle()
                        .fill(SettingsPalette.line)
                        .frame(width: 1, height: 22)
                    tokenStepButton("+", delta: 100)
                }
                .frame(width: 180, height: 34)
                .background(SettingsPalette.surface, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(SettingsPalette.line, lineWidth: 1))
            }
        }
        .padding(.vertical, 4)
        .background(SettingsPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SettingsPalette.line, lineWidth: 1))
    }

    private func inlineControlRow<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsPalette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SettingsPalette.muted)
            }
            .frame(width: 154, alignment: .leading)

            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tokenStepButton(_ title: String, delta: Int) -> some View {
        Button {
            adjustTokenLimit(by: delta)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(SettingsPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 44, height: 34)
        }
        .buttonStyle(.plain)
    }

    private var tokenLimitBinding: Binding<Int> {
        Binding(
            get: { settings.postProcessingMaxOutputTokens },
            set: { settings.postProcessingMaxOutputTokens = clampedTokenLimit($0) }
        )
    }

    private func adjustTokenLimit(by delta: Int) {
        settings.postProcessingMaxOutputTokens = clampedTokenLimit(settings.postProcessingMaxOutputTokens + delta)
    }

    private func clampedTokenLimit(_ value: Int) -> Int {
        min(4000, max(256, value))
    }

    private func settingRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }

    private func statusLine(_ title: String, _ value: String) -> some View {
        settingRow(title) {
            Text(value)
                .foregroundStyle(statusColor(value))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func previewText(_ text: String, height: CGFloat) -> some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(10)
        }
        .frame(height: height)
        .background(SettingsPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SettingsPalette.line, lineWidth: 1))
    }

    private func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try KeychainStore.shared.saveOpenAIAPIKey(key)
            apiKeyInput = ""
            savedAPIKeyMask = maskedKey(key)
            settings.savedAPIKeyMask = savedAPIKeyMask
            apiKeyStatus = T("API key saved in Keychain.")
            testStatus = T("Not tested")
        } catch {
            apiKeyStatus = String(format: T("Failed to save API key: %@"), error.localizedDescription)
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainStore.shared.deleteOpenAIAPIKey()
            apiKeyInput = ""
            savedAPIKeyMask = T("Not saved")
            settings.savedAPIKeyMask = savedAPIKeyMask
            apiKeyStatus = T("API key deleted from Keychain.")
            testStatus = T("Not tested")
        } catch {
            apiKeyStatus = String(format: T("Failed to delete API key: %@"), error.localizedDescription)
        }
    }

    private func refreshAPIKeyStatus() {
        do {
            if let key = try KeychainStore.shared.loadOpenAIAPIKey(), !key.isEmpty {
                savedAPIKeyMask = maskedKey(key)
                settings.savedAPIKeyMask = savedAPIKeyMask
                apiKeyStatus = T("API key is saved in Keychain.")
            } else {
                savedAPIKeyMask = T("Not saved")
                settings.savedAPIKeyMask = savedAPIKeyMask
                apiKeyStatus = T("No API key saved.")
            }
        } catch {
            apiKeyStatus = String(format: T("Failed to read Keychain: %@"), error.localizedDescription)
        }
    }

    private func testOpenAI() async {
        isBusy = true
        testStatus = T("Testing OpenAI…")
        defer { isBusy = false }
        do {
            try await transcriber.testAPIKey()
            testStatus = T("OpenAI test succeeded.")
            refreshAPIKeyStatus()
        } catch {
            testStatus = error.localizedDescription
        }
    }

    private var lastRecordingDescription: String {
        guard let url = audioRecorder.lastRecordingURL else { return T("none") }
        let peak = String(format: "%.2f", audioRecorder.lastRecordingPeakLevel)
        return String(
            format: T("%@, %d ms, %d bytes, peak %@"),
            url.lastPathComponent,
            audioRecorder.lastRecordingDurationMs,
            audioRecorder.lastRecordingSizeBytes,
            peak
        )
    }

    private func requestMicrophonePermission() async {
        isBusy = true
        defer { isBusy = false }
        _ = await PermissionsManager.shared.requestMicrophonePermission()
        refreshMicrophoneStatus()
    }

    private func refreshMicrophoneStatus() {
        microphoneStatus = PermissionsManager.shared.microphonePermissionDescription()
    }

    private func refreshAccessibilityStatus() {
        accessibilityStatus = PermissionsManager.shared.accessibilityPermissionDescription()
    }

    private func startRecording() async {
        do {
            recordingTranscriptionStatus = T("No recording transcribed yet")
            transcriptPreview = ""
            try await audioRecorder.startRecording()
            refreshMicrophoneStatus()
            hudController.show(.listening)
        } catch {
            refreshMicrophoneStatus()
            recordingTranscriptionStatus = error.localizedDescription
            hudController.show(.error)
        }
    }

    private func stopRecording() {
        do {
            _ = try audioRecorder.stopRecording()
            hudController.hide()
        } catch {
            recordingTranscriptionStatus = error.localizedDescription
            hudController.show(.error)
        }
    }

    private func playLastRecording() {
        do {
            try audioRecorder.playLastRecording()
        } catch {
            recordingTranscriptionStatus = error.localizedDescription
        }
    }

    private func transcribeLastRecording() async {
        guard let url = audioRecorder.lastRecordingURL else {
            recordingTranscriptionStatus = AudioRecorderError.noRecording.localizedDescription
            return
        }

        isBusy = true
        transcriptPreview = ""
        recordingTranscriptionStatus = T("Transcribing last recording…")
        hudController.show(.transcribing)
        defer { isBusy = false }

        do {
            let context = TranscriptionContext(promptMode: settings.promptMode, model: settings.sttModel.rawValue)
            let result = try await transcriber.transcribe(audioURL: url, context: context)
            transcriptPreview = try await processForPreview(result.text)
            recordingTranscriptionStatus = String(format: T("Success: %d ms, model: %@"), result.durationMs, result.model)
            audioRecorder.deleteLastRecordingIfNeeded(keepForDebugging: settings.keepLastAudioForDebugging)
            hudController.show(.pasted)
        } catch {
            recordingTranscriptionStatus = error.localizedDescription
            hudController.show(.error)
        }
    }

    private func transcribeSampleAudio() async {
        guard let url = openAudioFilePanel() else { return }

        isBusy = true
        transcriptPreview = ""
        transcriptionStatus = String(format: T("Transcribing %@…"), url.lastPathComponent)
        hudController.show(.transcribing)
        defer { isBusy = false }

        do {
            let context = TranscriptionContext(promptMode: settings.promptMode, model: settings.sttModel.rawValue)
            let result = try await transcriber.transcribe(audioURL: url, context: context)
            transcriptPreview = try await processForPreview(result.text)
            transcriptionStatus = String(format: T("Success: %d ms, model: %@"), result.durationMs, result.model)
            hudController.show(.pasted)
        } catch {
            transcriptionStatus = error.localizedDescription
            hudController.show(.error)
        }
    }

    private func processForPreview(_ text: String) async throws -> String {
        guard settings.postProcessingEnabled, settings.promptMode != .rawDictation else { return text }
        let result = try await PromptPostProcessor().process(
            text: text,
            mode: settings.promptMode,
            style: settings.writingStyle,
            model: settings.postProcessingModel.rawValue,
            maxOutputTokens: settings.postProcessingMaxOutputTokens
        )
        return result.text
    }

    @MainActor
    private func openAudioFilePanel() -> URL? {
        let panel = NSOpenPanel()
        panel.title = T("Choose sample audio")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .mp3, .wav]
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 10 else { return "••••" }
        return "\(key.prefix(7))…\(key.suffix(4))"
    }

    private func statusColor(_ status: String) -> Color {
        let lower = status.lowercased()
        // Short status tokens are localized, so match both the English keys and the
        // current-language translations so tinting stays correct in any locale.
        let positiveTokens: Set<String> = ["running", "yes", T("running").lowercased(), T("yes").lowercased()]
        let neutralTokens: Set<String> = ["stopped", "no", T("stopped").lowercased(), T("no").lowercased()]
        if positiveTokens.contains(lower) { return SettingsPalette.ink }
        if neutralTokens.contains(lower) { return SettingsPalette.muted }
        if lower.contains("success") || lower.contains("succeeded") || lower.contains("granted") { return SettingsPalette.ink }
        if lower.contains("error") || lower.contains("failed") || lower.contains("invalid") || lower.contains("missing") || lower.contains("denied") || lower.contains("risky") { return SettingsPalette.danger }
        return SettingsPalette.muted
    }
}

private enum SettingsPalette {
    static let background = Color(red: 0.96, green: 0.96, blue: 0.95)
    static let surface = Color.white
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.94)
    static let ink = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let inkPressed = Color(red: 0.16, green: 0.16, blue: 0.16)
    static let muted = Color(red: 0.40, green: 0.40, blue: 0.40)
    static let faint = Color(red: 0.70, green: 0.70, blue: 0.68)
    static let line = Color.black.opacity(0.10)
    static let lineStrong = Color.black.opacity(0.18)
    static let control = Color(red: 0.91, green: 0.91, blue: 0.90)
    static let controlPressed = Color(red: 0.86, green: 0.86, blue: 0.84)
    static let danger = Color(red: 0.18, green: 0.18, blue: 0.18)
}

private struct SettingsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(SettingsPalette.ink)
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(configuration.isPressed ? SettingsPalette.controlPressed : SettingsPalette.control, in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(SettingsPalette.line, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct SettingsCheckboxToggleStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 7)
                .fill(configuration.isOn ? SettingsPalette.ink : SettingsPalette.control)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(configuration.isOn ? 1 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(SettingsPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.38)
    }
}

private struct SettingsSecureInputField: View {
    private let placeholder: String
    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        SettingsNativeSecureField(placeholder: placeholder, text: $text)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(SettingsPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SettingsPalette.line, lineWidth: 1))
    }
}

private struct SettingsNativeSecureField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSSecureTextField {
        let field = NSSecureTextField(string: text)
        field.delegate = context.coordinator
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        field.textColor = NSColor(calibratedWhite: 0.06, alpha: 1)
        field.placeholderAttributedString = placeholderString(placeholder)
        return field
    }

    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        if nsView.stringValue != text { nsView.stringValue = text }
        nsView.placeholderAttributedString = placeholderString(placeholder)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    private func placeholderString(_ value: String) -> NSAttributedString {
        NSAttributedString(
            string: value,
            attributes: [
                .foregroundColor: NSColor(calibratedWhite: 0.48, alpha: 1),
                .font: NSFont.systemFont(ofSize: 14, weight: .regular)
            ]
        )
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            text = field.stringValue
        }
    }
}

private struct SettingsCard<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SettingsPalette.muted)
                .tracking(0.8)
            content
        }
        .padding(18)
        .frame(maxWidth: 700, alignment: .leading)
        .background(SettingsPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SettingsPalette.line, lineWidth: 1)
        )
    }
}
