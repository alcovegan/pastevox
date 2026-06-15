import Foundation

enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case fileUploadAfterRelease
    case streamingCompletedRecording
    case realtimeMicrophoneStreaming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fileUploadAfterRelease: T("Best quality: file upload")
        case .streamingCompletedRecording: T("Experimental: completed-recording stream")
        case .realtimeMicrophoneStreaming: T("Experimental: realtime microphone")
        }
    }
}

enum PostProcessingModel: String, CaseIterable, Identifiable {
    case gpt4oMini = "gpt-4o-mini"
    case gpt4o = "gpt-4o"

    var id: String { rawValue }
}

enum WritingStyle: String, CaseIterable, Identifiable, Codable {
    case `default`
    case concise
    case friendly
    case formal
    case codingAgent
    case chat
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "Default"
        case .concise: "Concise"
        case .friendly: "Friendly"
        case .formal: "Formal"
        case .codingAgent: "Coding Agent"
        case .chat: "Chat"
        case .email: "Email"
        }
    }

    var shortTitle: String {
        switch self {
        case .default: "Default"
        case .concise: "Concise"
        case .friendly: "Friendly"
        case .formal: "Formal"
        case .codingAgent: "Coding"
        case .chat: "Chat"
        case .email: "Email"
        }
    }

}

enum STTModel: String, CaseIterable, Identifiable {
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case whisper1 = "whisper-1"

    var id: String { rawValue }
}

enum PromptLanguageMode: String, CaseIterable, Identifiable, Codable {
    case followApp
    case en
    case ru

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followApp: return T("Match app language")
        case .en: return "English"
        case .ru: return "Русский"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedHotkey: String {
        didSet { UserDefaults.standard.set(selectedHotkey, forKey: Keys.selectedHotkey) }
    }

    @Published var holdHotkeyKind: HotkeyKind {
        didSet {
            selectedHotkey = holdHotkeyKind.title
            UserDefaults.standard.set(holdHotkeyKind.rawValue, forKey: Keys.holdHotkeyKind)
        }
    }

    @Published var promptMode: PromptMode {
        didSet { UserDefaults.standard.set(promptMode.rawValue, forKey: Keys.promptMode) }
    }

    @Published var writingStyle: WritingStyle {
        didSet { UserDefaults.standard.set(writingStyle.rawValue, forKey: Keys.writingStyle) }
    }

    @Published var sttModel: STTModel {
        didSet { UserDefaults.standard.set(sttModel.rawValue, forKey: Keys.sttModel) }
    }

    @Published var transcriptionMode: TranscriptionMode {
        didSet { UserDefaults.standard.set(transcriptionMode.rawValue, forKey: Keys.transcriptionMode) }
    }

    @Published var keepLastAudioForDebugging: Bool {
        didSet { UserDefaults.standard.set(keepLastAudioForDebugging, forKey: Keys.keepLastAudioForDebugging) }
    }

    @Published var pasteAutomatically: Bool {
        didSet { UserDefaults.standard.set(pasteAutomatically, forKey: Keys.pasteAutomatically) }
    }

    @Published var postProcessingEnabled: Bool {
        didSet { UserDefaults.standard.set(postProcessingEnabled, forKey: Keys.postProcessingEnabled) }
    }

    @Published var postProcessingEnabledModes: Set<PromptMode> {
        didSet { UserDefaults.standard.set(postProcessingEnabledModes.map(\.rawValue), forKey: Keys.postProcessingEnabledModes) }
    }

    @Published var postProcessingModel: PostProcessingModel {
        didSet { UserDefaults.standard.set(postProcessingModel.rawValue, forKey: Keys.postProcessingModel) }
    }

    @Published var postProcessingMaxOutputTokens: Int {
        didSet { UserDefaults.standard.set(postProcessingMaxOutputTokens, forKey: Keys.postProcessingMaxOutputTokens) }
    }

    @Published var savedAPIKeyMask: String {
        didSet { UserDefaults.standard.set(savedAPIKeyMask, forKey: Keys.savedAPIKeyMask) }
    }

    @Published var showInDock: Bool {
        didSet { UserDefaults.standard.set(showInDock, forKey: Keys.showInDock) }
    }

    @Published var fnHoldToRecordEnabled: Bool {
        didSet { UserDefaults.standard.set(fnHoldToRecordEnabled, forKey: Keys.fnHoldToRecordEnabled) }
    }

    @Published var preferSpeedOverQuality: Bool {
        didSet {
            UserDefaults.standard.set(preferSpeedOverQuality, forKey: Keys.preferSpeedOverQuality)
            if preferSpeedOverQuality {
                transcriptionMode = .fileUploadAfterRelease
                sttModel = .gpt4oMiniTranscribe
            }
        }
    }

