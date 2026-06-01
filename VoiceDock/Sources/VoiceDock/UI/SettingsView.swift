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
    @State private var apiKeyStatus = "Keychain status unknown"
    @State private var savedAPIKeyMask = AppSettings.shared.savedAPIKeyMask
    @State private var testStatus = "Not tested"
    @State private var transcriptionStatus = "No audio selected"
    @State private var transcriptPreview = ""
    @State private var microphoneStatus = PermissionsManager.shared.microphonePermissionDescription()
    @State private var accessibilityStatus = PermissionsManager.shared.accessibilityPermissionDescription()
    @State private var recordingTranscriptionStatus = "No recording transcribed yet"
    @State private var metricsCopyStatus = ""
    @State private var isBusy = false

    private let transcriber = OpenAIFileTranscriber()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    content
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 860, idealWidth: 980, minHeight: 680, idealHeight: 760)
        .onAppear {
            savedAPIKeyMask = settings.savedAPIKeyMask
            apiKeyStatus = "Keychain not checked on startup to avoid password prompts. Use Check Keychain or Test OpenAI."
            refreshMicrophoneStatus()
            refreshAccessibilityStatus()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("VoiceDock")
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
                        Text(section.rawValue)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(selectedSection == section ? Color.accentColor.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("Fn/Globe → STT → post-process → paste")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(width: 210)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedSection.rawValue)
                .font(.largeTitle.bold())
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
            SettingsCard("Dictation") {
                settingRow("Hotkey") { Text(settings.selectedHotkey).foregroundStyle(.secondary) }
                settingRow("Prompt mode") {
                    Picker("", selection: $settings.promptMode) {
                        ForEach(PromptMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }
                    .labelsHidden()
                    .frame(width: 240)
                }
                settingRow("OpenAI STT model") {
                    Picker("", selection: $settings.sttModel) {
                        ForEach(STTModel.allCases) { model in Text(model.rawValue).tag(model) }
                    }
                    .labelsHidden()
                    .frame(width: 260)
                }
                settingRow("Transcription mode") {
                    Text(TranscriptionMode.fileUploadAfterRelease.title)
                        .foregroundStyle(.secondary)
                }
                Text("Recommended default. The experimental modes are hidden in Debug because they did not show a stable latency/quality win.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsCard("Behavior") {
                Toggle("Show VoiceDock in Dock", isOn: $settings.showInDock)
                    .onChange(of: settings.showInDock) { _ in
                        NSApp.delegate.flatMap { $0 as? AppDelegate }?.applyActivationPolicy()
                    }
                Toggle("Paste automatically", isOn: $settings.pasteAutomatically)
                Toggle("Prefer speed over quality", isOn: $settings.preferSpeedOverQuality)
                    .help("Uses file upload + gpt-4o-mini-transcribe + disables post-processing.")
                Toggle("Sound feedback", isOn: $settings.soundFeedbackEnabled)
                    .help("Uses short custom VoiceDock tones, not macOS system sounds.")
                Toggle("Haptic feedback", isOn: $settings.hapticFeedbackEnabled)
                    .help("Subtle haptic only on release/success/error; no haptic on recording start.")
                Toggle("Keep last audio for debugging", isOn: $settings.keepLastAudioForDebugging)
                Toggle("Log paste target app", isOn: $settings.logPasteTargetApp)
                    .help("Stores target app name/bundle in local history for debugging and repeat paste.")
                Toggle("Log target window title", isOn: $settings.logPasteTargetWindowTitle)
                    .help("Optional and off by default. Requires Accessibility and may expose document/window names in local history.")
            }

            SettingsCard("Post-processing") {
                Toggle("Enable post-processing", isOn: $settings.postProcessingEnabled)
                settingRow("Model") {
                    Picker("", selection: $settings.postProcessingModel) {
                        ForEach(PostProcessingModel.allCases) { model in Text(model.rawValue).tag(model) }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
                Stepper("Max output tokens: \(settings.postProcessingMaxOutputTokens)", value: $settings.postProcessingMaxOutputTokens, in: 256...4000, step: 128)
            }
        }
    }

    private var permissionsSection: some View {
        SettingsCard("System Permissions") {
            statusLine("Microphone", microphoneStatus)
            statusLine("Accessibility", accessibilityStatus)

            HStack {
                Button("Request Microphone") { Task { await requestMicrophonePermission() } }
                    .disabled(isBusy)
                Button("Request Accessibility") {
                    PermissionsManager.shared.openAccessibilityPrompt()
                    refreshAccessibilityStatus()
                }
                .disabled(isBusy)
                Button("Refresh") {
                    refreshMicrophoneStatus()
                    refreshAccessibilityStatus()
                }
            }
        }
    }

    private var hotkeySection: some View {
        VStack(spacing: 14) {
            SettingsCard("Hold-to-record") {
                Text("Hold Fn/Globe to record. Release to transcribe and paste/copy.")
                    .foregroundStyle(.secondary)

                HStack {
                    Button(hotkeyManager.isRunning ? "Restart Monitor" : "Start Monitor") {
                        hotkeyManager.stop()
                        hotkeyManager.start()
                    }
                    Button("Stop Monitor") { hotkeyManager.stop() }
                        .disabled(!hotkeyManager.isRunning)
                }

                HStack {
                    Button("Copy Last Result") { hotkeyManager.copyLastResult() }
                        .disabled(hotkeyManager.lastProcessedText.isEmpty)
                    Button("Paste Last Result") { Task { await hotkeyManager.pasteLastResult() } }
                        .disabled(hotkeyManager.lastProcessedText.isEmpty)
                }

                statusLine("Monitor", hotkeyManager.isRunning ? "running" : "stopped")
                statusLine("Pressed", hotkeyManager.isPressed ? "yes" : "no")
                statusLine("Status", hotkeyManager.statusMessage)
                statusLine("Transcription", hotkeyManager.lastTranscriptionModeStatus)
                statusLine("Paste", hotkeyManager.lastPasteStatus)
                if !hotkeyManager.lastError.isEmpty {
                    statusLine("Last error", hotkeyManager.lastError)
                }
            }

            if !hotkeyManager.lastProcessedText.isEmpty {
                SettingsCard(hotkeyManager.lastProcessedText.hasPrefix("# RISKY_COMMAND_PREVIEW") ? "Risky command preview" : "Last final output") {
                    if hotkeyManager.lastProcessedText.hasPrefix("# RISKY_COMMAND_PREVIEW") {
                        Text("Blocked from auto-paste. Preview is shell-commented and safe to paste, but review manually.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    previewText(hotkeyManager.lastProcessedText, height: 130)
                }
            }

            if !hotkeyManager.lastTranscript.isEmpty {
                SettingsCard("Last raw transcript") {
                    previewText(hotkeyManager.lastTranscript, height: 90)
                }
            }
        }
    }

    private var metricsSection: some View {
        SettingsCard("Latency") {
            if let stats = metricsStore.totalReleaseToPasteStats() {
                Text("successful total_release_to_paste min/avg/max: \(stats.min)/\(stats.avg)/\(stats.max) ms")
                    .font(.headline)
            } else {
                Text("No successful sessions yet.")
                    .foregroundStyle(.secondary)
            }

            modeStatsBlock(title: "Total by mode", stats: metricsStore.totalStatsByTranscriptionMode())
            modeStatsBlock(title: "STT by mode", stats: metricsStore.sttStatsByTranscriptionMode())

            HStack {
                Button("Copy Metrics Report") { copyMetricsReport() }
                    .disabled(metricsStore.sessions.isEmpty)
                Button("Clear Metrics") {
                    metricsStore.clear()
                    metricsCopyStatus = ""
                }
            }
            if !metricsCopyStatus.isEmpty {
                Text(metricsCopyStatus)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(metricsStore.sessions.prefix(12)) { metric in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(metric.summary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(metric.success ? .green : .red)
                        Text("mode=\(metric.transcriptionMode?.title ?? "n/a")  model=\(metric.model ?? "n/a")  record=\(metric.recordingDurationMs.map(String.init) ?? "n/a")ms  audio=\(metric.audioFileSizeBytes.map(String.init) ?? "n/a")B  stt=\(metric.transcriptionDurationMs.map(String.init) ?? "n/a")ms  post=\(metric.postprocessDurationMs.map(String.init) ?? "n/a")ms  paste=\(metric.pasteDurationMs.map(String.init) ?? "n/a")ms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var debugSection: some View {
        VStack(spacing: 14) {
            SettingsCard("Manual recording") {
                HStack {
                    Button("Start Recording") { Task { await startRecording() } }
                        .disabled(isBusy || audioRecorder.state == .recording)
                    Button("Stop Recording") { stopRecording() }
                        .disabled(audioRecorder.state != .recording)
                    Button("Play Last") { playLastRecording() }
                        .disabled(audioRecorder.lastRecordingURL == nil || audioRecorder.state == .recording)
                    Button("Transcribe Last") { Task { await transcribeLastRecording() } }
                        .disabled(audioRecorder.lastRecordingURL == nil || audioRecorder.state == .recording || isBusy)
                }
                statusLine("Recorder", "\(audioRecorder.state.rawValue) — \(audioRecorder.statusMessage)")
                statusLine("Last recording", lastRecordingDescription)
                statusLine("Transcription", recordingTranscriptionStatus)
            }

            SettingsCard("Experimental transcription modes") {
                settingRow("Mode") {
                    Picker("", selection: $settings.transcriptionMode) {
                        ForEach(TranscriptionMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }
                    .labelsHidden()
                    .frame(width: 360)
                }
                Text("File upload is recommended. Completed-recording stream is not true live microphone streaming. Realtime remains unstable for Russian/short phrases and falls back to file upload.")
                    .font(.caption)
                    .foregroundStyle(settings.transcriptionMode == .fileUploadAfterRelease ? Color.secondary : Color.orange)
            }

            SettingsCard("Sample audio") {
                HStack {
                    Button("Transcribe Sample Audio…") { Task { await transcribeSampleAudio() } }
                        .disabled(isBusy)
                    if isBusy { ProgressView().controlSize(.small) }
                }
                statusLine("Status", transcriptionStatus)
                if !transcriptPreview.isEmpty { previewText(transcriptPreview, height: 130) }
            }

            SettingsCard("HUD states") {
                HStack {
                    ForEach([HUDState.listening, .transcribing, .pasted, .error, .modeChanged]) { state in
                        Button(state.title) { hudController.show(state) }
                    }
                    Button("Hide") { hudController.hide() }
                }
            }

            SettingsCard("Feedback test") {
                HStack {
                    Button("Start Haptic") { FeedbackService.shared.recordingStarted() }
                    Button("Release") { FeedbackService.shared.recordingEnded() }
                    Button("Success") { FeedbackService.shared.success() }
                    Button("Error") { FeedbackService.shared.error() }
                }
                Text("If sounds play but haptics do not, macOS/device may not expose haptic feedback to this app/session. Sounds remain independent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsCard("Logs") {
                settingRow("Local log") {
                    Text(LocalLogger.shared.logFilePath())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                Button("Copy Log Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(LocalLogger.shared.logFilePath(), forType: .string)
                }
            }

            SettingsCard("Reset") {
                Text("Reset local app settings. OpenAI key is kept unless you delete it in OpenAI section.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Reset App Settings") {
                    settings.resetToDefaults()
                    NSApp.delegate.flatMap { $0 as? AppDelegate }?.applyActivationPolicy()
                }
            }
        }
    }

    private var openAISection: some View {
        SettingsCard("API Key") {
            SecureField("OpenAI API key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save API Key") { saveAPIKey() }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
                Button("Check Keychain") { refreshAPIKeyStatus() }
                    .disabled(isBusy)
                Button("Delete Key") { deleteAPIKey() }
                    .disabled(isBusy)
                Button("Test OpenAI") { Task { await testOpenAI() } }
                    .disabled(isBusy)
            }

            settingRow("Saved key") {
                Text(savedAPIKeyMask)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
            statusLine("Keychain", apiKeyStatus)
            statusLine("Test", testStatus)
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
                        Text("\(stat.mode.title): n=\(stat.count), min/avg/max \(stat.min)/\(stat.avg)/\(stat.max) ms")
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
        metricsCopyStatus = "Metrics report copied to clipboard."
    }

    private func subtitle(for section: SettingsSection) -> String {
        switch section {
        case .workflow: "Main dictation, paste and post-processing options."
        case .permissions: "Microphone and Accessibility permissions."
        case .hotkey: "Fn/Globe hold-to-record status and last outputs."
        case .metrics: "Latency for recent dictation sessions."
        case .debug: "Manual recording, sample audio and HUD controls."
        case .openAI: "API key storage and connection test."
        }
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
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try KeychainStore.shared.saveOpenAIAPIKey(key)
            apiKeyInput = ""
            savedAPIKeyMask = maskedKey(key)
            settings.savedAPIKeyMask = savedAPIKeyMask
            apiKeyStatus = "API key saved in Keychain."
            testStatus = "Not tested"
        } catch {
            apiKeyStatus = "Failed to save API key: \(error.localizedDescription)"
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainStore.shared.deleteOpenAIAPIKey()
            apiKeyInput = ""
            savedAPIKeyMask = "Not saved"
            settings.savedAPIKeyMask = savedAPIKeyMask
            apiKeyStatus = "API key deleted from Keychain."
            testStatus = "Not tested"
        } catch {
            apiKeyStatus = "Failed to delete API key: \(error.localizedDescription)"
        }
    }

    private func refreshAPIKeyStatus() {
        do {
            if let key = try KeychainStore.shared.loadOpenAIAPIKey(), !key.isEmpty {
                savedAPIKeyMask = maskedKey(key)
                settings.savedAPIKeyMask = savedAPIKeyMask
                apiKeyStatus = "API key is saved in Keychain."
            } else {
                savedAPIKeyMask = "Not saved"
                settings.savedAPIKeyMask = savedAPIKeyMask
                apiKeyStatus = "No API key saved."
            }
        } catch {
            apiKeyStatus = "Failed to read Keychain: \(error.localizedDescription)"
        }
    }

    private func testOpenAI() async {
        isBusy = true
        testStatus = "Testing OpenAI…"
        defer { isBusy = false }
        do {
            try await transcriber.testAPIKey()
            testStatus = "OpenAI test succeeded."
            refreshAPIKeyStatus()
        } catch {
            testStatus = error.localizedDescription
        }
    }

    private var lastRecordingDescription: String {
        guard let url = audioRecorder.lastRecordingURL else { return "none" }
        return "\(url.lastPathComponent), \(audioRecorder.lastRecordingDurationMs) ms, \(audioRecorder.lastRecordingSizeBytes) bytes, peak \(String(format: "%.2f", audioRecorder.lastRecordingPeakLevel))"
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
            recordingTranscriptionStatus = "No recording transcribed yet"
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
        recordingTranscriptionStatus = "Transcribing last recording…"
        hudController.show(.transcribing)
        defer { isBusy = false }

        do {
            let context = TranscriptionContext(promptMode: settings.promptMode, model: settings.sttModel.rawValue)
            let result = try await transcriber.transcribe(audioURL: url, context: context)
            transcriptPreview = try await processForPreview(result.text)
            recordingTranscriptionStatus = "Success: \(result.durationMs) ms, model: \(result.model)"
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
        transcriptionStatus = "Transcribing \(url.lastPathComponent)…"
        hudController.show(.transcribing)
        defer { isBusy = false }

        do {
            let context = TranscriptionContext(promptMode: settings.promptMode, model: settings.sttModel.rawValue)
            let result = try await transcriber.transcribe(audioURL: url, context: context)
            transcriptPreview = try await processForPreview(result.text)
            transcriptionStatus = "Success: \(result.durationMs) ms, model: \(result.model)"
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
            model: settings.postProcessingModel.rawValue,
            maxOutputTokens: settings.postProcessingMaxOutputTokens
        )
        return result.text
    }

    @MainActor
    private func openAudioFilePanel() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose sample audio"
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
        if lower.contains("success") || lower.contains("succeeded") || lower.contains("granted") || lower == "running" || lower == "yes" { return .green }
        if lower.contains("error") || lower.contains("failed") || lower.contains("invalid") || lower.contains("missing") || lower.contains("denied") || lower.contains("risky") { return .red }
        return .secondary
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
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: 680, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }
}
