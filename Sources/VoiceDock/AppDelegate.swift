import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsCancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()
        LocalLogger.shared.info("PasteVox 0.1.0 started mode=\(AppSettings.shared.promptMode.rawValue) transcription_mode=\(AppSettings.shared.transcriptionMode.rawValue) stt_model=\(AppSettings.shared.sttModel.rawValue) paste_auto=\(AppSettings.shared.pasteAutomatically) postprocess=\(AppSettings.shared.postProcessingEnabled) mic=\(PermissionsManager.shared.microphonePermissionDescription().replacingOccurrences(of: " ", with: "_")) accessibility_trusted=\(PermissionsManager.shared.isAccessibilityTrusted(prompt: false))")
        FloatingHUDController.shared.configureIfNeeded()
        configureStatusItem()
        observeSettingsChanges()
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
        let showInDock = AppSettings.shared.showInDock
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
        if showInDock {
            NSApp.activate(ignoringOtherApps: true)
        }

        // macOS sometimes keeps the Dock tile visible until the next run-loop tick
        // when the policy is changed from a visible Settings window. Re-apply once
        // asynchronously so the toggle takes effect without a full app restart.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(policy)
            if showInDock {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        LocalLogger.shared.info("activation_policy_changed show_in_dock=\(showInDock)")
    }

    @MainActor
    private func observeSettingsChanges() {
        let settings = AppSettings.shared
        settings.$showInDock
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.applyActivationPolicy() }
            }
            .store(in: &settingsCancellables)

        settings.$promptMode
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureStatusItem() }
            }
            .store(in: &settingsCancellables)

        settings.$writingStyle
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureStatusItem() }
            }
            .store(in: &settingsCancellables)

        settings.$fnHoldToRecordEnabled
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureStatusItem() }
            }
            .store(in: &settingsCancellables)

        settings.$holdHotkeyKind
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureStatusItem() }
            }
            .store(in: &settingsCancellables)

        settings.$appLanguage
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureStatusItem() }
            }
            .store(in: &settingsCancellables)
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
        let modeRoot = NSMenuItem(title: T("Mode"), action: nil, keyEquivalent: "")
        menu.setSubmenu(modeMenu, for: modeRoot)
        menu.addItem(modeRoot)

        let styleMenu = NSMenu()
        for style in WritingStyle.allCases {
            let item = NSMenuItem(title: styleMenuTitle(for: style), action: #selector(selectWritingStyle(_:)), keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state = AppSettings.shared.writingStyle == style ? .on : .off
            styleMenu.addItem(item)
        }
        let styleRoot = NSMenuItem(title: T("Style"), action: nil, keyEquivalent: "")
        menu.setSubmenu(styleMenu, for: styleRoot)
        menu.addItem(styleRoot)

        let holdKeyMenu = NSMenu()
        for kind in HotkeyKind.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(selectHoldHotkey(_:)), keyEquivalent: "")
            item.representedObject = kind.rawValue
            item.state = AppSettings.shared.holdHotkeyKind == kind ? .on : .off
            holdKeyMenu.addItem(item)
        }
        let holdKeyRoot = NSMenuItem(title: T("Hold Key"), action: nil, keyEquivalent: "")
        menu.setSubmenu(holdKeyMenu, for: holdKeyRoot)
        menu.addItem(holdKeyRoot)

        let fnHoldItem = NSMenuItem(
            title: String(format: T("Hold Recording (%@)"), AppSettings.shared.holdHotkeyKind.shortTitle),
            action: #selector(toggleFnHoldRecording),
            keyEquivalent: ""
        )
        fnHoldItem.state = AppSettings.shared.fnHoldToRecordEnabled ? .on : .off
        menu.addItem(fnHoldItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: T("Copy Last Result"),
            action: #selector(copyLastResult),
            keyEquivalent: "c"
        ))
        menu.addItem(NSMenuItem(
            title: T("Paste Last Result"),
            action: #selector(pasteLastResult),
            keyEquivalent: "v"
        ))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: T("Open Home…"),
            action: #selector(openHome),
            keyEquivalent: "h"
        ))
        menu.addItem(NSMenuItem(
            title: T("Settings"),
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
            title: T("Hide"),
            action: #selector(hideHUD),
            keyEquivalent: ""
        ))

        let hudRoot = NSMenuItem(title: T("Debug HUD"), action: nil, keyEquivalent: "")
        menu.setSubmenu(hudMenu, for: hudRoot)
        menu.addItem(hudRoot)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: T("Quit PasteVox"),
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
            FloatingHUDController.shared.show(.modeChanged, message: String(format: T("Mode: %@"), mode.shortTitle))
        }
    }

    @objc private func selectWritingStyle(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let style = WritingStyle(rawValue: rawValue)
        else { return }

        Task { @MainActor in
            AppSettings.shared.writingStyle = style
            configureStatusItem()
            let mode = AppSettings.shared.promptMode
            let suffix = styleApplies(to: mode, style: style) ? "" : " \(T("inactive"))"
            FloatingHUDController.shared.show(.modeChanged, message: "\(String(format: T("Style: %@"), style.shortTitle))\(suffix)")
        }
    }

    @objc private func selectHoldHotkey(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let kind = HotkeyKind(rawValue: rawValue)
        else { return }

        Task { @MainActor in
            AppSettings.shared.holdHotkeyKind = kind
            configureStatusItem()
            FloatingHUDController.shared.show(.modeChanged, message: String(format: T("Hold: %@"), kind.shortTitle))
            LocalLogger.shared.info("hold_hotkey_changed source=tray kind=\(kind.rawValue)")
        }
    }

    @objc private func toggleFnHoldRecording() {
        Task { @MainActor in
            let isEnabled = !AppSettings.shared.fnHoldToRecordEnabled
            AppSettings.shared.fnHoldToRecordEnabled = isEnabled
            configureStatusItem()
            FloatingHUDController.shared.show(.modeChanged, message: isEnabled ? T("Fn recording on") : T("Fn recording off"))
            LocalLogger.shared.info("fn_hold_to_record_toggled source=tray enabled=\(isEnabled)")
        }
    }

    private func styleMenuTitle(for style: WritingStyle) -> String {
        switch style {
        case .default: "Default — Fn+5"
        case .concise: "Concise — Fn+6"
        case .friendly: "Friendly — Fn+7"
        case .formal: "Formal — Fn+8"
        case .codingAgent: "Coding Agent — Fn+9"
        case .chat: "Chat — Fn+0"
        case .email: "Email — Fn+-"
        }
    }

    @MainActor
    private func styleApplies(to mode: PromptMode, style: WritingStyle) -> Bool {
        let settings = AppSettings.shared
        return style != .default
            && mode != .rawDictation
            && settings.postProcessingEnabled
            && settings.postProcessingEnabledModes.contains(mode)
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
