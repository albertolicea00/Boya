import AppKit
import SwiftUI

@MainActor
final class StatusBarController {

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var eventMonitor: Any?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lifepreserver", accessibilityDescription: "Boya")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView(
                onOpenSettings: { [weak self] in self?.showSettings() },
                onQuit: { NSApp.terminate(nil) }
            )
        )

        registerHotKeys()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            WindowManager.shared.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func showPicker() {
        if !popover.isShown {
            togglePopover()
        }
    }

    private func showSettings() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Boya Settings"
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SettingsView())
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func registerHotKeys() {
        HotKeyManager.shared.onFire(.togglePicker) { [weak self] in
            self?.showPicker()
        }
        HotKeyManager.shared.onFire(.toggleFrontmost) {
            WindowManager.shared.toggleFloatingFrontmostWindow()
        }
        HotKeyManager.shared.onFire(.cyclePriority) {
            WindowManager.shared.cyclePriority()
        }
    }
}
