import AppKit
import Foundation

protocol PasteService {
    func pasteText(_ text: String) async throws
}

@MainActor
final class ClipboardPasteService: PasteService {
    static let shared = ClipboardPasteService()

    private let pasteboard: NSPasteboard
    private let keyboardEventSender: KeyboardEventSender

    init(
        pasteboard: NSPasteboard = .general,
        keyboardEventSender: KeyboardEventSender = .shared
    ) {
        self.pasteboard = pasteboard
        self.keyboardEventSender = keyboardEventSender
    }

    func pasteText(_ text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PasteError.emptyText
        }

        let backup = ClipboardBackup.capture(from: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        do {
            try keyboardEventSender.sendCommandV()
            try await Task.sleep(nanoseconds: 450_000_000)
            backup.restore(to: pasteboard)
        } catch {
            // Fallback: leave text in clipboard so the user can paste manually.
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            throw error
        }
    }

    func copyOnly(_ text: String) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PasteError.emptyText
        }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

enum PasteError: LocalizedError {
    case emptyText
    case accessibilityPermissionMissing
    case couldNotCreateKeyboardEvent

    var errorDescription: String? {
        switch self {
        case .emptyText:
            "Paste text is empty."
        case .accessibilityPermissionMissing:
            "Accessibility permission is missing. Enable it in System Settings → Privacy & Security → Accessibility. Text was copied to clipboard for manual paste."
        case .couldNotCreateKeyboardEvent:
            "Could not create keyboard paste event. Text was copied to clipboard for manual paste."
        }
    }
}
