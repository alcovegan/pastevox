#!/usr/bin/env swift
import Foundation

let runID = UUID().uuidString
let startedAt = Date()
func log(_ message: String) {
    let formatter = ISO8601DateFormatter()
    print("[\(formatter.string(from: Date()))] run_id=\(runID) \(message)")
}

let dryRun = CommandLine.arguments.contains("--dry-run")
let domain = "com.pastevox.app"
log("startup script=seed-demo-data domain=\(domain) dry_run=\(dryRun)")

struct VoiceSnippet: Codable {
    let id: UUID
    var trigger: String
    var triggers: [String]
    var replacement: String
    let createdAt: Date
}

struct DictionaryTerm: Codable {
    let id: UUID
    var text: String
    var note: String
    let createdAt: Date
}

struct ScratchpadNote: Codable {
    let id: UUID
    var title: String
    var text: String
    let createdAt: Date
    var updatedAt: Date
}

struct PasteTarget: Codable {
    let appName: String
    let bundleIdentifier: String?
    let processIdentifier: Int32?
    let windowTitle: String?
}

struct DictationHistoryEntry: Codable {
    let id: UUID
    let createdAt: Date
    let transcript: String
    let output: String
    let promptMode: String
    let transcriptionMode: String
    let model: String
    let status: String
    let statusMessage: String
    let target: PasteTarget?
    let durationMs: Int?
    let wordCount: Int

    init(
        createdAt: Date,
        transcript: String,
        output: String,
        promptMode: String,
        status: String,
        statusMessage: String,
        target: PasteTarget?,
        durationMs: Int?
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.transcript = transcript
        self.output = output
        self.promptMode = promptMode
        self.transcriptionMode = "fileUploadAfterRelease"
        self.model = "gpt-4o-mini-transcribe"
        self.status = status
        self.statusMessage = statusMessage
        self.target = target
        self.durationMs = durationMs
        self.wordCount = output.split { $0.isWhitespace || $0.isNewline }.count
    }
}

let now = Date()
func minutesAgo(_ minutes: Int) -> Date { now.addingTimeInterval(TimeInterval(-minutes * 60)) }

let snippets: [VoiceSnippet] = [
    VoiceSnippet(
        id: UUID(),
        trigger: "my email",
        triggers: ["my email", "insert my email", "paste my email"],
        replacement: "alex@pastevox.app",
        createdAt: minutesAgo(54)
    ),
    VoiceSnippet(
        id: UUID(),
        trigger: "standup update",
        triggers: ["standup update", "insert standup update", "daily update"],
        replacement: "Yesterday: shipped the PasteVox Home polish. Today: capture screenshots and tighten the landing page. Blockers: none.",
        createdAt: minutesAgo(48)
    ),
    VoiceSnippet(
        id: UUID(),
        trigger: "bug report template",
        triggers: ["bug report template", "insert bug template", "new bug report"],
        replacement: "Summary:\nSteps to reproduce:\nExpected result:\nActual result:\nNotes:",
        createdAt: minutesAgo(38)
    ),
    VoiceSnippet(
        id: UUID(),
        trigger: "ralph prompt",
        triggers: ["ralph prompt", "insert ralph prompt", "ralph template"],
        replacement: "Role:\nGoal:\nContext:\nConstraints:\nPhases:\nAcceptance criteria:\nStop points:",
        createdAt: minutesAgo(25)
    )
]

let terms: [DictionaryTerm] = [
    DictionaryTerm(id: UUID(), text: "PasteVox", note: "app name, one word, capital P and V", createdAt: minutesAgo(80)),
    DictionaryTerm(id: UUID(), text: "RALPH", note: "prompt structure: Role, Goal, Context, Constraints", createdAt: minutesAgo(72)),
    DictionaryTerm(id: UUID(), text: "gpt-4o-mini-transcribe", note: "default OpenAI STT model", createdAt: minutesAgo(61)),
    DictionaryTerm(id: UUID(), text: "AppKit", note: "native macOS framework used for tray, paste and windows", createdAt: minutesAgo(45)),
    DictionaryTerm(id: UUID(), text: "Keychain", note: "secure storage for the OpenAI API key", createdAt: minutesAgo(30))
]

let notes: [ScratchpadNote] = [
    ScratchpadNote(
        id: UUID(),
        title: "Landing page copy",
        text: "Hero idea: Speak. Paste. Keep moving.\n\nMake the landing feel useful and approachable, not elitist or generic AI SaaS. Use real screenshots, colorful accents and a practical setup section.",
        createdAt: minutesAgo(35),
        updatedAt: minutesAgo(8)
    ),
    ScratchpadNote(
        id: UUID(),
        title: "Product demo checklist",
        text: "Screenshots needed:\n- Home / History with demo entries\n- Snippets with a few saved shortcuts\n- Dictionary with product terms\n- Scratchpad with a real note\n- HUD listening overlay",
        createdAt: minutesAgo(66),
        updatedAt: minutesAgo(18)
    ),
    ScratchpadNote(
        id: UUID(),
        title: "Agent prompt draft",
        text: "Turn the rough voice transcript into a clear coding-agent task. Preserve file paths, constraints and acceptance criteria. Do not invent requirements.",
        createdAt: minutesAgo(120),
        updatedAt: minutesAgo(55)
    )
]

