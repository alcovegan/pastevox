import AppKit
import SwiftUI

@MainActor
final class HomeWindowController {
    static let shared = HomeWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if let window {
            ensureWindowIsVisible(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: HomeView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "VoiceDock"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setFrame(defaultFrame(), display: false)
        window.minSize = NSSize(width: 920, height: 640)

        self.window = window
        ensureWindowIsVisible(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func defaultFrame() -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(CGFloat(1120), visibleFrame.width - 80)
        let height = min(CGFloat(780), visibleFrame.height - 80)
        return NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )
    }

    private func ensureWindowIsVisible(_ window: NSWindow) {
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var frame = window.frame

        if frame.width > visibleFrame.width - 40 { frame.size.width = visibleFrame.width - 40 }
        if frame.height > visibleFrame.height - 40 { frame.size.height = visibleFrame.height - 40 }
        if frame.maxX > visibleFrame.maxX - 20 { frame.origin.x = visibleFrame.maxX - frame.width - 20 }
        if frame.minX < visibleFrame.minX + 20 { frame.origin.x = visibleFrame.minX + 20 }
        if frame.maxY > visibleFrame.maxY - 20 { frame.origin.y = visibleFrame.maxY - frame.height - 20 }
        if frame.minY < visibleFrame.minY + 20 { frame.origin.y = visibleFrame.minY + 20 }

        window.setFrame(frame, display: true)
    }
}
