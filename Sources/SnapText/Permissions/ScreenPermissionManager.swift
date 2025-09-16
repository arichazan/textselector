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
        alert.messageText = "SnapText needs screen access"
        alert.informativeText = "To capture text from your screen, macOS requires granting SnapText Screen Recording permission. You'll see the standard system prompt next."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")

        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }

        userDefaults.set(true, forKey: onboardingKey)
    }
}
