import Foundation
import Security

// MARK: - Trial Status

enum TrialStatus {
    case notStarted
    case active(daysRemaining: Int)
    case expired
}

// MARK: - Trial Tracker

final class TrialTracker {

    // MARK: - Constants

    private let trialStartDateKey = "com.snaptext.trial.startDate"
    private let trialDurationDays = 7
    private let keychainService = "com.snaptext.trial"

    // MARK: - Public Interface

    var hasTrialStarted: Bool {
        return getTrialStartDate() != nil
    }

    func startTrial() {
        guard !hasTrialStarted else { return }

        let startDate = Date()
        saveTrialStartDate(startDate)

        print("Trial started on: \(startDate)")
    }

    func getTrialStatus() -> TrialStatus {
        guard let startDate = getTrialStartDate() else {
            return .notStarted
        }

        let currentDate = Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
        let daysRemaining = trialDurationDays - daysSinceStart

        if daysRemaining > 0 {
            return .active(daysRemaining: daysRemaining)
        } else {
            return .expired
        }
    }

    func getRemainingDays() -> Int {
        if case .active(let remaining) = getTrialStatus() {
            return remaining
        }
        return 0
    }

    // MARK: - Private Methods - Keychain Storage

    private func saveTrialStartDate(_ date: Date) {
        let data = try! JSONEncoder().encode(date)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: trialStartDateKey,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save trial start date to keychain: \(status)")
        }
    }

    private func getTrialStartDate() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: trialStartDateKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let date = try? JSONDecoder().decode(Date.self, from: data) {
            return date
        }

        return nil
    }

    // MARK: - Debug Methods

    #if DEBUG
    func resetTrial() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: trialStartDateKey
        ]

        SecItemDelete(query as CFDictionary)
        print("Trial reset - removed from keychain")
    }

    func setTrialStartDate(_ date: Date) {
        // For testing purposes
        saveTrialStartDate(date)
    }
    #endif
}