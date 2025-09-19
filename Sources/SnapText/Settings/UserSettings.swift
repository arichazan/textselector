import AppKit
import Combine

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    enum Keys: String {
        case hotkey
        case ocrLanguage
        case showToast
        case launchAtLogin
        case latinOnlyMode
        case enableRefinePass
        case minAcceptConfidence
        case reconsiderConfidence
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

    @Published var latinOnlyMode: Bool {
        didSet { persistToggle(.latinOnlyMode, value: latinOnlyMode) }
    }

    @Published var enableRefinePass: Bool {
        didSet { persistToggle(.enableRefinePass, value: enableRefinePass) }
    }

    @Published var minAcceptConfidence: Float {
        didSet { persistConfidence(.minAcceptConfidence, value: minAcceptConfidence) }
    }

    @Published var reconsiderConfidence: Float {
        didSet { persistConfidence(.reconsiderConfidence, value: reconsiderConfidence) }
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
        latinOnlyMode = userDefaults.object(forKey: Keys.latinOnlyMode.rawValue) as? Bool ?? false
        enableRefinePass = userDefaults.object(forKey: Keys.enableRefinePass.rawValue) as? Bool ?? false

        let defaultMinAccept: Float = 0.70
        let defaultReconsider: Float = 0.60

        if userDefaults.object(forKey: Keys.minAcceptConfidence.rawValue) != nil {
            let value = userDefaults.float(forKey: Keys.minAcceptConfidence.rawValue)
            minAcceptConfidence = max(0.1, min(1.0, value))
        } else {
            minAcceptConfidence = defaultMinAccept
        }

        if userDefaults.object(forKey: Keys.reconsiderConfidence.rawValue) != nil {
            let value = userDefaults.float(forKey: Keys.reconsiderConfidence.rawValue)
            reconsiderConfidence = max(0.1, min(1.0, value))
        } else {
            reconsiderConfidence = defaultReconsider
        }
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

    private func persistConfidence(_ key: Keys, value: Float) {
        let clampedValue = max(0.1, min(1.0, value))
        userDefaults.set(clampedValue, forKey: key.rawValue)
    }
}

enum OCRLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chineseSimplified:
            return "Chinese (Simplified)"
        case .chineseTraditional:
            return "Chinese (Traditional)"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .german:
            return "German"
        case .italian:
            return "Italian"
        case .portuguese:
            return "Portuguese"
        case .russian:
            return "Russian"
        case .arabic:
            return "Arabic"
        }
    }

    var visionRecognitionLanguage: String {
        switch self {
        case .english:
            return "en-US"
        case .chineseSimplified:
            return "zh-Hans"
        case .chineseTraditional:
            return "zh-Hant"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        case .spanish:
            return "es-ES"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .italian:
            return "it-IT"
        case .portuguese:
            return "pt-BR"
        case .russian:
            return "ru-RU"
        case .arabic:
            return "ar-SA"
        }
    }

    var tesseractLanguageCode: String {
        switch self {
        case .english:
            return "eng"
        case .chineseSimplified:
            return "chi_sim"
        case .chineseTraditional:
            return "chi_tra"
        case .japanese:
            return "jpn"
        case .korean:
            return "kor"
        case .spanish:
            return "spa"
        case .french:
            return "fra"
        case .german:
            return "deu"
        case .italian:
            return "ita"
        case .portuguese:
            return "por"
        case .russian:
            return "rus"
        case .arabic:
            return "ara"
        }
    }
}
