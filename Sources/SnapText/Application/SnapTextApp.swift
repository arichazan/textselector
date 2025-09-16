import SwiftUI

@main
struct SnapTextApp: App {
    @NSApplicationDelegateAdaptor(SnapTextAppDelegate.self) private var appDelegate
    @StateObject private var settings = UserSettings.shared

    var body: some Scene {
        Settings {
            PreferencesView(viewModel: PreferencesViewModel(settings: settings))
                .frame(width: 420, height: 320)
        }
    }
}
