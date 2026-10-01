import AppKit
import Carbon.HIToolbox

/// A recordable global shortcut, stored as raw Carbon key code + modifier mask.
struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32 // NSEvent.ModifierFlags.rawValue, carbon-compatible subset

    static let none = Shortcut(keyCode: 0, modifiers: 0)

    var isSet: Bool { modifiers != 0 }

    var displayString: String {
        guard isSet else { return "Not set" }
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 32: "U", 34: "I",
            31: "O", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
            49: "Space", 36: "Return", 48: "Tab", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return map[keyCode] ?? "Key \(keyCode)"
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case togglePicker = "Show window picker"
    case toggleFrontmost = "Toggle float on frontmost window"
    case cyclePriority = "Cycle floating priority"

    var id: String { rawValue }

    var defaultsKey: String { "shortcut.\(self)" }

    var hotKeyID: UInt32 {
        switch self {
        case .togglePicker: return 1
        case .toggleFrontmost: return 2
        case .cyclePriority: return 3
        }
    }
}
