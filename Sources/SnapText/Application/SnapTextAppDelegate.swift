import AppKit
import Combine
import SwiftUI

final class SnapTextAppDelegate: NSObject, NSApplicationDelegate {
    private let settings = UserSettings.shared
    private lazy var statusItemController = StatusItemController()
    private lazy var captureController = CaptureController(settings: settings)
    private lazy var toastPresenter = ToastPresenter(settings: settings)
    private lazy var clipboardManager = ClipboardManager()
    private lazy var permissionManager = ScreenPermissionManager()
    private let hotkeyManager = GlobalHotkeyManager.shared

    private var preferencesWindow: NSWindow?

    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController.onCaptureRequested = { [weak self] in
            self?.startCapture()
        }
        statusItemController.onPreferencesRequested = { [weak self] in
            self?.showPreferences()
        }
        statusItemController.onQuitRequested = {
            NSApp.terminate(nil)
        }

        registerHotkey(settings.hotkey)
        observeSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }

    private func startCapture() {
        permissionManager.ensurePermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.toastPresenter.show(message: "Text could not be captured.")
                return
            }

            self.captureController.beginCapture { result in
                switch result {
                case let .success(ocrResult):
                    self.clipboardManager.copy(ocrResult.text)
                    let message = ocrResult.detectionType == .qrCode ? "QR Code Copied to Clipboard" : "Copied to Clipboard"
                    self.toastPresenter.show(message: message)
                case let .failure(error):
                    switch error {
                    case .cancelled:
                        break // Silent cancel per requirements
                    case .screenshotFailed:
                        self.toastPresenter.show(message: "Text could not be captured.")
                    case let .ocrFailed(underlyingError):
                        NSLog("OCR failed with error: \(underlyingError.localizedDescription)")
                        self.toastPresenter.show(message: "Text could not be captured.")
                    }
                }
            }
        }
    }

    private func registerHotkey(_ configuration: HotkeyConfiguration) {
        hotkeyManager.register(configuration: configuration) { [weak self] in
            self?.startCapture()
        }
    }

    private func observeSettings() {
        settings.$hotkey
            .sink { [weak self] configuration in
                self?.registerHotkey(configuration)
            }
            .store(in: &cancellables)
    }

    private func showPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesView(viewModel: PreferencesViewModel(settings: settings))
            let hostingView = NSHostingView(rootView: preferencesView)

            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "SnapText Preferences"
            preferencesWindow?.contentView = hostingView
            preferencesWindow?.center()
            preferencesWindow?.setFrameAutosaveName("PreferencesWindow")
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
