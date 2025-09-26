import Foundation

class FeatureLimiter {
    static let shared = FeatureLimiter()

    private let trialTracker: TrialTracker

    private init(trialTracker: TrialTracker = .shared) {
        self.trialTracker = trialTracker
    }

    var shouldLimitTextCopy: Bool {
        return trialTracker.status == .free
    }

    var characterLimit: Int {
        return 144
    }

    func truncatedText(from fullText: String) -> String {
        if shouldLimitTextCopy && fullText.count > characterLimit {
            return String(fullText.prefix(characterLimit))
        }
        return fullText
    }

    var shouldDisableBarcodeDetection: Bool {
        return trialTracker.status == .free
    }
}