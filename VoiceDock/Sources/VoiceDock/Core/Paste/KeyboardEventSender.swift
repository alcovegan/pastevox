import AppKit
import Foundation

final class KeyboardEventSender {
    static let shared = KeyboardEventSender()

    private init() {}

    func sendCommandV() throws {
        guard PermissionsManager.shared.isAccessibilityTrusted(prompt: false) else {
            throw PasteError.accessibilityPermissionMissing
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyCodeV: CGKeyCode = 9

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
        else {
            throw PasteError.couldNotCreateKeyboardEvent
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
