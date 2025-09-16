import AppKit
import Carbon

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    private init() {
        installEventHandlerIfNeeded()
    }

    deinit {
        unregister()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    func register(configuration: HotkeyConfiguration, handler: @escaping () -> Void) {
        unregister()
        callback = handler

        let hotKeyID = EventHotKeyID(signature: OSType(UInt32("SNAP".fourCharCodeValue)), id: 1)
        let status = RegisterEventHotKey(
            configuration.keyCode,
            configuration.modifierFlags.carbonFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("Failed to register hotkey with status: \(status)")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetEventDispatcherTarget(), { _, eventRef, userData in
            guard let userData else { return noErr }
            let unmanaged = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData)
            let manager = unmanaged.takeUnretainedValue()
            manager.callback?()
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)
    }
}

private extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var carbonFlags: UInt32 = 0
        if contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if contains(.option) { carbonFlags |= UInt32(optionKey) }
        if contains(.control) { carbonFlags |= UInt32(controlKey) }
        if contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        return carbonFlags
    }
}

private extension String {
    var fourCharCodeValue: UInt32 {
        var result: UInt32 = 0
        for scalar in unicodeScalars {
            result = (result << 8) + UInt32(scalar.value)
        }
        return result
    }
}
