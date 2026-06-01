import Foundation

struct VoiceSnippet: Identifiable, Codable, Equatable {
    let id: UUID
    var trigger: String
    var triggers: [String]
    var replacement: String
    let createdAt: Date

    init(id: UUID = UUID(), trigger: String, triggers: [String]? = nil, replacement: String, createdAt: Date = Date()) {
        self.id = id
        self.trigger = trigger
        self.triggers = triggers ?? [trigger]
        self.replacement = replacement
        self.createdAt = createdAt
    }

    var allTriggers: [String] {
        let values = [trigger] + triggers
        var seen: Set<String> = []
        return values.filter { value in
            let key = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}

struct SnippetMatch {
    let snippet: VoiceSnippet
    let matchedTrigger: String
    let outputText: String
    let confidence: Double
    let reason: String
}

@MainActor
final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published private(set) var snippets: [VoiceSnippet] = []

    private struct Candidate {
        let text: String
        let isCommand: Bool
    }

    private let userDefaultsKey = "voiceSnippets"

    private let commandPrefixes = [
        "вставь", "вставить", "вставьте", "напиши", "напишите", "напечатай", "напечатайте",
        "подставь", "добавь", "добавьте", "дай", "дайте", "поставь", "поставьте", "используй", "используйте",
        "insert", "paste", "type", "write", "add", "put", "use"
    ]

    private let fillerWords = Set([
        "пожалуйста", "плиз", "please", "мне", "сюда", "тут", "здесь", "это", "этот", "эту", "этой", "the", "a", "an"
    ])

    private init() {
        load()
    }

    func add(trigger: String, triggers: [String] = [], replacement: String) {
        let cleanTriggers = ([trigger] + triggers)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanReplacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let primary = cleanTriggers.first, !cleanReplacement.isEmpty else { return }
        guard !snippets.contains(where: { snippet in
            snippet.allTriggers.contains { existing in cleanTriggers.contains { normalized($0) == normalized(existing) } }
        }) else { return }
        snippets.insert(VoiceSnippet(trigger: primary, triggers: cleanTriggers, replacement: cleanReplacement), at: 0)
        save()
    }

    func update(_ snippet: VoiceSnippet, triggers: [String], replacement: String) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        let cleanTriggers = triggers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanReplacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let primary = cleanTriggers.first, !cleanReplacement.isEmpty else { return }
        snippets[index].trigger = primary
        snippets[index].triggers = cleanTriggers
        snippets[index].replacement = cleanReplacement
        save()
    }

