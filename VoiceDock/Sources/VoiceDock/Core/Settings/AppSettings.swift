import Foundation

enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case fileUploadAfterRelease
    case streamingCompletedRecording
    case realtimeMicrophoneStreaming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fileUploadAfterRelease: "Best quality: file upload"
        case .streamingCompletedRecording: "Experimental: completed-recording stream"
        case .realtimeMicrophoneStreaming: "Experimental: realtime microphone"
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

    var instruction: String {
        switch self {
        case .default:
            "Сохраняй естественный стиль пользователя."
        case .concise:
            "Сделай результат кратким, плотным и без лишних слов."
        case .friendly:
            "Сделай тон дружелюбным, живым и понятным, без чрезмерной официальности."
        case .formal:
            "Сделай тон профессиональным, аккуратным и формальным."
        case .codingAgent:
            "Сформулируй как чёткую задачу для coding agent: цель, контекст, ограничения, критерии готовности."
        case .chat:
            "Сформулируй как короткое сообщение для чата/мессенджера."
        case .email:
            "Сформулируй как аккуратный email или email-фрагмент с уместным тоном."
        }
    }
}

enum STTModel: String, CaseIterable, Identifiable {
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case whisper1 = "whisper-1"

    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedHotkey: String {
        didSet { UserDefaults.standard.set(selectedHotkey, forKey: Keys.selectedHotkey) }
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

    private enum Keys {
        static let selectedHotkey = "selectedHotkey"
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
        static let preferSpeedOverQuality = "preferSpeedOverQuality"
        static let soundFeedbackEnabled = "soundFeedbackEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let logPasteTargetApp = "logPasteTargetApp"
        static let logPasteTargetWindowTitle = "logPasteTargetWindowTitle"
        static let appAwareModeSwitchingEnabled = "appAwareModeSwitchingEnabled"
    }

    func resetToDefaults() {
        selectedHotkey = "Fn/Globe hold"
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
        preferSpeedOverQuality = false
        soundFeedbackEnabled = true
        hapticFeedbackEnabled = true
        logPasteTargetApp = true
        logPasteTargetWindowTitle = false
        appAwareModeSwitchingEnabled = false
    }

    private init() {
        selectedHotkey = UserDefaults.standard.string(forKey: Keys.selectedHotkey) ?? "Fn/Globe hold"
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
        preferSpeedOverQuality = UserDefaults.standard.object(forKey: Keys.preferSpeedOverQuality) as? Bool ?? false
        soundFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.soundFeedbackEnabled) as? Bool ?? true
        hapticFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
        logPasteTargetApp = UserDefaults.standard.object(forKey: Keys.logPasteTargetApp) as? Bool ?? true
        logPasteTargetWindowTitle = UserDefaults.standard.object(forKey: Keys.logPasteTargetWindowTitle) as? Bool ?? false
        appAwareModeSwitchingEnabled = UserDefaults.standard.object(forKey: Keys.appAwareModeSwitchingEnabled) as? Bool ?? false
    }
}
