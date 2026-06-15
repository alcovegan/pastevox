import Foundation

struct AppAwareModeResolver {
    @MainActor
    static func mode(for target: PasteTarget?) -> PromptMode? {
        guard AppSettings.shared.appAwareModeSwitchingEnabled, let target else { return nil }
        let haystack = [target.bundleIdentifier, target.appName]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if containsAny(haystack, ["iterm", "terminal", "warp", "alacritty", "kitty", "hyper"]) {
            return .terminalCommand
        }

        if containsAny(haystack, ["cursor", "visual studio code", "vscode", "xcode", "zed", "sublime", "jetbrains", "intellij", "pycharm", "webstorm", "claude"]) {
            return .agentPrompt
        }

        if containsAny(haystack, ["mail", "messages", "telegram", "slack", "discord", "whatsapp", "signal", "notion", "notes"]) {
            return .rawDictation
        }

        return nil
    }

    static func explanation(for target: PasteTarget?, resolvedMode: PromptMode?) -> String? {
        guard let resolvedMode, let target else { return nil }
        return "App-aware mode: \(target.appName) → \(resolvedMode.shortTitle)"
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
