import AppKit
import Carbon

enum KeyCodeTranslator {
    static func displayName(for keyCode: UInt32) -> String {
        if let special = specialKeyNames[keyCode] {
            return special
        }

        let keyboard = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let rawLayoutData = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData) else {
            return "Key \(keyCode)"
        }

        let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self) as Data
        guard let keyLayout = layoutData.withUnsafeBytes({ (pointer: UnsafeRawBufferPointer) -> UnsafePointer<UCKeyboardLayout>? in
            return pointer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self)
        }) else {
            return "Key \(keyCode)"
        }

        var deadKeyState: UInt32 = 0
        let maxLength = 4
        var chars: [UniChar] = Array(repeating: 0, count: maxLength)
        var actualLength = 0

        let status = UCKeyTranslate(
            keyLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxLength,
            &actualLength,
            &chars
        )

        if status == noErr, actualLength > 0 {
            return String(utf16CodeUnits: chars, count: actualLength)
        } else {
            return "Key \(keyCode)"
        }
    }

    static func isFunctionKey(_ keyCode: UInt16) -> Bool {
        functionKeyRange.contains(Int(keyCode))
    }

    private static let functionKeyRange = 122...135

    private static let specialKeyNames: [UInt32: String] = [
        0x24: "↩", // return
        0x30: "⇥", // tab
        0x31: "Space",
        0x33: "⌫", // delete
        0x35: "⎋", // escape
        0x7B: "←",
        0x7C: "→",
        0x7D: "↓",
        0x7E: "↑"
    ]
}
