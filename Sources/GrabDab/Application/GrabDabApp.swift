import SwiftUI

@main
struct GrabDabApp: App {
    @NSApplicationDelegateAdaptor(GrabDabAppDelegate.self) private var appDelegate
    @StateObject private var settings = UserSettings.shared

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)

        Settings {
            PreferencesView(viewModel: PreferencesViewModel(settings: settings))
                .frame(width: 420, height: 320)
        }
    }
}
