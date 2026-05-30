import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func show(settings: AppSettings, hudController: FloatingHUDController) {
        if let window {
            ensureWindowIsVisible(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(settings: settings, hudController: hudController)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "VoiceDock Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setFrame(defaultFrame(), display: false)
        window.minSize = NSSize(width: 820, height: 620)

        self.window = window
        ensureWindowIsVisible(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func defaultFrame() -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(CGFloat(980), visibleFrame.width - 80)
        let height = min(CGFloat(760), visibleFrame.height - 80)
        let x = visibleFrame.midX - width / 2
        let y = visibleFrame.midY - height / 2
        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func ensureWindowIsVisible(_ window: NSWindow) {
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var frame = window.frame

        if frame.width > visibleFrame.width - 40 {
            frame.size.width = visibleFrame.width - 40
        }
        if frame.height > visibleFrame.height - 40 {
            frame.size.height = visibleFrame.height - 40
        }

        if frame.maxX > visibleFrame.maxX - 20 {
            frame.origin.x = visibleFrame.maxX - frame.width - 20
        }
        if frame.minX < visibleFrame.minX + 20 {
            frame.origin.x = visibleFrame.minX + 20
        }
        if frame.maxY > visibleFrame.maxY - 20 {
            frame.origin.y = visibleFrame.maxY - frame.height - 20
        }
        if frame.minY < visibleFrame.minY + 20 {
            frame.origin.y = visibleFrame.minY + 20
        }

        window.setFrame(frame, display: true)
    }
}
