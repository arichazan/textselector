import AppKit

struct HotkeyConfiguration: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case keyCode
        case modifierFlags
    }

    let keyCode: UInt32
    let modifierFlags: NSEvent.ModifierFlags

    init(keyCode: UInt32, modifierFlags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    static let `default` = HotkeyConfiguration(
        keyCode: 0x13, // '2' key in macOS virtual keycode table
        modifierFlags: [.command, .shift]
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyCode = try container.decode(UInt32.self, forKey: .keyCode)
        let rawFlags = try container.decode(UInt.self, forKey: .modifierFlags)
        self.modifierFlags = NSEvent.ModifierFlags(rawValue: rawFlags)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifierFlags.rawValue, forKey: .modifierFlags)
    }
}
