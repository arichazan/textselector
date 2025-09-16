import AppKit
import Combine

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    enum Keys: String {
        case hotkey
        case ocrLanguage
        case showToast
        case launchAtLogin
    }

    @Published var hotkey: HotkeyConfiguration {
        didSet { persistHotkey() }
    }

    @Published var ocrLanguage: OCRLanguage {
        didSet { persistLanguage() }
    }

    @Published var showToast: Bool {
        didSet { persistToggle(.showToast, value: showToast) }
    }

    @Published var launchAtLogin: Bool {
        didSet { persistToggle(.launchAtLogin, value: launchAtLogin) }
    }

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let hotkeyData = userDefaults.data(forKey: Keys.hotkey.rawValue),
           let decoded = try? JSONDecoder().decode(HotkeyConfiguration.self, from: hotkeyData) {
            hotkey = decoded
        } else {
            hotkey = .default
        }

        if let rawValue = userDefaults.string(forKey: Keys.ocrLanguage.rawValue),
           let language = OCRLanguage(rawValue: rawValue) {
            ocrLanguage = language
        } else {
            ocrLanguage = .english
        }

        showToast = userDefaults.object(forKey: Keys.showToast.rawValue) as? Bool ?? true
        launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin.rawValue) as? Bool ?? false
    }

    private func persistHotkey() {
        guard let data = try? JSONEncoder().encode(hotkey) else { return }
        userDefaults.set(data, forKey: Keys.hotkey.rawValue)
    }

    private func persistLanguage() {
        userDefaults.set(ocrLanguage.rawValue, forKey: Keys.ocrLanguage.rawValue)
    }

    private func persistToggle(_ key: Keys, value: Bool) {
        userDefaults.set(value, forKey: key.rawValue)
    }
}

enum OCRLanguage: String, CaseIterable, Identifiable {
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        }
    }

    var visionRecognitionLanguage: String {
        switch self {
        case .english:
            return "en_US"
        }
    }
}
