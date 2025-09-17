import SwiftUI

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Form {
                Section(header: Text("Capture")) {
                    LabeledContent("Global Hotkey") {
                        HotkeyRecorderView(configuration: $viewModel.hotkey, displayString: viewModel.displayString)
                    }

                    Picker("OCR Language", selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.availableLanguages) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Feedback")) {
                    Toggle("Show confirmation toast", isOn: $viewModel.showToast)
                        .toggleStyle(.switch)
                }

                Section(header: Text("Startup")) {
                    Toggle("Launch SnapText at login", isOn: $viewModel.launchAtLogin)
                        .toggleStyle(.switch)
                }
            }
            .formStyle(.grouped)

            Text("Changes are saved automatically.")
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
