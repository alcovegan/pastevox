import AppKit
import AVFoundation
import Foundation

final class PermissionsManager {
    static let shared = PermissionsManager()

    private init() {}

    var microphonePermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestMicrophonePermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func accessibilityPermissionDescription() -> String {
        if isAccessibilityTrusted(prompt: false) {
            return "Accessibility permission granted."
        }
        return "Accessibility permission missing. Enable it in System Settings → Privacy & Security → Accessibility."
    }

    func openAccessibilityPrompt() {
        _ = isAccessibilityTrusted(prompt: true)
    }

    func microphonePermissionDescription() -> String {
        switch microphonePermissionStatus {
        case .notDetermined:
            "Microphone permission not requested."
        case .restricted:
            "Microphone permission is restricted."
        case .denied:
            "Microphone permission denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .authorized:
            "Microphone permission granted."
        @unknown default:
            "Unknown microphone permission status."
        }
    }
}
