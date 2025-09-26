import SwiftUI
import AppKit

struct HotkeyRecorderView: View {
    @Binding var configuration: HotkeyConfiguration
    let displayString: (HotkeyConfiguration) -> String

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack {
            Text(displayString(configuration))
                .font(.system(.body, design: .monospaced))
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                .frame(minWidth: 120, alignment: .leading)

            Button(isRecording ? "Press combination…" : "Change") {
                toggleRecording()
            }
            .buttonStyle(.bordered)
        }
        .onDisappear {
            tearDownMonitor()
        }
    }

    private func toggleRecording() {
        if isRecording {
            tearDownMonitor()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event: event)
            return nil
        }
    }

    private func tearDownMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRecording = false
    }

    private func handle(event: NSEvent) {
        let sanitizedModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        guard !sanitizedModifiers.isEmpty else {
            tearDownMonitor()
            return
        }

        guard !KeyCodeTranslator.isFunctionKey(event.keyCode) else {
            tearDownMonitor()
            return
        }

        let keyCode = UInt32(event.keyCode)
        configuration = HotkeyConfiguration(keyCode: keyCode, modifierFlags: sanitizedModifiers)
        tearDownMonitor()
    }
}
