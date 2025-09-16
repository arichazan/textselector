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
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "SnapText")
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(handlePrimaryAction)
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Text", action: #selector(handleCapture), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(handlePreferences), keyEquivalent: ",")
        menu.addItem(withTitle: "Quit SnapText", action: #selector(handleQuit), keyEquivalent: "q")
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
