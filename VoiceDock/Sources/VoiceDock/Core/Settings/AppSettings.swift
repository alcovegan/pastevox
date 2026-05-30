import Foundation

enum TranscriptionMode: String, CaseIterable, Identifiable {
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
                postProcessingEnabled = false
            }
        }
    }

    @Published var soundFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(soundFeedbackEnabled, forKey: Keys.soundFeedbackEnabled) }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled) }
    }

    private enum Keys {
        static let selectedHotkey = "selectedHotkey"
        static let promptMode = "promptMode"
        static let sttModel = "sttModel"
        static let transcriptionMode = "transcriptionMode"
        static let keepLastAudioForDebugging = "keepLastAudioForDebugging"
        static let pasteAutomatically = "pasteAutomatically"
        static let postProcessingEnabled = "postProcessingEnabled"
        static let postProcessingModel = "postProcessingModel"
        static let postProcessingMaxOutputTokens = "postProcessingMaxOutputTokens"
        static let savedAPIKeyMask = "savedAPIKeyMask"
        static let showInDock = "showInDock"
        static let preferSpeedOverQuality = "preferSpeedOverQuality"
        static let soundFeedbackEnabled = "soundFeedbackEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
    }

    func resetToDefaults() {
        selectedHotkey = "Fn/Globe hold"
        promptMode = .rawDictation
        sttModel = .gpt4oMiniTranscribe
        transcriptionMode = .fileUploadAfterRelease
        keepLastAudioForDebugging = false
        pasteAutomatically = true
        postProcessingEnabled = true
        postProcessingModel = .gpt4oMini
        postProcessingMaxOutputTokens = 1200
        savedAPIKeyMask = "Not checked"
        showInDock = false
        preferSpeedOverQuality = false
        soundFeedbackEnabled = true
        hapticFeedbackEnabled = true
    }

    private init() {
        selectedHotkey = UserDefaults.standard.string(forKey: Keys.selectedHotkey) ?? "Fn/Globe hold"
        let promptModeRaw = UserDefaults.standard.string(forKey: Keys.promptMode) ?? PromptMode.rawDictation.rawValue
        promptMode = PromptMode(rawValue: promptModeRaw) ?? .rawDictation
        let modelRaw = UserDefaults.standard.string(forKey: Keys.sttModel) ?? STTModel.gpt4oMiniTranscribe.rawValue
        sttModel = STTModel(rawValue: modelRaw) ?? .gpt4oMiniTranscribe
        let transcriptionModeRaw = UserDefaults.standard.string(forKey: Keys.transcriptionMode) ?? TranscriptionMode.fileUploadAfterRelease.rawValue
        transcriptionMode = TranscriptionMode(rawValue: transcriptionModeRaw) ?? .fileUploadAfterRelease
        keepLastAudioForDebugging = UserDefaults.standard.bool(forKey: Keys.keepLastAudioForDebugging)
        pasteAutomatically = UserDefaults.standard.object(forKey: Keys.pasteAutomatically) as? Bool ?? true
        postProcessingEnabled = UserDefaults.standard.object(forKey: Keys.postProcessingEnabled) as? Bool ?? true
        let postModelRaw = UserDefaults.standard.string(forKey: Keys.postProcessingModel) ?? PostProcessingModel.gpt4oMini.rawValue
        postProcessingModel = PostProcessingModel(rawValue: postModelRaw) ?? .gpt4oMini
        let savedMaxTokens = UserDefaults.standard.integer(forKey: Keys.postProcessingMaxOutputTokens)
        postProcessingMaxOutputTokens = savedMaxTokens > 0 ? savedMaxTokens : 1200
        savedAPIKeyMask = UserDefaults.standard.string(forKey: Keys.savedAPIKeyMask) ?? "Not checked"
        showInDock = UserDefaults.standard.object(forKey: Keys.showInDock) as? Bool ?? false
        preferSpeedOverQuality = UserDefaults.standard.object(forKey: Keys.preferSpeedOverQuality) as? Bool ?? false
        soundFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.soundFeedbackEnabled) as? Bool ?? true
        hapticFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
    }
}