    @Published var soundFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(soundFeedbackEnabled, forKey: Keys.soundFeedbackEnabled) }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled) }
    }

    @Published var logPasteTargetApp: Bool {
        didSet { UserDefaults.standard.set(logPasteTargetApp, forKey: Keys.logPasteTargetApp) }
    }

    @Published var logPasteTargetWindowTitle: Bool {
        didSet { UserDefaults.standard.set(logPasteTargetWindowTitle, forKey: Keys.logPasteTargetWindowTitle) }
    }

    @Published var appAwareModeSwitchingEnabled: Bool {
        didSet { UserDefaults.standard.set(appAwareModeSwitchingEnabled, forKey: Keys.appAwareModeSwitchingEnabled) }
    }

    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: Keys.appLanguage)
            L10n.languageCode = appLanguage.resolvedCode
            NotificationCenter.default.post(name: .appLanguageChanged, object: nil)
        }
    }

    @Published var promptLanguageMode: PromptLanguageMode {
        didSet { UserDefaults.standard.set(promptLanguageMode.rawValue, forKey: Keys.promptLanguageMode) }
    }

    @Published var promptOverrides: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(promptOverrides) {
                UserDefaults.standard.set(data, forKey: Keys.promptOverrides)
            }
        }
    }

    private enum Keys {
        static let selectedHotkey = "selectedHotkey"
        static let holdHotkeyKind = "holdHotkeyKind"
        static let promptMode = "promptMode"
        static let writingStyle = "writingStyle"
        static let sttModel = "sttModel"
        static let transcriptionMode = "transcriptionMode"
        static let keepLastAudioForDebugging = "keepLastAudioForDebugging"
        static let pasteAutomatically = "pasteAutomatically"
        static let postProcessingEnabled = "postProcessingEnabled"
        static let postProcessingEnabledModes = "postProcessingEnabledModes"
        static let postProcessingModel = "postProcessingModel"
        static let postProcessingMaxOutputTokens = "postProcessingMaxOutputTokens"
        static let savedAPIKeyMask = "savedAPIKeyMask"
        static let showInDock = "showInDock"
        static let fnHoldToRecordEnabled = "fnHoldToRecordEnabled"
        static let preferSpeedOverQuality = "preferSpeedOverQuality"
        static let soundFeedbackEnabled = "soundFeedbackEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let logPasteTargetApp = "logPasteTargetApp"
        static let logPasteTargetWindowTitle = "logPasteTargetWindowTitle"
        static let appAwareModeSwitchingEnabled = "appAwareModeSwitchingEnabled"
        static let appLanguage = "appLanguage"
        static let promptLanguageMode = "promptLanguageMode"
        static let promptOverrides = "promptOverrides"
    }

    func resetToDefaults() {
        holdHotkeyKind = .fnHold
        selectedHotkey = holdHotkeyKind.title
        promptMode = .rawDictation
        writingStyle = .default
        sttModel = .gpt4oMiniTranscribe
        transcriptionMode = .fileUploadAfterRelease
        keepLastAudioForDebugging = false
        pasteAutomatically = true
        postProcessingEnabled = true
        postProcessingEnabledModes = [.agentPrompt, .ralphPrompt, .terminalCommand]
        postProcessingModel = .gpt4oMini
        postProcessingMaxOutputTokens = 1200
        savedAPIKeyMask = "Not checked"
        showInDock = false
        fnHoldToRecordEnabled = true
        preferSpeedOverQuality = false
        soundFeedbackEnabled = true
        hapticFeedbackEnabled = true
        logPasteTargetApp = true
        logPasteTargetWindowTitle = false
        appAwareModeSwitchingEnabled = false
        appLanguage = .system
        promptLanguageMode = .followApp
        promptOverrides = [:]
    }

    /// The language used for built-in (non-overridden) post-processing prompts.
    var resolvedPromptLanguage: String {
        switch promptLanguageMode {
        case .followApp: return appLanguage.resolvedCode
        case .en: return "en"
        case .ru: return "ru"
        }
    }

    /// Non-empty per-mode custom prompt, if the user set one (wins over the default).
    func promptOverride(for mode: PromptMode) -> String? {
        guard let value = promptOverrides[mode.rawValue],
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return value
    }

    func hasPromptOverride(for mode: PromptMode) -> Bool {
        promptOverride(for: mode) != nil
    }

    /// Store an override; clears it if empty or identical to the current-language default.
    func setPromptOverride(_ text: String, for mode: PromptMode) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultPrompt = DefaultPrompts.modePrompt(mode, language: resolvedPromptLanguage)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == defaultPrompt {
            promptOverrides[mode.rawValue] = nil
        } else {
            promptOverrides[mode.rawValue] = text
        }
    }

    func resetPromptOverride(for mode: PromptMode) {
        promptOverrides[mode.rawValue] = nil
    }

    private init() {
        let holdHotkeyRaw = UserDefaults.standard.string(forKey: Keys.holdHotkeyKind) ?? HotkeyKind.fnHold.rawValue
        let resolvedHoldHotkeyKind = HotkeyKind(rawValue: holdHotkeyRaw) ?? .fnHold
        holdHotkeyKind = resolvedHoldHotkeyKind
        selectedHotkey = resolvedHoldHotkeyKind.title
        let promptModeRaw = UserDefaults.standard.string(forKey: Keys.promptMode) ?? PromptMode.rawDictation.rawValue
        promptMode = PromptMode(rawValue: promptModeRaw) ?? .rawDictation
        let styleRaw = UserDefaults.standard.string(forKey: Keys.writingStyle) ?? WritingStyle.default.rawValue
        writingStyle = WritingStyle(rawValue: styleRaw) ?? .default
        let modelRaw = UserDefaults.standard.string(forKey: Keys.sttModel) ?? STTModel.gpt4oMiniTranscribe.rawValue
        sttModel = STTModel(rawValue: modelRaw) ?? .gpt4oMiniTranscribe
        let transcriptionModeRaw = UserDefaults.standard.string(forKey: Keys.transcriptionMode) ?? TranscriptionMode.fileUploadAfterRelease.rawValue
        transcriptionMode = TranscriptionMode(rawValue: transcriptionModeRaw) ?? .fileUploadAfterRelease
        keepLastAudioForDebugging = UserDefaults.standard.bool(forKey: Keys.keepLastAudioForDebugging)
        pasteAutomatically = UserDefaults.standard.object(forKey: Keys.pasteAutomatically) as? Bool ?? true
        postProcessingEnabled = UserDefaults.standard.object(forKey: Keys.postProcessingEnabled) as? Bool ?? true
        if let enabledModeRawValues = UserDefaults.standard.stringArray(forKey: Keys.postProcessingEnabledModes) {
            postProcessingEnabledModes = Set(enabledModeRawValues.compactMap(PromptMode.init(rawValue:)))
        } else {
            postProcessingEnabledModes = [.agentPrompt, .ralphPrompt, .terminalCommand]
        }
        let postModelRaw = UserDefaults.standard.string(forKey: Keys.postProcessingModel) ?? PostProcessingModel.gpt4oMini.rawValue
        postProcessingModel = PostProcessingModel(rawValue: postModelRaw) ?? .gpt4oMini
        let savedMaxTokens = UserDefaults.standard.integer(forKey: Keys.postProcessingMaxOutputTokens)
        postProcessingMaxOutputTokens = savedMaxTokens > 0 ? savedMaxTokens : 1200
        savedAPIKeyMask = UserDefaults.standard.string(forKey: Keys.savedAPIKeyMask) ?? "Not checked"
        showInDock = UserDefaults.standard.object(forKey: Keys.showInDock) as? Bool ?? false
        fnHoldToRecordEnabled = UserDefaults.standard.object(forKey: Keys.fnHoldToRecordEnabled) as? Bool ?? true
        preferSpeedOverQuality = UserDefaults.standard.object(forKey: Keys.preferSpeedOverQuality) as? Bool ?? false
        soundFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.soundFeedbackEnabled) as? Bool ?? true
        hapticFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
        logPasteTargetApp = UserDefaults.standard.object(forKey: Keys.logPasteTargetApp) as? Bool ?? true
        logPasteTargetWindowTitle = UserDefaults.standard.object(forKey: Keys.logPasteTargetWindowTitle) as? Bool ?? false
        appAwareModeSwitchingEnabled = UserDefaults.standard.object(forKey: Keys.appAwareModeSwitchingEnabled) as? Bool ?? false
        let appLanguageRaw = UserDefaults.standard.string(forKey: Keys.appLanguage) ?? AppLanguage.system.rawValue
        appLanguage = AppLanguage(rawValue: appLanguageRaw) ?? .system
        let promptLangRaw = UserDefaults.standard.string(forKey: Keys.promptLanguageMode) ?? PromptLanguageMode.followApp.rawValue
        promptLanguageMode = PromptLanguageMode(rawValue: promptLangRaw) ?? .followApp
        if let data = UserDefaults.standard.data(forKey: Keys.promptOverrides),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            promptOverrides = decoded
        } else {
            promptOverrides = [:]
        }
        L10n.languageCode = appLanguage.resolvedCode
    }
}
