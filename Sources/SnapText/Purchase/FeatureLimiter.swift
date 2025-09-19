import Foundation

// MARK: - Feature Limitation Result

struct LimitationResult {
    let isAllowed: Bool
    let limitedContent: String?
    let shouldShowUpgrade: Bool
    let upgradeContext: UpgradeContext?
    let message: String?
}

// MARK: - Feature Limiter

@MainActor
final class FeatureLimiter {
    private let purchaseManager = PurchaseManager.shared

    // MARK: - Text Processing

    func processTextResult(_ text: String, lineCount: Int) -> LimitationResult {
        // Single line text is always free
        if lineCount <= 1 {
            return LimitationResult(
                isAllowed: true,
                limitedContent: text,
                shouldShowUpgrade: false,
                upgradeContext: nil,
                message: nil
            )
        }

        // Multi-line text requires full version
        if purchaseManager.isFullVersionUnlocked {
            return LimitationResult(
                isAllowed: true,
                limitedContent: text,
                shouldShowUpgrade: false,
                upgradeContext: nil,
                message: nil
            )
        } else {
            // Show only first line in free mode
            let firstLine = text.components(separatedBy: .newlines).first ?? text
            let message = localizedString("freeMode.multiLineRestricted", comment: "Multi-line restricted message")

            return LimitationResult(
                isAllowed: false,
                limitedContent: firstLine,
                shouldShowUpgrade: true,
                upgradeContext: .multiLineBlocked,
                message: message
            )
        }
    }

    // MARK: - QR Code Processing

    func processQRCodeResult(_ text: String) -> LimitationResult {
        if purchaseManager.isFullVersionUnlocked {
            return LimitationResult(
                isAllowed: true,
                limitedContent: text,
                shouldShowUpgrade: false,
                upgradeContext: nil,
                message: nil
            )
        } else {
            let message = localizedString("freeMode.qrCodeLocked", comment: "QR code locked message")

            return LimitationResult(
                isAllowed: false,
                limitedContent: nil,
                shouldShowUpgrade: true,
                upgradeContext: .qrCodeBlocked,
                message: message
            )
        }
    }

    // MARK: - Barcode Processing

    func processBarcodeResult(_ text: String) -> LimitationResult {
        if purchaseManager.isFullVersionUnlocked {
            return LimitationResult(
                isAllowed: true,
                limitedContent: text,
                shouldShowUpgrade: false,
                upgradeContext: nil,
                message: nil
            )
        } else {
            let message = localizedString("freeMode.barcodeLocked", comment: "Barcode locked message")

            return LimitationResult(
                isAllowed: false,
                limitedContent: nil,
                shouldShowUpgrade: true,
                upgradeContext: .barcodeBlocked,
                message: message
            )
        }
    }

    // MARK: - Trial Activation

    func shouldActivateTrial(for detectionType: DetectionType, lineCount: Int) -> Bool {
        // Activate trial on first meaningful capture if not purchased and trial not started
        if case .freeLimited = purchaseManager.purchaseStatus {
            switch detectionType {
            case .text:
                return lineCount > 1 // Multi-line text
            case .qrCode, .barcode:
                return true // Any QR/barcode
            }
        }
        return false
    }

    // MARK: - Helper Methods

    func countLines(in text: String) -> Int {
        return text.components(separatedBy: .newlines).count
    }

    func formatTrialStatus() -> String? {
        switch purchaseManager.purchaseStatus {
        case .trial(let daysRemaining):
            return String(format: localizedString("status.trialActive", comment: "Trial active status"), daysRemaining)
        case .unlocked:
            return localizedString("status.unlocked", comment: "Unlocked status")
        case .freeLimited:
            return localizedString("status.freeMode", comment: "Free mode status")
        }
    }
}