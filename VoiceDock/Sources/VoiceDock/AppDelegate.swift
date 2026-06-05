import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()
        LocalLogger.shared.info("PasteVox 0.0.10 started mode=\(AppSettings.shared.promptMode.rawValue) transcription_mode=\(AppSettings.shared.transcriptionMode.rawValue) stt_model=\(AppSettings.shared.sttModel.rawValue) paste_auto=\(AppSettings.shared.pasteAutomatically) postprocess=\(AppSettings.shared.postProcessingEnabled) mic=\(PermissionsManager.shared.microphonePermissionDescription().replacingOccurrences(of: " ", with: "_")) accessibility_trusted=\(PermissionsManager.shared.isAccessibilityTrusted(prompt: false))")
        FloatingHUDController.shared.configureIfNeeded()
        configureStatusItem()
        HotkeyManager.shared.start()
        scheduleHotkeyMonitorWarmupRestart()
        FloatingHUDController.shared.hide()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Task { @MainActor in
            HomeWindowController.shared.show()
        }
        return true
    }

    private func scheduleHotkeyMonitorWarmupRestart() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard HotkeyManager.shared.isRunning, !HotkeyManager.shared.isPressed else { return }
            HotkeyManager.shared.restart()
        }
    }

    @MainActor
    func applyActivationPolicy() {
        NSApp.setActivationPolicy(AppSettings.shared.showInDock ? .regular : .accessory)
    }

    @MainActor
    private func configureStatusItem() {
        let item: NSStatusItem
        if let statusItem {
            item = statusItem
        } else {
            item = NSStatusBar.system.statusItem(withLength: 18)
            statusItem = item
        }
        if
            let iconURL = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
            let image = NSImage(contentsOf: iconURL)
        {
            image.size = NSSize(width: 20, height: 20)
            image.isTemplate = true
            item.button?.image = image
        } else {
            item.button?.title = "🎙"
        }
        item.button?.toolTip = "PasteVox"

        let menu = NSMenu()

        let modeMenu = NSMenu()
        for mode in PromptMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(selectPromptMode(_:)), keyEquivalent: "")
            item.representedObject = mode.rawValue
            item.state = AppSettings.shared.promptMode == mode ? .on : .off
            modeMenu.addItem(item)
        }
        let modeRoot = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        menu.setSubmenu(modeMenu, for: modeRoot)
        menu.addItem(modeRoot)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Copy Last Result",
            action: #selector(copyLastResult),
            keyEquivalent: "c"
        ))
        menu.addItem(NSMenuItem(
            title: "Paste Last Result",
            action: #selector(pasteLastResult),
            keyEquivalent: "v"
        ))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Open Home…",
            action: #selector(openHome),
            keyEquivalent: "h"
        ))
        menu.addItem(NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        let hudMenu = NSMenu()
        for state in [HUDState.listening, .transcribing, .pasted, .error] {
            let item = NSMenuItem(
                title: state.title,
                action: #selector(showHUDState(_:)),
                keyEquivalent: ""
            )
            item.representedObject = state.rawValue
            hudMenu.addItem(item)
        }
        hudMenu.addItem(NSMenuItem.separator())
        hudMenu.addItem(NSMenuItem(
            title: "Hide",
            action: #selector(hideHUD),
            keyEquivalent: ""
        ))

        let hudRoot = NSMenuItem(title: "Debug HUD", action: nil, keyEquivalent: "")
        menu.setSubmenu(hudMenu, for: hudRoot)
        menu.addItem(hudRoot)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit PasteVox",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        item.menu = menu
    }

    @objc private func selectPromptMode(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let mode = PromptMode(rawValue: rawValue)
        else { return }

        Task { @MainActor in
            AppSettings.shared.promptMode = mode
            configureStatusItem()
        }
    }

    @objc private func copyLastResult() {
        Task { @MainActor in
            HotkeyManager.shared.copyLastResult()
        }
    }

    @objc private func pasteLastResult() {
        Task { @MainActor in
            await HotkeyManager.shared.pasteLastResult()
        }
    }

    @objc private func openHome() {
        Task { @MainActor in
            HomeWindowController.shared.show()
        }
    }

    @objc private func openSettings() {
        Task { @MainActor in
            SettingsWindowController.shared.show(
                settings: AppSettings.shared,
                hudController: FloatingHUDController.shared
            )
        }
    }

    @objc private func showHUDState(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let state = HUDState(rawValue: rawValue)
        else { return }

        Task { @MainActor in
            FloatingHUDController.shared.show(state)
        }
    }

    @objc private func hideHUD() {
        Task { @MainActor in
            FloatingHUDController.shared.hide()
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
