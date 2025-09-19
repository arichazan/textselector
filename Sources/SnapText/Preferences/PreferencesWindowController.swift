import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private let settings: UserSettings

    init(settings: UserSettings) {
        self.settings = settings

        let preferencesView = PreferencesView(viewModel: PreferencesViewModel(settings: settings))
        let hostingView = NSHostingView(rootView: preferencesView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        let title = localizedString("preferences.title", comment: "Preferences window title")
        window.title = title
        window.contentView = hostingView
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.isReleasedWhenClosed = false

        // Note: AppDelegate handles cleanup via its own notification observer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}