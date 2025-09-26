import SwiftUI

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Form {
                Section(header: Text("preferences.capture.header", bundle: .module)) {
                    LabeledContent {
                        HotkeyRecorderView(configuration: $viewModel.hotkey, displayString: viewModel.displayString)
                    } label: {
                        Text("preferences.globalHotkey", bundle: .module)
                    }

                    Picker(selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.availableLanguages) { language in
                            Text(language.localizedDisplayName).tag(language)
                        }
                    } label: {
                        Text("preferences.ocrLanguage", bundle: .module)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("preferences.feedback.header", bundle: .module)) {
                    Toggle(isOn: $viewModel.showToast) {
                        Text("preferences.showToast", bundle: .module)
                    }
                    .toggleStyle(.switch)
                }

                Section(header: Text("preferences.startup.header", bundle: .module)) {
                    Toggle(isOn: $viewModel.launchAtLogin) {
                        Text("preferences.launchAtLogin", bundle: .module)
                    }
                    .toggleStyle(.switch)
                }

                Section(header: Text("preferences.advanced.header", bundle: .module)) {
                    Toggle(isOn: $viewModel.latinOnlyMode) {
                        Text("preferences.latinOnlyMode", bundle: .module)
                    }
                    .toggleStyle(.switch)

                    Toggle(isOn: $viewModel.enableRefinePass) {
                        Text("preferences.enableRefinePass", bundle: .module)
                    }
                    .toggleStyle(.switch)
                }
            }
            .formStyle(.grouped)

            Text("preferences.autoSave", bundle: .module)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: PreferencesViewModel(settings: UserSettings.shared))
            .frame(width: 420, height: 320)
    }
}
