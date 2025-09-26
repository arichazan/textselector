import AppKit

final class ClipboardManager {
    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let finalText = FeatureLimiter.shared.truncatedText(from: text)
        pasteboard.setString(finalText, forType: .string)

        // Show upgrade sheet if text was truncated
        if FeatureLimiter.shared.shouldLimitTextCopy && text.count > FeatureLimiter.shared.characterLimit {
            DispatchQueue.main.async {
                // Get the app delegate and show upgrade sheet
                if let appDelegate = NSApp.delegate as? GrabDabAppDelegate {
                    appDelegate.showUpgradeSheet(context: .multiLineBlocked)
                }
            }
        }
    }
}