    func delete(_ snippet: VoiceSnippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    func clear() {
        snippets.removeAll()
        save()
    }

    func match(for text: String) -> SnippetMatch? {
        let input = normalized(text)
        guard !input.isEmpty else { return nil }

        let candidates = candidatePhrases(from: input)
        var best: SnippetMatch?

        for snippet in snippets {
            for triggerText in snippet.allTriggers {
                let trigger = normalized(triggerText)
                guard !trigger.isEmpty else { continue }

                for candidate in candidates {
                    let match = matchCandidate(candidate, trigger: trigger, triggerText: triggerText, snippet: snippet)
                    if let match, best == nil || match.confidence > best!.confidence {
                        best = match
                    }
                }
            }
        }

        return best
    }

    private func matchCandidate(_ candidate: Candidate, trigger: String, triggerText: String, snippet: VoiceSnippet) -> SnippetMatch? {
        if candidate.text == trigger {
            return SnippetMatch(
                snippet: snippet,
                matchedTrigger: triggerText,
                outputText: snippet.replacement,
                confidence: 1.0,
                reason: candidate.isCommand ? "command_exact" : "exact"
            )
        }

        let candidateTokens = tokens(candidate.text)
        let triggerTokens = tokens(trigger)
        guard !candidateTokens.isEmpty, !triggerTokens.isEmpty else { return nil }

        if let range = subsequenceRange(triggerTokens, in: candidateTokens) {
            let output = candidate.isCommand ? snippet.replacement : replaceTokens(in: candidateTokens, range: range, replacement: snippet.replacement)
            return SnippetMatch(
                snippet: snippet,
                matchedTrigger: triggerText,
                outputText: output,
                confidence: 0.96,
                reason: candidate.isCommand ? "command_token_subsequence" : "partial_token_subsequence"
            )
        }

        let tokenSetScore = tokenCoverage(triggerTokens: triggerTokens, candidateTokens: candidateTokens)
        if tokenSetScore >= 0.75 {
            return SnippetMatch(
                snippet: snippet,
                matchedTrigger: triggerText,
                outputText: candidate.isCommand ? snippet.replacement : snippet.replacement,
                confidence: tokenSetScore * 0.92,
                reason: candidate.isCommand ? "command_token_coverage" : "token_coverage_replacement"
            )
        }

        let similarity = similarity(candidate.text, trigger)
        if similarity >= 0.74 {
            return SnippetMatch(
                snippet: snippet,
                matchedTrigger: triggerText,
                outputText: snippet.replacement,
                confidence: similarity * 0.9,
                reason: candidate.isCommand ? "command_fuzzy_phrase" : "fuzzy_phrase"
            )
        }

        return nil
    }

    private func candidatePhrases(from input: String) -> [Candidate] {
        var candidates: [Candidate] = [Candidate(text: input, isCommand: false)]
        let inputTokens = tokens(input)

        for prefix in commandPrefixes {
            if input.hasPrefix(prefix + " ") {
                candidates.append(Candidate(
                    text: String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines),
                    isCommand: true
                ))
            }
        }

        let withoutFillers = inputTokens.filter { !fillerWords.contains($0) }.joined(separator: " ")
        if !withoutFillers.isEmpty {
            candidates.append(Candidate(text: withoutFillers, isCommand: false))
        }

        for prefix in commandPrefixes {
            let strippedTokens = inputTokens.drop(while: { $0 == prefix || fillerWords.contains($0) })
            let stripped = strippedTokens.joined(separator: " ")
            if !stripped.isEmpty, stripped != input {
                candidates.append(Candidate(text: stripped, isCommand: true))
            }
        }

        var seen: Set<String> = []
        return candidates.filter { candidate in
            let key = "\(candidate.isCommand)-\(candidate.text)"
            guard !candidate.text.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func subsequenceRange(_ needle: [String], in haystack: [String]) -> Range<Int>? {
        guard needle.count <= haystack.count else { return nil }
        for start in 0...(haystack.count - needle.count) {
            let window = Array(haystack[start..<(start + needle.count)])
            if zip(needle, window).allSatisfy({ tokenSimilar($0.0, $0.1) }) {
                return start..<(start + needle.count)
            }
        }
        return nil
    }

    private func replaceTokens(in tokens: [String], range: Range<Int>, replacement: String) -> String {
        let prefix = tokens[..<range.lowerBound].joined(separator: " ")
        let suffix = tokens[range.upperBound...].joined(separator: " ")
        return [prefix, replacement, suffix]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func tokenCoverage(triggerTokens: [String], candidateTokens: [String]) -> Double {
        var matched = 0
        var used = Set<Int>()
        for triggerToken in triggerTokens {
            if let index = candidateTokens.indices.first(where: { !used.contains($0) && tokenSimilar(triggerToken, candidateTokens[$0]) }) {
                used.insert(index)
                matched += 1
            }
        }
        return Double(matched) / Double(triggerTokens.count)
    }

    private func tokenSimilar(_ lhs: String, _ rhs: String) -> Bool {
        lhs == rhs || similarity(lhs, rhs) >= 0.72 || phoneticKey(lhs) == phoneticKey(rhs)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        let decoded = (try? JSONDecoder().decode([VoiceSnippet].self, from: data)) ?? []
        snippets = decoded.map { snippet in
            var migrated = snippet
            if migrated.triggers.isEmpty { migrated.triggers = [migrated.trigger] }
            return migrated
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private func tokens(_ value: String) -> [String] {
        normalized(value)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty && !fillerWords.contains($0) }
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?:;\"'`“”«»()[]{}"))
            .replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func phoneticKey(_ value: String) -> String {
        normalized(value)
            .replacingOccurrences(of: "prompt", with: "промт")
            .replacingOccurrences(of: "ph", with: "f")
            .replacingOccurrences(of: "п", with: "")
            .replacingOccurrences(of: "p", with: "")
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        let distance = levenshtein(lhs, rhs)
        return 1.0 - Double(distance) / Double(max(lhs.count, rhs.count))
    }

    private func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous = Array(0...b.count)
        var current = Array(repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }

        return previous[b.count]
    }
}
