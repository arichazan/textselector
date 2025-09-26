import AppKit
import CoreGraphics

final class ScreenPermissionManager {
    private let onboardingKey = "ScreenPermissionOnboardingShown"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func ensurePermission(grantedHandler: @escaping (Bool) -> Void) {
        if CGPreflightScreenCaptureAccess() {
            grantedHandler(true)
            return
        }

        presentOnboardingIfNeeded()

        DispatchQueue.global(qos: .userInitiated).async {
            let granted = CGRequestScreenCaptureAccess()
            DispatchQueue.main.async {
                grantedHandler(granted)
            }
        }
    }

    func presentOnboardingIfNeeded() {
        guard userDefaults.bool(forKey: onboardingKey) == false else { return }

        let alert = NSAlert()
        alert.messageText = localizedString("permission.title", comment: "Permission dialog title")
        alert.informativeText = localizedString("permission.message", comment: "Permission dialog message")
        alert.alertStyle = .informational
        alert.addButton(withTitle: localizedString("permission.continue", comment: "Continue button"))

        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }

        userDefaults.set(true, forKey: onboardingKey)
    }
}
