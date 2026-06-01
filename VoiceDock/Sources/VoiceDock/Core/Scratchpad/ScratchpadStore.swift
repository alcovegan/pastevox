import AppKit
import Foundation

struct ScratchpadNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var text: String
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, text: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@MainActor
final class ScratchpadStore: ObservableObject {
    static let shared = ScratchpadStore()

    @Published private(set) var notes: [ScratchpadNote] = []

    private let userDefaultsKey = "scratchpadNotes"

    private init() {
        load()
    }

    func add(text: String, title: String = "") {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        notes.insert(ScratchpadNote(title: cleanTitle.isEmpty ? defaultTitle(for: cleanText) : cleanTitle, text: cleanText), at: 0)
        save()
    }

    func update(_ note: ScratchpadNote, title: String, text: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[index].title = cleanTitle.isEmpty ? defaultTitle(for: cleanText) : cleanTitle
        notes[index].text = cleanText
        notes[index].updatedAt = Date()
        save()
    }

    func delete(_ note: ScratchpadNote) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func clear() {
        notes.removeAll()
        save()
    }

    func copy(_ note: ScratchpadNote) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.text, forType: .string)
    }

    private func defaultTitle(for text: String) -> String {
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? "Scratchpad note"
        return String(firstLine.prefix(48))
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        notes = (try? JSONDecoder().decode([ScratchpadNote].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
