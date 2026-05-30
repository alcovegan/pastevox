import SwiftUI

@main
struct VoiceDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settings: AppSettings.shared,
                hudController: FloatingHUDController.shared
            )
        }
    }
}
