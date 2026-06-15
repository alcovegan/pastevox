import Foundation

enum PromptMode: String, CaseIterable, Identifiable, Codable {
    case rawDictation
    case agentPrompt
    case ralphPrompt
    case terminalCommand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rawDictation: "Raw Dictation"
        case .agentPrompt: "Agent Prompt"
        case .ralphPrompt: "RALPH Prompt"
        case .terminalCommand: "Terminal Command"
        }
    }

    var shortTitle: String {
        switch self {
        case .rawDictation: "Raw"
        case .agentPrompt: "Agent"
        case .ralphPrompt: "RALPH"
        case .terminalCommand: "Command"
        }
    }
}
