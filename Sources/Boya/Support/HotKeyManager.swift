import AppKit
import Carbon.HIToolbox
import Foundation

/// Registers/unregisters global shortcuts via Carbon's `RegisterEventHotKey`.
/// This is public, documented API (still the standard mechanism AppKit apps
/// use for system-wide hotkeys that work regardless of which app is
/// frontmost) and requires no special entitlement or privacy permission.
@MainActor
final class HotKeyManager {

    static let shared = HotKeyManager()

    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var eventHandler: EventHandlerRef?

    private init() {
        installEventHandler()
        for action in ShortcutAction.allCases {
            if let saved = ShortcutStore.load(action) {
                register(action: action, shortcut: saved)
            }
        }
    }

    func onFire(_ action: ShortcutAction, _ handler: @escaping () -> Void) {
        handlers[action.hotKeyID] = handler
    }

    func register(action: ShortcutAction, shortcut: Shortcut) {
        unregister(action)
        guard shortcut.isSet else { return }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x464C4254), id: action.hotKeyID) // 'FLBT'
        let carbonMods = Self.carbonModifiers(from: shortcut.modifiers)

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            carbonMods,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            refs[action.hotKeyID] = ref
        }
    }

    func unregister(_ action: ShortcutAction) {
        if let ref = refs[action.hotKeyID] {
            UnregisterEventHotKey(ref)
            refs.removeValue(forKey: action.hotKeyID)
        }
    }

    private func installEventHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hkID = EventHotKeyID()
            GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID
            )
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handlers[hkID.id]?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }

    private static func carbonModifiers(from nsFlags: UInt32) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(nsFlags))
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}

enum ShortcutStore {
    static func load(_ action: ShortcutAction) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: action.defaultsKey) else { return nil }
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }

    static func save(_ action: ShortcutAction, _ shortcut: Shortcut) {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        UserDefaults.standard.set(data, forKey: action.defaultsKey)
    }
}
