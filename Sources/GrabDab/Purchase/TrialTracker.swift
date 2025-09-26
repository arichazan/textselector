import Foundation

class TrialTracker {
    static let shared = TrialTracker()

    enum UserStatus {
        case premium
        case trial
        case free
    }

    private var settings: UserSettings

    private init(settings: UserSettings = .shared) {
        self.settings = settings
    }

    var status: UserStatus {
        if settings.isPremium {
            return .premium
        }
        if isTrialActive() {
            return .trial
        }
        // If trial has never started, they are still in a pre-trial state
        // which functions like the trial. The trial only starts on first capture.
        if settings.trialStartDate == nil {
            return .trial
        }
        return .free
    }

    func startTrial() {
        // Only start the trial if it hasn't been started before and the user is not premium
        guard settings.trialStartDate == nil, !settings.isPremium else { return }
        settings.trialStartDate = Date()
    }

    var shouldShowTrialExpired: Bool {
        return true
        guard let trialStartDate = settings.trialStartDate, !settings.isPremium else { return false }
        let sevenDaysInSeconds: TimeInterval = 604800
        let isExpired = Date().timeIntervalSince(trialStartDate) > sevenDaysInSeconds

        // Only show once - check if we've already shown the expired message
        let hasShownExpired = settings.hasShownTrialExpired

        if isExpired && !hasShownExpired {
            settings.hasShownTrialExpired = true
            return true
        }

        return false
    }

    private func isTrialActive() -> Bool {
        guard let trialStartDate = settings.trialStartDate else {
            return false // Trial hasn't started
        }
        // 7 days in seconds = 7 * 24 * 60 * 60 = 604800
        let sevenDaysInSeconds: TimeInterval = 604800
        let isStillActive = Date().timeIntervalSince(trialStartDate) <= sevenDaysInSeconds
        
        // If user is premium, the trial is irrelevant
        return isStillActive && !settings.isPremium
    }
}