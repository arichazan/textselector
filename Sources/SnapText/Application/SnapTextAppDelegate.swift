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
    private var resultWindow: NSWindow?

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
                let message = localizedString("toast.permission", comment: "Permission required toast")
                self.toastPresenter.show(message: message)
                return
            }

            self.captureController.beginCapture { result in
                switch result {
                case let .success(ocrResult):
                    self.showCaptureResult(ocrResult)
                case let .failure(error):
                    switch error {
                    case .cancelled:
                        break // Silent cancel per requirements
                    case .screenshotFailed:
                        let message = localizedString("toast.failed", comment: "OCR failed toast")
                        self.toastPresenter.show(message: message)
                    case let .ocrFailed(underlyingError):
                        NSLog("OCR failed with error: \(underlyingError.localizedDescription)")
                        let message = localizedString("toast.failed", comment: "OCR failed toast")
                        self.toastPresenter.show(message: message)
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
            let title = localizedString("preferences.title", comment: "Preferences window title")
            preferencesWindow?.title = title
            preferencesWindow?.contentView = hostingView
            preferencesWindow?.center()
            preferencesWindow?.setFrameAutosaveName("PreferencesWindow")
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showCaptureResult(_ result: OCRResult) {
        // Close existing window if any
        resultWindow?.close()
        resultWindow = nil

        let resultView = CaptureResultView(result: result) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Close window first
                self.resultWindow?.close()
                self.resultWindow = nil

                // Copy to clipboard
                self.clipboardManager.copy(result.text)

                // Show toast message
                let message: String
                switch result.detectionType {
                case .qrCode:
                    message = localizedString("toast.qrCode", comment: "QR code copied toast")
                case .barcode:
                    message = localizedString("toast.barcode", comment: "Barcode copied toast")
                case .text:
                    message = localizedString("toast.copied", comment: "Text copied toast")
                }
                self.toastPresenter.show(message: message)
            }
        }

        let hostingView = NSHostingView(rootView: resultView)

        resultWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let resultTitle = localizedString("result.title", comment: "Result window title")
        resultWindow?.title = resultTitle
        resultWindow?.contentView = hostingView
        resultWindow?.center()
        resultWindow?.level = .floating
        resultWindow?.isReleasedWhenClosed = false
        resultWindow?.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}
