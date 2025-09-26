import AppKit

final class StatusItemController {
    var onCaptureRequested: (() -> Void)?
    var onPreferencesRequested: (() -> Void)?
    var onQuitRequested: (() -> Void)?

    private let statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            let accessibilityDesc = localizedString("accessibility.statusItem", comment: "Status item accessibility description")
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: accessibilityDesc)
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(handlePrimaryAction)
        }

        let menu = NSMenu()
        let captureTitle = localizedString("menu.captureText", comment: "Capture Text/QR/Bar Code menu item")
        let preferencesTitle = localizedString("menu.preferences", comment: "Preferences menu item")
        let quitTitle = localizedString("menu.quit", comment: "Quit menu item")

        menu.addItem(withTitle: captureTitle, action: #selector(handleCapture), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: preferencesTitle, action: #selector(handlePreferences), keyEquivalent: ",")
        menu.addItem(withTitle: quitTitle, action: #selector(handleQuit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func handlePrimaryAction() {
        statusItem.menu?.cancelTracking()
        onCaptureRequested?()
    }

    @objc private func handleCapture() {
        onCaptureRequested?()
    }

    @objc private func handlePreferences() {
        onPreferencesRequested?()
    }

    @objc private func handleQuit() {
        onQuitRequested?()
    }
}
