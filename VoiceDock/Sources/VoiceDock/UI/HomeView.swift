import AppKit
import SwiftUI

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
                .padding(.horizontal, 34)
                .padding(.vertical, 30)
                .frame(maxWidth: 900, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .background(homeBackground)
        }
        .frame(minWidth: 980, idealWidth: 1120, minHeight: 700, idealHeight: 780)
    }

    private var homeBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor).opacity(0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sidebarBackground: some ShapeStyle {
        Color(nsColor: .controlBackgroundColor).opacity(0.86)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("VoiceDock")
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

            Button("Open Settings…") {
                SettingsWindowController.shared.show(
                    settings: AppSettings.shared,
                    hudController: FloatingHUDController.shared
                )
            }
            .buttonStyle(HomeButtonStyle(.secondary, size: .regular))
        }
        .padding(20)
        .frame(width: 224)
        .background(sidebarBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(selectedSection.rawValue)
                .font(.system(size: 38, weight: .semibold))
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
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .tracking(-0.8)
                Text("dictations")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            HomeCard("Words") {
                Text("\(historyStore.totalWords)")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
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

    private var dictionarySection: some View {
        VStack(spacing: 14) {
            HomeCard("Add term") {
                Text("Dictionary terms are sent as STT context so OpenAI prefers your names, project terms and spellings.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                TextField("Term, name, email, project…", text: $newDictionaryTerm)
                    .textFieldStyle(.roundedBorder)
                TextField("Optional note, e.g. company name or spelling hint", text: $newDictionaryNote)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Add") {
                        dictionaryStore.add(text: newDictionaryTerm, note: newDictionaryNote)
                        newDictionaryTerm = ""
                        newDictionaryNote = ""
                    }
                    .buttonStyle(HomeButtonStyle(.primary))
                    .disabled(newDictionaryTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Clear Dictionary") { dictionaryStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger))
                        .disabled(dictionaryStore.terms.isEmpty)
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
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.text)
                                    if !term.note.isEmpty {
                                        Text(term.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button("Delete") { dictionaryStore.delete(term) }
                                    .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                            }
                            .padding(.vertical, 10)
                            if term.id != dictionaryStore.terms.last?.id {
                                Divider()
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
                Text("Create a voice shortcut: say the trigger phrase alone, VoiceDock inserts the replacement text.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Say any of these phrases")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        ForEach(newSnippetTriggers.indices, id: \.self) { index in
                            HStack {
                                TextField(index == 0 ? "мой имейл" : "вставь мой имейл", text: $newSnippetTriggers[index])
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
                                Button("−") { newSnippetTriggers.remove(at: index) }
                                    .buttonStyle(HomeButtonStyle(.ghost, size: .small))
                                    .disabled(newSnippetTriggers.count == 1)
                            }
                        }
                        HStack {
                            Button("+ Add phrase") { newSnippetTriggers.append("") }
                                .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                            Button("Generate Russian variants") { generateSnippetVariants() }
                                .buttonStyle(HomeButtonStyle(.secondary, size: .small))
                                .disabled(newSnippetTriggers.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                        }
                        .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("2. Insert this text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $newSnippetReplacement)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .frame(height: 120)
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
                    if newSnippetReplacement.isEmpty {
                        Text("Text to insert, e.g. alexey@example.com")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
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
                }
                .font(.system(size: 12))

                HStack {
                    Button(editingSnippetID == nil ? "Add Snippet" : "Save Snippet") { saveSnippet() }
                        .buttonStyle(HomeButtonStyle(.primary))
                        .keyboardShortcut(.defaultAction)
                    if editingSnippetID != nil {
                        Button("Cancel Edit") { resetSnippetForm() }
                            .buttonStyle(HomeButtonStyle(.secondary))
                    }
                    Button("Clear Form") {
                        resetSnippetForm()
                    }
                    .buttonStyle(HomeButtonStyle(.secondary))
                    Button("Clear Snippets") { snippetStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger))
                        .disabled(snippetStore.snippets.isEmpty)
                    if !newSnippetStatus.isEmpty {
                        Text(newSnippetStatus)
                            .font(.caption)
                            .foregroundStyle(newSnippetStatus.hasPrefix("Added") ? .green : .red)
                    }
                }
            }

            HomeCard("Test snippet") {
                Text("Type a transcript or record a test phrase. This never pastes anywhere.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                TextField("вставь мою почту", text: $snippetTestInput)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
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
                            .foregroundStyle(snippetTestStatus.hasPrefix("Matched") ? .green : .secondary)
                    }
                }
                if !snippetTestOutput.isEmpty {
                    Text(snippetTestOutput)
                        .font(.system(size: 14))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            HomeCard("Snippets") {
                TextField("Search snippets", text: $snippetSearch)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.14), lineWidth: 1))

                if filteredSnippets().isEmpty {
                    emptyState(
                        icon: "scissors",
                        title: "No snippets yet",
                        message: "Add short voice shortcuts for emails, templates, prompts, links or recurring phrases."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(filteredSnippets()) { snippet in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        FlowLayout(spacing: 6) {
                                            ForEach(snippet.allTriggers, id: \.self) { trigger in
                                                Text(trigger)
                                                    .font(.caption.weight(.medium))
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(Color.accentColor.opacity(0.10), in: Capsule())
                                            }
                                        }
                                    }
                                    Spacer()
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
                                Text(snippet.replacement)
                                    .lineLimit(3)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                            if snippet.id != filteredSnippets().last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
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
        guard !triggers.isEmpty else {
            newSnippetStatus = "Trigger is empty."
            return
        }
        guard !replacement.isEmpty else {
            newSnippetStatus = "Replacement is empty."
            return
        }

        snippetStore.update(snippet, triggers: triggers, replacement: replacement)
        resetSnippetForm(status: "Saved.")
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
        guard !triggers.isEmpty else {
            newSnippetStatus = "Trigger is empty."
            return
        }
        guard !replacement.isEmpty else {
            newSnippetStatus = "Replacement is empty."
            return
        }

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
                Text("Capture longer thoughts without auto-pasting. Save, copy or paste later.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Optional title", text: $scratchpadTitle)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $scratchpadText)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .frame(height: 180)
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
                    if scratchpadText.isEmpty {
                        Text("Type or paste a note here. Voice dictation-to-scratchpad comes next.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Button(editingScratchpadID == nil ? "Save Note" : "Update Note") { saveScratchpadNote() }
                        .buttonStyle(HomeButtonStyle(.primary))
                        .keyboardShortcut(.defaultAction)
                    if editingScratchpadID != nil {
                        Button("Cancel Edit") { resetScratchpadForm() }
                            .buttonStyle(HomeButtonStyle(.secondary))
                    }
                    Button("Clear Form") { resetScratchpadForm() }
                        .buttonStyle(HomeButtonStyle(.secondary))
                    Button("Clear Notes") { scratchpadStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger))
                        .disabled(scratchpadStore.notes.isEmpty)
                    if !scratchpadStatus.isEmpty {
                        Text(scratchpadStatus)
                            .font(.caption)
                            .foregroundStyle(scratchpadStatus.hasPrefix("Saved") || scratchpadStatus.hasPrefix("Updated") ? .green : .red)
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
                            .background(Color.secondary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                HStack {
                    Button("Clear History") { historyStore.clear() }
                        .buttonStyle(HomeButtonStyle(.danger))
                    if !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.green)
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
                            .background(Color.secondary.opacity(0.10), in: Capsule())
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

    private func historyStatusColor(_ status: DictationHistoryStatus) -> Color {
        switch status {
        case .pasted: .green
        case .copied: .blue
        case .ignored: .secondary
        case .error: .red
        }
    }
}

private enum HomeButtonKind {
    case primary
    case secondary
    case ghost
    case danger
}

private enum HomeButtonSize {
    case small
    case regular

    var verticalPadding: CGFloat { self == .small ? 5 : 7 }
    var horizontalPadding: CGFloat { self == .small ? 9 : 12 }
    var fontSize: CGFloat { self == .small ? 12 : 13 }
    var cornerRadius: CGFloat { self == .small ? 8 : 10 }
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
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
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
        case .secondary: .primary
        case .ghost: .secondary
        case .danger: .red
        }
    }

    private func backgroundColor(_ isPressed: Bool) -> Color {
        switch kind {
        case .primary: isPressed ? Color.accentColor.opacity(0.82) : Color.accentColor
        case .secondary: Color.secondary.opacity(isPressed ? 0.16 : 0.09)
        case .ghost: Color.clear
        case .danger: Color.red.opacity(isPressed ? 0.14 : 0.08)
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary: .clear
        case .secondary: Color.secondary.opacity(0.14)
        case .ghost: Color.secondary.opacity(0.12)
        case .danger: Color.red.opacity(0.18)
        }
    }
}

private struct HomeCard<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            content
        }
        .padding(20)
        .frame(maxWidth: 780, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 4)
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
