import Combine

final class PreferencesViewModel: ObservableObject {
    @Published var hotkey: HotkeyConfiguration {
        didSet {
            guard hotkey != settings.hotkey else { return }
            settings.hotkey = hotkey
        }
    }

    @Published var showToast: Bool {
        didSet {
            guard showToast != settings.showToast else { return }
            settings.showToast = showToast
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != settings.launchAtLogin else { return }
            settings.launchAtLogin = launchAtLogin
            loginItemManager.setLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var selectedLanguage: OCRLanguage {
        didSet {
            guard selectedLanguage != settings.ocrLanguage else { return }
            settings.ocrLanguage = selectedLanguage
        }
    }

    let availableLanguages = OCRLanguage.allCases

    private let settings: UserSettings
    private let loginItemManager: LoginItemManaging
    private var cancellables: Set<AnyCancellable> = []

    init(settings: UserSettings, loginItemManager: LoginItemManaging = LoginItemManager()) {
        self.settings = settings
        self.loginItemManager = loginItemManager
        self.hotkey = settings.hotkey
        self.showToast = settings.showToast
        self.launchAtLogin = settings.launchAtLogin
        self.selectedLanguage = settings.ocrLanguage

        bindSettings()

        if launchAtLogin {
            loginItemManager.setLaunchAtLogin(true)
        }
    }

    func displayString(for hotkey: HotkeyConfiguration) -> String {
        var parts: [String] = []
        if hotkey.modifierFlags.contains(.command) { parts.append("⌘") }
        if hotkey.modifierFlags.contains(.option) { parts.append("⌥") }
        if hotkey.modifierFlags.contains(.control) { parts.append("⌃") }
        if hotkey.modifierFlags.contains(.shift) { parts.append("⇧") }
        parts.append(KeyCodeTranslator.displayName(for: hotkey.keyCode))
        return parts.joined(separator: " ")
    }

    private func bindSettings() {
        settings.$hotkey
            .sink { [weak self] newValue in
                guard let self, self.hotkey != newValue else { return }
                self.hotkey = newValue
            }
            .store(in: &cancellables)

        settings.$showToast
            .sink { [weak self] newValue in
                guard let self, self.showToast != newValue else { return }
                self.showToast = newValue
            }
            .store(in: &cancellables)

        settings.$launchAtLogin
            .sink { [weak self] newValue in
                guard let self, self.launchAtLogin != newValue else { return }
                self.launchAtLogin = newValue
            }
            .store(in: &cancellables)

        settings.$ocrLanguage
            .sink { [weak self] newValue in
                guard let self, self.selectedLanguage != newValue else { return }
                self.selectedLanguage = newValue
            }
            .store(in: &cancellables)
    }
}
