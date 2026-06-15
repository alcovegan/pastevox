import Foundation

struct DictionaryTerm: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var note: String
    let createdAt: Date

    init(id: UUID = UUID(), text: String, note: String = "", createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.note = note
        self.createdAt = createdAt
    }
}

@MainActor
final class DictionaryStore: ObservableObject {
    static let shared = DictionaryStore()
    nonisolated static let userDefaultsKey = "dictionaryTerms"

    @Published private(set) var terms: [DictionaryTerm] = []

    private init() {
        load()
    }

    func add(text: String, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !terms.contains(where: { $0.text.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        terms.insert(DictionaryTerm(text: trimmed, note: note.trimmingCharacters(in: .whitespacesAndNewlines)), at: 0)
        save()
    }

    func delete(_ term: DictionaryTerm) {
        terms.removeAll { $0.id == term.id }
        save()
    }

    func clear() {
        terms.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return }
        terms = (try? JSONDecoder().decode([DictionaryTerm].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(terms) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    nonisolated static func promptText(maxTerms: Int = 80) -> String? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let terms = try? JSONDecoder().decode([DictionaryTerm].self, from: data)
        else { return nil }

        let values = terms
            .prefix(maxTerms)
            .map { term -> String in
                if term.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return term.text
                }
                return "\(term.text) (\(term.note))"
            }

        guard !values.isEmpty else { return nil }
        return "Prefer these custom dictionary terms and spellings when transcribing: " + values.joined(separator: ", ")
    }
}
