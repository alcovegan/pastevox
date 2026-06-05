import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum HomeSection: String, CaseIterable, Identifiable {
    case history = "History"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case scratchpad = "Scratchpad"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .history: "clock"
        case .dictionary: "character.book.closed"
        case .snippets: "scissors"
        case .scratchpad: "note.text"
        }
    }
}

struct HomeView: View {
    @ObservedObject private var historyStore = DictationHistoryStore.shared
    @ObservedObject private var dictionaryStore = DictionaryStore.shared
    @ObservedObject private var snippetStore = SnippetStore.shared
    @ObservedObject private var scratchpadStore = ScratchpadStore.shared
    @ObservedObject private var audioRecorder = AudioRecorder.shared
    @State private var selectedSection: HomeSection = .history
    @State private var status = ""
    @State private var newDictionaryTerm = ""
    @State private var newDictionaryNote = ""
    @State private var newSnippetTriggers: [String] = [""]
    @State private var newSnippetReplacement = ""
    @State private var newSnippetStatus = ""
    @State private var snippetSearch = ""
    @State private var snippetTestInput = ""
    @State private var snippetTestOutput = ""
    @State private var snippetTestStatus = ""
    @State private var isSnippetTestBusy = false
    @State private var editingSnippetID: UUID?
    @State private var scratchpadTitle = ""
    @State private var scratchpadText = ""
    @State private var scratchpadStatus = ""
    @State private var editingScratchpadID: UUID?