let targets = [
    PasteTarget(appName: "Cursor", bundleIdentifier: "com.todesktop.230313mzl4w4u92", processIdentifier: nil, windowTitle: nil),
    PasteTarget(appName: "iTerm2", bundleIdentifier: "com.googlecode.iterm2", processIdentifier: nil, windowTitle: nil),
    PasteTarget(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", processIdentifier: nil, windowTitle: nil),
    PasteTarget(appName: "Mail", bundleIdentifier: "com.apple.mail", processIdentifier: nil, windowTitle: nil),
    PasteTarget(appName: "Sublime Text", bundleIdentifier: "com.sublimetext.4", processIdentifier: nil, windowTitle: nil)
]

let entries: [DictationHistoryEntry] = [
    DictationHistoryEntry(createdAt: minutesAgo(4), transcript: "turn this into a clean coding agent task", output: "Refactor the landing page workspace section to use real PasteVox screenshots instead of CSS placeholders. Keep the layout responsive and preserve the colorful accent system.", promptMode: "agentPrompt", status: "pasted", statusMessage: "Pasted.", target: targets[0], durationMs: 1840),
    DictationHistoryEntry(createdAt: minutesAgo(9), transcript: "insert my email", output: "alex@pastevox.app", promptMode: "rawDictation", status: "pasted", statusMessage: "Snippet expanded and pasted.", target: targets[2], durationMs: 920),
    DictationHistoryEntry(createdAt: minutesAgo(16), transcript: "make this shorter and friendly for slack", output: "Looks good — I’ll clean up the screenshot section and send a tighter version in a few minutes.", promptMode: "agentPrompt", status: "copied", statusMessage: "Copied to clipboard.", target: targets[2], durationMs: 1510),
    DictationHistoryEntry(createdAt: minutesAgo(24), transcript: "list files sorted by size", output: "ls -lhS", promptMode: "terminalCommand", status: "pasted", statusMessage: "Pasted.", target: targets[1], durationMs: 1100),
    DictationHistoryEntry(createdAt: minutesAgo(33), transcript: "create a ralph prompt for onboarding", output: "Role:\nYou are a macOS product engineer.\n\nGoal:\nDesign a PasteVox onboarding checklist for first launch.\n\nContext:\nThe app needs OpenAI key, Microphone and Accessibility permissions.\n\nAcceptance criteria:\nUsers can verify recording and paste in one flow.", promptMode: "ralphPrompt", status: "pasted", statusMessage: "Pasted.", target: targets[0], durationMs: 2260),
    DictationHistoryEntry(createdAt: minutesAgo(48), transcript: "send a quick update email", output: "Hi team,\n\nQuick update: the PasteVox Home redesign is in progress. The main workspace now has cleaner navigation, better input fields and a screenshot-ready neutral UI.\n\nBest,\nAlex", promptMode: "agentPrompt", status: "copied", statusMessage: "Copied to clipboard.", target: targets[3], durationMs: 2040),
    DictationHistoryEntry(createdAt: minutesAgo(64), transcript: "open the project in sublime", output: "subl .", promptMode: "terminalCommand", status: "pasted", statusMessage: "Pasted.", target: targets[1], durationMs: 980),
    DictationHistoryEntry(createdAt: minutesAgo(78), transcript: "bug report template", output: "Summary:\nSteps to reproduce:\nExpected result:\nActual result:\nNotes:", promptMode: "rawDictation", status: "pasted", statusMessage: "Snippet expanded and pasted.", target: targets[4], durationMs: 760),
    DictationHistoryEntry(createdAt: minutesAgo(95), transcript: "too short", output: "Recording too short", promptMode: "rawDictation", status: "ignored", statusMessage: "Recording too short.", target: targets[1], durationMs: nil),
    DictationHistoryEntry(createdAt: minutesAgo(115), transcript: "remove all build artifacts", output: "# RISKY_COMMAND_PREVIEW\n# rm -rf .build dist\n# This can delete generated artifacts. Review before running.", promptMode: "terminalCommand", status: "copied", statusMessage: "Risky command copied as commented preview.", target: targets[1], durationMs: 1320)
]

let defaults = UserDefaults(suiteName: domain) ?? .standard
let encoder = JSONEncoder()
let values: [(String, Data)] = [
    ("voiceSnippets", try encoder.encode(snippets)),
    ("dictionaryTerms", try encoder.encode(terms)),
    ("scratchpadNotes", try encoder.encode(notes)),
    ("dictationHistoryEntries", try encoder.encode(entries))
]

for (key, data) in values {
    if dryRun {
        log("dry_run key=\(key) bytes=\(data.count)")
    } else {
        defaults.set(data, forKey: key)
        log("wrote key=\(key) bytes=\(data.count)")
    }
}

if !dryRun {
    defaults.synchronize()
}

let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
log("summary status=success duration_ms=\(durationMs) snippets=\(snippets.count) terms=\(terms.count) notes=\(notes.count) history_entries=\(entries.count)")
