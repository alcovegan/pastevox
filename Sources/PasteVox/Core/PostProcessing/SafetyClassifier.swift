import Foundation

enum SafetyClassifier {
    static func isRiskyTerminalCommandOutput(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("RISKY_COMMAND_PREVIEW") { return true }
        return containsRiskyShellPattern(trimmed)
    }

    private static func containsRiskyShellPattern(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")

        let riskyRegexes = [
            #"(^|[;&|]\s*)sudo\s+"#,
            #"(^|[;&|]\s*)rm\s+(-[a-z]*[rf][a-z]*|-\S*\s+-\S*)\s+"#,
            #"(^|[;&|]\s*)rm\s+.*(/|~|\.\.|\*)"#,
            #"(^|[;&|]\s*)rmdir\s+"#,
            #"(^|[;&|]\s*)mv\s+.*\s+/(bin|etc|usr|var|system|library|applications)"#,
            #"(^|[;&|]\s*)chmod\s+(-r\s+)?(777|666|\+x)"#,
            #"(^|[;&|]\s*)chown\s+(-r\s+)?"#,
            #"(^|[;&|]\s*)dd\s+.*\bof="#,
            #"mkfs\.|diskutil\s+(erase|partition|format|unmount|eject)"#,
            #"docker\s+(system\s+prune|volume\s+(rm|prune)|container\s+prune|image\s+prune)"#,
            #"kubectl\s+delete\s+"#,
            #"terraform\s+(destroy|apply)"#,
            #"git\s+push\s+.*(--force|-f)"#,
            #"git\s+reset\s+--hard"#,
            #"curl\s+.*\|\s*(sh|bash|zsh)"#,
            #"wget\s+.*\|\s*(sh|bash|zsh)"#,
            #">\s*/(etc|bin|usr|var|system|library)"#,
            #"\b(shutdown|reboot|halt)\b"#
        ]

        return riskyRegexes.contains { pattern in
            normalized.range(of: pattern, options: .regularExpression) != nil
        }
    }

    static func riskyPreview(command: String) -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines: [String]

        if trimmed.hasPrefix("RISKY_COMMAND_PREVIEW") {
            lines = trimmed.components(separatedBy: .newlines)
        } else {
            lines = [
                "RISKY_COMMAND_PREVIEW",
                trimmed,
                "Local safety classifier blocked auto-paste because the command may be destructive or modify system/remote state."
            ]
        }

        return lines
            .map { line in
                let content = line.trimmingCharacters(in: .whitespacesAndNewlines)
                return content.isEmpty ? "#" : "# \(content)"
            }
            .joined(separator: "\n")
    }
}