    private let transcriber = OpenAIFileTranscriber()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    content
                }
                .padding(.horizontal, 42)
                .padding(.vertical, 34)
                .frame(maxWidth: 940, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .background(homeBackground)
        }
        .frame(minWidth: 980, idealWidth: 1120, minHeight: 700, idealHeight: 780)
    }

    private var homeBackground: some ShapeStyle {
        LinearGradient(
            colors: [HomePalette.surface, HomePalette.background],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sidebarBackground: some ShapeStyle {
        HomePalette.surfaceSecondary
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(LinearGradient(colors: [HomePalette.ink, HomePalette.ink.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text("PasteVox")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Home")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 16)

            ForEach(HomeSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .frame(width: 18)
                        Text(section.rawValue)
                        Spacer()
                    }
                    .font(.system(size: 14, weight: selectedSection == section ? .semibold : .medium))
                    .padding(.vertical, 9)
                    .padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(selectedSection == section ? Color.primary.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(selectedSection == section ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button("Settings") {
                SettingsWindowController.shared.show(
                    settings: AppSettings.shared,
                    hudController: FloatingHUDController.shared
                )
            }
            .buttonStyle(HomeButtonStyle(.secondary, size: .regular))
        }
        .padding(20)
        .frame(width: 232)
        .background(sidebarBackground)
        .overlay(Rectangle().fill(HomePalette.line).frame(width: 1), alignment: .trailing)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(selectedSection.rawValue)
                .font(.system(size: 40, weight: .semibold))
                .tracking(-0.6)
            Text(subtitle(for: selectedSection))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedSection {
        case .history:
            stats
            usageDashboard
            recentDictations
        case .dictionary:
            dictionarySection
        case .snippets:
            snippetsSection
        case .scratchpad:
            scratchpadSection
        }
    }

    private var stats: some View {
        HStack(spacing: 14) {
            HomeCard("Today") {
                Text("\(historyStore.todayEntries.count)")
                    .font(.system(size: 38, weight: .semibold))
                    .tracking(-0.8)
                Text("dictations")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            HomeCard("Words") {
                Text("\(historyStore.totalWords)")
                    .font(.system(size: 38, weight: .semibold))
                    .tracking(-0.8)
                Text(historyStore.averageWordsPerMinute.map { "~\($0) wpm" } ?? "wpm n/a")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            HomeCard("Mode") {
                Text(AppSettings.shared.promptMode.shortTitle)
                    .font(.system(size: 30, weight: .semibold))
                    .tracking(-0.3)
                Text("Fn+1/2/3/4 to switch")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var usageDashboard: some View {
        HStack(alignment: .top, spacing: 14) {
            HomeCard("Delivery", isSoft: true) {
                HStack(spacing: 8) {
                    miniStat("\(historyStore.pastedCount)", "Pasted")
                    miniStat("\(historyStore.copiedCount)", "Copied")
                    miniStat("\(historyStore.ignoredCount)", "Ignored")
                    miniStat("\(historyStore.errorCount)", "Errors")
                }
            }

            HomeCard("Top apps", isSoft: true) {
                let apps = historyStore.topApps()
                if apps.isEmpty {
                    Text("No app data yet")
                        .font(.system(size: 13))
                        .foregroundStyle(HomePalette.muted)
                } else {
                    VStack(spacing: 10) {
                        let maxCount = max(apps.map(\.count).max() ?? 1, 1)
                        ForEach(apps, id: \.name) { app in
                            appUsageRow(name: app.name, count: app.count, maxCount: maxCount)
                        }
                    }
                }
            }
        }
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.4)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HomePalette.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HomePalette.line, lineWidth: 1))
    }

    private func appUsageRow(name: String, count: Int, maxCount: Int) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HomePalette.ink)
                .lineLimit(1)
                .frame(width: 84, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(HomePalette.ink.opacity(0.08))
                    Capsule().fill(HomePalette.ink.opacity(0.72))
                        .frame(width: proxy.size.width * CGFloat(count) / CGFloat(maxCount))
                }
            }
            .frame(height: 7)
            Text("\(count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HomePalette.muted)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private var dictionarySection: some View {
        VStack(spacing: 14) {
            HomeCard("Add term") {
                VStack(spacing: 14) {
                    Text("Dictionary terms are sent as STT context so OpenAI prefers your names, project terms and spellings.")
                        .font(.system(size: 14))
                        .foregroundStyle(HomePalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Term")
                                .font(.system(size: 13, weight: .semibold))
                            HomeInputField("PasteVox, project name, email…", text: $newDictionaryTerm)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.system(size: 13, weight: .semibold))
                            HomeInputField("Optional spelling/context hint", text: $newDictionaryNote)
                        }
                    }

                    Divider().overlay(HomePalette.line)

                    HStack {
                        Text("Terms are local and only used as transcription context.")
                            .font(.system(size: 12))
                            .foregroundStyle(HomePalette.muted)
                        Spacer()
                        Button("Clear Dictionary") { dictionaryStore.clear() }
                            .buttonStyle(HomeButtonStyle(.danger))
                            .disabled(dictionaryStore.terms.isEmpty)
                        Button("Add Term") {
                            dictionaryStore.add(text: newDictionaryTerm, note: newDictionaryNote)
                            newDictionaryTerm = ""
                            newDictionaryNote = ""
                        }
                        .buttonStyle(HomeButtonStyle(.primary, size: .large))
                        .disabled(newDictionaryTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }

            HomeCard("Terms") {
                if dictionaryStore.terms.isEmpty {
                    emptyState(
                        icon: "character.book.closed",
                        title: "No dictionary terms yet",
                        message: "Add names, emails, project names, acronyms or words STT often misspells."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(dictionaryStore.terms) { term in
                            HStack(alignment: .center, spacing: 14) {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(term.text)
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 9)
                                        .background(HomePalette.sand, in: Capsule())
                                    if !term.note.isEmpty {
                                        Text(term.note)
                                            .font(.system(size: 13))
                                            .foregroundStyle(HomePalette.muted)
                                    }
                                }
                                Spacer()
                                Button("Delete") { dictionaryStore.delete(term) }
                                    .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                            }
                            .padding(.vertical, 12)
                            if term.id != dictionaryStore.terms.last?.id {
                                Divider().overlay(HomePalette.line)
                            }
                        }
                    }
                }
            }
        }
    }

    private var snippetsSection: some View {
        VStack(spacing: 14) {
            HomeCard(editingSnippetID == nil ? "Create snippet" : "Edit snippet") {
                VStack(spacing: 18) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Trigger phrases")
                                .font(.system(size: 13, weight: .semibold))
                            Text("What you say. New phrases are added below the list.")
                                .font(.system(size: 12))
                                .foregroundStyle(HomePalette.muted)

                            VStack(spacing: 9) {
                                ForEach(newSnippetTriggers.indices, id: \.self) { index in
                                    HStack(spacing: 8) {
                                        HomeInputField(index == 0 ? "my email" : "insert my email", text: $newSnippetTriggers[index])
                                        Button("−") { newSnippetTriggers.remove(at: index) }
                                            .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                                            .disabled(newSnippetTriggers.count == 1)
                                    }
                                }
                            }

                            HStack(spacing: 8) {
                                Button("+ Phrase") { newSnippetTriggers.append("") }
                                    .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                Button("Generate variants") { generateSnippetVariants() }
                                    .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    .disabled(newSnippetTriggers.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
                        .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(HomePalette.line, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Replacement")
                                .font(.system(size: 13, weight: .semibold))
                            Text("What PasteVox inserts when a trigger matches.")
                                .font(.system(size: 12))
                                .foregroundStyle(HomePalette.muted)
                            TextEditor(text: $newSnippetReplacement)
                                .homeTextEditor(height: 150)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
                        .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(HomePalette.line, lineWidth: 1))
                    }

                    HStack(spacing: 8) {
                        Button("Example: email") {
                            newSnippetTriggers = ["мой имейл", "вставь мой имейл"]
                            newSnippetReplacement = "alexey@example.com"
                            newSnippetStatus = ""
                        }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                        Button("Example: RALPH") {
                            newSnippetTriggers = ["ральф промт", "вставь ральф промт", "ralph prompt"]
                            newSnippetReplacement = """
                            Роль:
                            Цель:
                            Контекст:
                            Ограничения:
                            Acceptance criteria:
                            """
                            newSnippetStatus = ""
                        }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                        Spacer()
                    }

                    Divider().overlay(HomePalette.line)

                    HStack(spacing: 10) {
                        Text(newSnippetStatus.isEmpty ? "Local matching only · no LLM · conflicts checked before save" : newSnippetStatus)
                            .font(.system(size: 12))
                            .foregroundStyle(newSnippetStatus.isEmpty ? HomePalette.muted : statusColor(newSnippetStatus))
                        Spacer()
                        if editingSnippetID != nil {
                            Button("Cancel") { resetSnippetForm() }
                                .buttonStyle(HomeButtonStyle(.secondary))
                        }
                        Button("Clear") { resetSnippetForm() }
                            .buttonStyle(HomeButtonStyle(.secondary))
                        Button(editingSnippetID == nil ? "Save Snippet" : "Update Snippet") { saveSnippet() }
                            .buttonStyle(HomeButtonStyle(.primary, size: .large))
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }

            HomeCard("Test snippet") {
                Text("Type a transcript or record a test phrase. This never pastes anywhere.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                HomeInputField("insert my email", text: $snippetTestInput)
                HStack {
                    Button("Test") { testSnippetInput() }
                        .buttonStyle(HomeButtonStyle(.primary))
                    Button(audioRecorder.state == .recording ? "Stop & Test" : "Record Test") {
                        Task {
                            if audioRecorder.state == .recording {
                                await stopAndTestSnippetRecording()
                            } else {
                                await startSnippetTestRecording()
                            }
                        }
                    }
                    .buttonStyle(HomeButtonStyle(audioRecorder.state == .recording ? .danger : .secondary))
                    .disabled(isSnippetTestBusy)
                    Button("Clear") {
                        snippetTestInput = ""
                        snippetTestOutput = ""
                        snippetTestStatus = ""
                    }
                    .buttonStyle(HomeButtonStyle(.secondary))
                    if !snippetTestStatus.isEmpty {
                        Text(snippetTestStatus)
                            .font(.caption)
                            .foregroundStyle(snippetTestStatus.hasPrefix("Matched") ? HomePalette.ink : HomePalette.muted)
                    }
                }
                if !snippetTestOutput.isEmpty {
                    Text(snippetTestOutput)
                        .font(.system(size: 14))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HomePalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HomePalette.line, lineWidth: 1))
                }
            }

            HomeCard("Snippets") {
                HStack(spacing: 8) {
                    HomeInputField("Search snippets", text: $snippetSearch)
                    Button("Import") { importSnippetsJSON() }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                    Button("Export") { exportSnippetsJSON() }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                        .disabled(snippetStore.snippets.isEmpty)
                    Button("Clear") { snippetStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger, size: .small))
                        .disabled(snippetStore.snippets.isEmpty)
                }

                if filteredSnippets().isEmpty {
                    emptyState(
                        icon: "scissors",
                        title: "No snippets yet",
                        message: "Add short voice shortcuts for emails, templates, prompts, links or recurring phrases."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(filteredSnippets()) { snippet in
                            HStack(alignment: .top, spacing: 18) {
                                VStack(alignment: .leading, spacing: 9) {
                                    FlowLayout(spacing: 6) {
                                        ForEach(snippet.allTriggers, id: \.self) { trigger in
                                            Text(trigger)
                                                .font(.system(size: 12, weight: .semibold))
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 9)
                                                .background(HomePalette.sand, in: Capsule())
                                        }
                                    }
                                    Text(snippet.replacement)
                                        .font(.system(size: 13))
                                        .lineLimit(3)
                                        .foregroundStyle(HomePalette.muted)
                                }
                                Spacer()
                                HStack(spacing: 7) {
                                    Button("Edit") { beginEditing(snippet) }
                                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(snippet.replacement, forType: .string)
                                    }
                                    .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    Button("Delete") { snippetStore.delete(snippet) }
                                        .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                                }
                            }
                            .padding(.vertical, 13)
                            if snippet.id != filteredSnippets().last?.id {
                                Divider().overlay(HomePalette.line)
                            }
                        }
                    }
                }
            }
        }
    }

    private func exportSnippetsJSON() {
        let panel = NSSavePanel()
        panel.title = "Export snippets"
        panel.nameFieldStringValue = "pastevox-snippets.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try JSONEncoder.prettyPrinted.encode(snippetStore.portableSnippets())
            try data.write(to: url)
            newSnippetStatus = "Exported."
        } catch {
            newSnippetStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importSnippetsJSON() {
        let panel = NSOpenPanel()
        panel.title = "Import snippets"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let snippets = try JSONDecoder().decode([PortableSnippet].self, from: data)
            let count = snippetStore.importPortableSnippets(snippets)
            newSnippetStatus = "Imported \(count)."
        } catch {
            newSnippetStatus = "Import failed: \(error.localizedDescription)"
        }
    }

    private func filteredSnippets() -> [VoiceSnippet] {
        let query = snippetSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return snippetStore.snippets }
        return snippetStore.snippets.filter { snippet in
            snippet.replacement.lowercased().contains(query)
            || snippet.allTriggers.contains { $0.lowercased().contains(query) }
        }
    }

    private func testSnippetInput() {
        testSnippetText(snippetTestInput)
    }

    private func testSnippetText(_ text: String) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            snippetTestStatus = "Enter a phrase."
            snippetTestOutput = ""
            return
        }
        if let match = snippetStore.match(for: input) {
            snippetTestStatus = "Matched “\(match.matchedTrigger)” · \(match.reason) · \(String(format: "%.2f", match.confidence))"
            snippetTestOutput = match.outputText
        } else {
            snippetTestStatus = "No snippet matched."
            snippetTestOutput = input
        }
    }

    private func startSnippetTestRecording() async {
        isSnippetTestBusy = true
        snippetTestStatus = "Recording test phrase…"
        snippetTestOutput = ""
        defer { isSnippetTestBusy = false }
        do {
            try await audioRecorder.startRecording()
            FloatingHUDController.shared.show(.listening)
        } catch {
            snippetTestStatus = error.localizedDescription
            FloatingHUDController.shared.show(.error)
        }
    }

    private func stopAndTestSnippetRecording() async {
        isSnippetTestBusy = true
        snippetTestStatus = "Transcribing test phrase…"
        defer { isSnippetTestBusy = false }
        do {
            guard let url = try audioRecorder.stopRecording() else {
                snippetTestStatus = "No recording available."
                FloatingHUDController.shared.show(.modeChanged, message: "No recording")
                return
            }
            FloatingHUDController.shared.show(.transcribing)
            let context = TranscriptionContext(promptMode: AppSettings.shared.promptMode, model: AppSettings.shared.sttModel.rawValue)
            let result = try await transcriber.transcribe(audioURL: url, context: context)
            snippetTestInput = result.text
            testSnippetText(result.text)
            audioRecorder.deleteLastRecordingIfNeeded(keepForDebugging: AppSettings.shared.keepLastAudioForDebugging)
            FloatingHUDController.shared.show(.pasted, message: "Tested")
        } catch {
            snippetTestStatus = error.localizedDescription
            FloatingHUDController.shared.show(.error)
        }
    }

    private func generateSnippetVariants() {
        let variants = newSnippetTriggers.flatMap { RussianSnippetVariantGenerator.variants(for: $0) }
        var seen: Set<String> = []
        newSnippetTriggers = variants.filter { value in
            let key = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func saveSnippet() {
        if let editingSnippetID, let snippet = snippetStore.snippets.first(where: { $0.id == editingSnippetID }) {
            updateSnippet(snippet)
        } else {
            addSnippet()
        }
    }

    private func beginEditing(_ snippet: VoiceSnippet) {
        editingSnippetID = snippet.id
        newSnippetTriggers = snippet.allTriggers.isEmpty ? [""] : snippet.allTriggers
        newSnippetReplacement = snippet.replacement
        newSnippetStatus = "Editing snippet."
    }

    private func updateSnippet(_ snippet: VoiceSnippet) {
        let triggers = newSnippetTriggers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let replacement = newSnippetReplacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateSnippet(triggers: triggers, replacement: replacement, excluding: snippet.id) else { return }

        snippetStore.update(snippet, triggers: triggers, replacement: replacement)
        resetSnippetForm(status: "Saved.")
    }

    private func validateSnippet(triggers: [String], replacement: String, excluding snippetID: UUID?) -> Bool {
        guard !triggers.isEmpty else {
            newSnippetStatus = "Trigger is empty."
            return false
        }
        guard !replacement.isEmpty else {
            newSnippetStatus = "Replacement is empty."
            return false
        }

        let normalizedTriggers = Set(triggers.map(normalizeConflictKey))
        let duplicateSnippet = snippetStore.snippets.first { snippet in
            snippet.id != snippetID && !Set(snippet.allTriggers.map(normalizeConflictKey)).isDisjoint(with: normalizedTriggers)
        }
        if let duplicateSnippet {
            newSnippetStatus = "Trigger already used by snippet “\(duplicateSnippet.trigger)”."
            return false
        }

        if let conflictingTerm = dictionaryStore.terms.first(where: { normalizedTriggers.contains(normalizeConflictKey($0.text)) }) {
            newSnippetStatus = "Trigger conflicts with dictionary term “\(conflictingTerm.text)”."
            return false
        }

        return true
    }

    private func normalizeConflictKey(_ value: String) -> String {
        value.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func resetSnippetForm(status: String = "") {
        editingSnippetID = nil
        newSnippetTriggers = [""]
        newSnippetReplacement = ""
        newSnippetStatus = status
    }

    private func addSnippet() {
        let triggers = newSnippetTriggers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let replacement = newSnippetReplacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateSnippet(triggers: triggers, replacement: replacement, excluding: nil) else { return }

        snippetStore.add(trigger: triggers[0], triggers: triggers, replacement: replacement)
        resetSnippetForm(status: "Added.")
    }

    private func placeholderSection(title: String, message: String) -> some View {
        HomeCard(title) {
            Text(message)
                .foregroundStyle(.secondary)
                .padding(.vertical, 20)
        }
    }

    private var scratchpadSection: some View {
        VStack(spacing: 14) {
            HomeCard(editingScratchpadID == nil ? "New note" : "Edit note") {
                VStack(spacing: 14) {
                    Text("Capture longer thoughts without auto-pasting. Save, copy or paste later.")
                        .font(.system(size: 14))
                        .foregroundStyle(HomePalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 13, weight: .semibold))
                        HomeInputField("Optional title", text: $scratchpadTitle)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.system(size: 13, weight: .semibold))
                        TextEditor(text: $scratchpadText)
                            .homeTextEditor(height: 190)
                        if scratchpadText.isEmpty {
                            Text("Type or paste a note here. Voice dictation-to-scratchpad comes next.")
                                .font(.system(size: 12))
                                .foregroundStyle(HomePalette.muted)
                        }
                    }

                    Divider().overlay(HomePalette.line)

                    HStack(spacing: 10) {
                        Text(scratchpadStatus.isEmpty ? "Scratchpad saves drafts locally." : scratchpadStatus)
                            .font(.system(size: 12))
                            .foregroundStyle(scratchpadStatus.isEmpty ? HomePalette.muted : (scratchpadStatus.hasPrefix("Saved") || scratchpadStatus.hasPrefix("Updated") ? HomePalette.ink : HomePalette.terracotta))
                        Spacer()
                        if editingScratchpadID != nil {
                            Button("Cancel") { resetScratchpadForm() }
                                .buttonStyle(HomeButtonStyle(.secondary))
                        }
                        Button("Clear") { resetScratchpadForm() }
                            .buttonStyle(HomeButtonStyle(.secondary))
                        Button("Clear Notes") { scratchpadStore.clear() }
                            .buttonStyle(HomeButtonStyle(.danger))
                            .disabled(scratchpadStore.notes.isEmpty)
                        Button(editingScratchpadID == nil ? "Save Note" : "Update Note") { saveScratchpadNote() }
                            .buttonStyle(HomeButtonStyle(.primary, size: .large))
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }

            HomeCard("Notes") {
                if scratchpadStore.notes.isEmpty {
                    emptyState(
                        icon: "note.text",
                        title: "No scratchpad notes yet",
                        message: "Use this space for longer thoughts you do not want to paste immediately."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(scratchpadStore.notes) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title)
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("Updated \(shortTime(note.updatedAt))")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Edit") { beginEditing(note) }
                                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    Button("Copy") { scratchpadStore.copy(note) }
                                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    Button("Paste") {
                                        Task {
                                            do {
                                                try await ClipboardPasteService.shared.pasteText(note.text)
                                            } catch {
                                                scratchpadStore.copy(note)
                                            }
                                        }
                                    }
                                    .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                    Button("Delete") { scratchpadStore.delete(note) }
                                        .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                                }
                                Text(note.text)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(.vertical, 12)
                            if note.id != scratchpadStore.notes.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func saveScratchpadNote() {
        let text = scratchpadText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            scratchpadStatus = "Note is empty."
            return
        }
        if let editingScratchpadID, let note = scratchpadStore.notes.first(where: { $0.id == editingScratchpadID }) {
            scratchpadStore.update(note, title: scratchpadTitle, text: text)
            resetScratchpadForm(status: "Updated.")
        } else {
            scratchpadStore.add(text: text, title: scratchpadTitle)
            resetScratchpadForm(status: "Saved.")
        }
    }

    private func beginEditing(_ note: ScratchpadNote) {
        editingScratchpadID = note.id
        scratchpadTitle = note.title
        scratchpadText = note.text
        scratchpadStatus = "Editing note."
    }

    private func resetScratchpadForm(status: String = "") {
        editingScratchpadID = nil
        scratchpadTitle = ""
        scratchpadText = ""
        scratchpadStatus = status
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var recentDictations: some View {
        HomeCard("Recent") {
            if historyStore.entries.isEmpty {
                emptyState(
                    icon: "waveform",
                    title: "No dictations yet",
                    message: "Hold Fn/Globe to record your first voice prompt."
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(historyGroups(), id: \.title) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.9)
                                .padding(.horizontal, 2)
                            VStack(spacing: 0) {
                                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                    historyRow(entry)
                                    if index < group.entries.count - 1 {
                                        Divider().padding(.leading, 82)
                                    }
                                }
                            }
                            .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(HomePalette.line, lineWidth: 1))
                        }
                    }
                }
                HStack {
                    Button("Clear History") { historyStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger))
                    if !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(HomePalette.ink)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func historyRow(_ entry: DictationHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(shortTime(entry.createdAt))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 76, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top) {
                        Text(entry.output.isEmpty ? entry.statusMessage : entry.output)
                            .lineLimit(2)
                            .font(.system(size: 14))
                        Spacer()
                        Text(entry.status.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(historyStatusColor(entry.status))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(historyStatusColor(entry.status).opacity(0.10), in: Capsule())
                    }

                    HStack(spacing: 8) {
                        Text(entry.promptMode.shortTitle)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(HomePalette.sand, in: Capsule())
                        if let target = entry.target {
                            Text("→ \(target.displayName)")
                                .lineLimit(1)
                        }
                        if let durationMs = entry.durationMs {
                            Text("\(durationMs)ms")
                        }
                        Spacer()
                        Button("Copy") {
                            historyStore.copy(entry)
                            status = "Copied."
                        }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                        .disabled(entry.output.isEmpty)
                        Button("Paste") {
                            Task {
                                do {
                                    try await ClipboardPasteService.shared.pasteText(entry.output)
                                    status = "Pasted."
                                } catch {
                                    historyStore.copy(entry)
                                    status = "Paste failed; copied."
                                }
                            }
                        }
                        .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                        .disabled(entry.output.isEmpty)
                        Button("Delete") { historyStore.delete(entry) }
                            .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }

    private func subtitle(for section: HomeSection) -> String {
        switch section {
        case .history: "Recent voice prompts, paste targets and quick recovery."
        case .dictionary: "Personal vocabulary for names, terms and spellings."
        case .snippets: "Reusable voice shortcuts."
        case .scratchpad: "Dictate notes without pasting immediately."
        }
    }

    private func historyGroups() -> [(title: String, entries: [DictationHistoryEntry])] {
        let entries = Array(historyStore.entries.prefix(30))
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.createdAt)
        }
        return grouped.keys.sorted(by: >).map { day in
            (title: dayTitle(day), entries: grouped[day] ?? [])
        }
    }

    private func dayTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func statusColor(_ message: String) -> Color {
        message.hasPrefix("Added") || message.hasPrefix("Saved") || message.hasPrefix("Imported") || message.hasPrefix("Exported") ? HomePalette.successText : HomePalette.terracotta
    }

    private func historyStatusColor(_ status: DictationHistoryStatus) -> Color {
        switch status {
        case .pasted: HomePalette.successText
        case .copied: HomePalette.ink.opacity(0.72)
        case .ignored: HomePalette.muted
        case .error: HomePalette.terracotta
        }
    }
}

private enum HomePalette {
    static let background = Color(red: 0.96, green: 0.96, blue: 0.95)
    static let surface = Color.white
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.94)
    static let ink = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let inkPressed = Color(red: 0.16, green: 0.16, blue: 0.16)
    static let muted = Color(red: 0.40, green: 0.40, blue: 0.40)
    static let faint = Color(red: 0.65, green: 0.65, blue: 0.65)
    static let line = Color.black.opacity(0.10)
    static let lineStrong = Color.black.opacity(0.18)
    static let sand = Color(red: 0.91, green: 0.91, blue: 0.90)
    static let sandPressed = Color(red: 0.86, green: 0.86, blue: 0.84)
    static let terracotta = Color(red: 0.18, green: 0.18, blue: 0.18)
    static let terracottaFill = Color(red: 0.93, green: 0.93, blue: 0.92)
    static let terracottaPressed = Color(red: 0.86, green: 0.86, blue: 0.84)
    static let successFill = Color(red: 0.91, green: 0.91, blue: 0.89)
    static let successText = Color(red: 0.20, green: 0.20, blue: 0.20)
}

