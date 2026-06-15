import AppKit
import ApplicationServices
import Foundation

struct PasteTarget: Codable, Equatable {
    let appName: String
    let bundleIdentifier: String?
    let processIdentifier: Int32?
    let windowTitle: String?

    @MainActor
    static var current: PasteTarget {
        let app = NSWorkspace.shared.frontmostApplication
        let pid = app?.processIdentifier
        let title = AppSettings.shared.logPasteTargetWindowTitle ? focusedWindowTitle(processIdentifier: pid) : nil
        return PasteTarget(
            appName: app?.localizedName ?? "Unknown app",
            bundleIdentifier: app?.bundleIdentifier,
            processIdentifier: pid,
            windowTitle: title
        )
    }

    var displayName: String {
        if let windowTitle, !windowTitle.isEmpty {
            return "\(appName) — \(windowTitle)"
        }
        return appName
    }

    private static func focusedWindowTitle(processIdentifier pid: pid_t?) -> String? {
        guard let pid else { return nil }
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard focusedResult == .success, let focusedWindow else { return nil }

        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(focusedWindow as! AXUIElement, kAXTitleAttribute as CFString, &titleValue)
        guard titleResult == .success else { return nil }
        return titleValue as? String
    }
}
