import AppKit
import Foundation

enum DictationHistoryStatus: String, Codable {
    case pasted
    case copied
    case ignored
    case error

    var title: String {
        switch self {
        case .pasted: "Pasted"
        case .copied: "Copied"
        case .ignored: "Ignored"
        case .error: "Error"
        }
    }
}

struct DictationHistoryEntry: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let transcript: String
    let output: String
    let promptMode: PromptMode
    let transcriptionMode: TranscriptionMode
    let model: String
    let status: DictationHistoryStatus
    let statusMessage: String
    let target: PasteTarget?
    let durationMs: Int?
    let wordCount: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        transcript: String,
        output: String,
        promptMode: PromptMode,
        transcriptionMode: TranscriptionMode,
        model: String,
        status: DictationHistoryStatus,
        statusMessage: String,
        target: PasteTarget?,
        durationMs: Int?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.transcript = transcript
        self.output = output
        self.promptMode = promptMode
        self.transcriptionMode = transcriptionMode
        self.model = model
        self.status = status
        self.statusMessage = statusMessage
        self.target = target
        self.durationMs = durationMs
        self.wordCount = output.split { $0.isWhitespace || $0.isNewline }.count
    }
}

@MainActor
final class DictationHistoryStore: ObservableObject {
    static let shared = DictationHistoryStore()

    @Published private(set) var entries: [DictationHistoryEntry] = []

    private let userDefaultsKey = "dictationHistoryEntries"
    private let maxEntries = 80

    private init() {
        load()
    }

    var todayEntries: [DictationHistoryEntry] {
        entries.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    var totalWords: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    var averageWordsPerMinute: Int? {
        let values = entries.compactMap { entry -> Int? in
            guard let durationMs = entry.durationMs, durationMs > 0, entry.wordCount > 0 else { return nil }
            return Int(Double(entry.wordCount) / (Double(durationMs) / 60_000.0))
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    func add(_ entry: DictationHistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
        save()
    }

    func delete(_ entry: DictationHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    func copy(_ entry: DictationHistoryEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.output, forType: .string)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        entries = (try? JSONDecoder().decode([DictationHistoryEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
