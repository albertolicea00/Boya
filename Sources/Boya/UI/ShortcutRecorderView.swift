import SwiftUI

/// Click-to-record control: captures the next key combo via a local NSEvent
/// monitor and writes it straight to `ShortcutStore` + re-registers the hotkey.
struct ShortcutRecorderView: View {
    let action: ShortcutAction
    @State private var shortcut: Shortcut
    @State private var isRecording = false
    @State private var monitor: Any?

    init(action: ShortcutAction) {
        self.action = action
        _shortcut = State(initialValue: ShortcutStore.load(action) ?? .none)
    }

    var body: some View {
        HStack {
            Text(action.rawValue)
            Spacer()
            Button(isRecording ? "Press a key combo…" : shortcut.displayString) {
                startRecording()
            }
            .frame(minWidth: 140)
            .foregroundStyle(isRecording ? .secondary : .primary)

            if shortcut.isSet {
                Button {
                    clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            defer { stopRecording() }
            guard event.keyCode != 53 else { return nil } // Escape cancels
            let mods = event.modifierFlags.intersection([.control, .option, .shift, .command])
            guard !mods.isEmpty else { return nil } // require at least one modifier

            let newShortcut = Shortcut(keyCode: UInt32(event.keyCode), modifiers: UInt32(mods.rawValue))
            shortcut = newShortcut
            ShortcutStore.save(action, newShortcut)
            HotKeyManager.shared.register(action: action, shortcut: newShortcut)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func clear() {
        shortcut = .none
        ShortcutStore.save(action, .none)
        HotKeyManager.shared.unregister(action)
    }
}
