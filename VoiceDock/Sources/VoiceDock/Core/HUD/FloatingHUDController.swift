import AppKit
import SwiftUI

enum HUDState: String, CaseIterable, Identifiable {
    case hidden
    case listening
    case transcribing
    case pasted
    case error
    case modeChanged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hidden: "Ready"
        case .listening: "Listening"
        case .transcribing: "Transcribing"
        case .pasted: "Pasted"
        case .error: "Error"
        case .modeChanged: "Mode"
        }
    }

    var systemImage: String {
        switch self {
        case .hidden: "mic.fill"
        case .listening: "waveform"
        case .transcribing: "sparkles"
        case .pasted: "checkmark"
        case .error: "exclamationmark"
        case .modeChanged: "switch.2"
        }
    }
}

@MainActor
final class FloatingHUDController: ObservableObject {
    static let shared = FloatingHUDController()

    @Published var state: HUDState = .hidden
    @Published var message: String = "Ready"

    private let panelSize = NSSize(width: 420, height: 72)
    private var panel: NSPanel?
    private var autoCollapseTask: Task<Void, Never>?

    private init() {}

    func configureIfNeeded() {
        guard panel == nil else { return }

        let view = FloatingHUDView(controller: self)
        let hostingController = NSHostingController(rootView: view)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hostingController
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true

        self.panel = panel
        position(panel)
        panel.orderFrontRegardless()
    }

    func show(_ newState: HUDState) {
        show(newState, message: newState.title)
    }

    func show(_ newState: HUDState, message customMessage: String) {
        configureIfNeeded()
        state = newState
        message = customMessage

        autoCollapseTask?.cancel()
        if newState == .pasted || newState == .modeChanged {
            autoCollapseTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 900_000_000)
                await MainActor.run {
                    guard self?.state == .pasted || self?.state == .modeChanged else { return }
                    self?.hide()
                }
            }
        } else if newState == .error {
            autoCollapseTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                await MainActor.run {
                    guard self?.state == .error else { return }
                    self?.hide()
                }
            }
        }

        if let panel {
            position(panel)
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        show(.hidden)
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = screen.midX - panelSize.width / 2
        let y = screen.minY + 2
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: panelSize), display: true, animate: false)
    }
}