private enum HomeButtonKind {
    case primary
    case secondary
    case ghost
    case danger
}

private enum HomeButtonSize {
    case tiny
    case small
    case regular
    case large

    var height: CGFloat {
        switch self {
        case .tiny: 24
        case .small: 28
        case .regular: 34
        case .large: 38
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .tiny: 7
        case .small: 9
        case .regular: 13
        case .large: 16
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .tiny: 11
        case .small: 11.5
        case .regular: 12.5
        case .large: 13
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .tiny: 8
        case .small: 9
        case .regular: 11
        case .large: 12
        }
    }
}

private struct HomeButtonStyle: ButtonStyle {
    private let kind: HomeButtonKind
    private let size: HomeButtonSize

    init(_ kind: HomeButtonKind = .secondary, size: HomeButtonSize = .regular) {
        self.kind = kind
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background(backgroundColor(configuration.isPressed), in: RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(borderColor, lineWidth: kind == .primary ? 0 : 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary: .white
        case .secondary: HomePalette.ink
        case .ghost: HomePalette.muted
        case .danger: HomePalette.terracotta
        }
    }

    private func backgroundColor(_ isPressed: Bool) -> Color {
        switch kind {
        case .primary: isPressed ? HomePalette.inkPressed : HomePalette.ink
        case .secondary: isPressed ? HomePalette.sandPressed : HomePalette.sand
        case .ghost: Color.clear
        case .danger: isPressed ? HomePalette.terracottaPressed : HomePalette.terracottaFill
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary: .clear
        case .secondary: HomePalette.ink.opacity(0.08)
        case .ghost: HomePalette.line
        case .danger: HomePalette.terracotta.opacity(0.16)
        }
    }
}

private struct HomeCard<Content: View>: View {
    private let title: String
    private let isSoft: Bool
    private let content: Content

    init(_ title: String, isSoft: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isSoft = isSoft
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HomePalette.muted)
                .tracking(0.8)
            content
        }
        .padding(20)
        .frame(maxWidth: 820, alignment: .leading)
        .background(isSoft ? HomePalette.surfaceSecondary : HomePalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(HomePalette.line, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 4)
    }
}

private struct HomeInputField: View {
    private let placeholder: String
    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        HomeNativeTextField(placeholder: placeholder, text: $text)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HomePalette.line, lineWidth: 1))
    }
}

private struct HomeNativeTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.delegate = context.coordinator
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        field.textColor = NSColor(calibratedWhite: 0.06, alpha: 1)
        field.placeholderAttributedString = placeholderString(placeholder)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
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
                .font: NSFont.systemFont(ofSize: 15, weight: .regular)
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

private struct HomeTextEditorModifier: ViewModifier {
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .regular))
            .scrollContentBackground(.hidden)
            .frame(height: height)
            .padding(10)
            .background(HomePalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HomePalette.line, lineWidth: 1))
    }
}

private extension View {
    func homeTextEditor(height: CGFloat) -> some View {
        modifier(HomeTextEditorModifier(height: height))
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 600
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
