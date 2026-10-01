# Boya

A tiny, native macOS menu bar utility that keeps any open window floating
always-on-top — inspired by [AfloatX](https://github.com/jslegendre/AfloatX),
but built as a standalone app instead of a MacForge plugin.

Click the menu bar icon, pick any open window from the list, and it stays
pinned above every other app. Float more than one at a time — the most
recently floated window is reasserted to the top of the stack; the rest keep
their relative order underneath.

## Features

- **Window picker** — menu bar popover lists every on-screen window from
  other running apps, with its owning app's icon and title.
- **Floating priority stack (LIFO)** — the last window you float jumps to
  the very top. Un-floating a window doesn't reshuffle the others.
- **Global shortcuts** (configurable in Settings):
  - Show window picker
  - Toggle float on the frontmost window
  - Cycle floating priority
- **Settings window** — General (launch at login, permission status),
  Shortcuts (click-to-record), About.
- No Dock icon, no bundled frameworks, no network access.

## How it works

Apple doesn't expose a public API to change the window level of a window
owned by another process. Boya uses the same private `SkyLight.framework`
window-server calls (`CGSSetWindowLevel`, `CGSOrderWindow`) that most
non-plugin "always-on-top" utilities rely on, resolved at runtime via
`dlsym` — no code injection. Practical consequences:

- **Not eligible for the Mac App Store** (private API usage).
- Requires **Screen Recording** permission so `CGWindowListCopyWindowInfo`
  can report real window titles for other apps' windows.
- These symbols are undocumented. They've been stable for years but could
  change on a future macOS release — `WindowManager.isCGSAvailable` guards
  against a hard crash if they ever disappear, but floating would silently
  stop working.

Global shortcuts use Carbon's `RegisterEventHotKey`, which is public,
documented API and needs no extra permission.

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.10+ / Xcode command line tools

## Build & run

```bash
./build_app.sh           # debug build
./build_app.sh release   # release build
open Boya.app
```

The script compiles the Swift package, wraps the binary in a minimal
`.app` bundle (`Resources/Info.plist` sets `LSUIElement` so it's menu-bar
only, no Dock icon), and signs it ad-hoc (`codesign --sign -`) so Gatekeeper
allows local execution. It is **not notarized** — fine for running on your
own Mac, but sharing the binary with someone else would need a Developer ID
and notarization.

On first launch, grant **Screen Recording** access when prompted (or from
Settings → General → Permissions) so window titles show up correctly.

## Project layout

```
Sources/Boya/
  main.swift                     entry point, NSApplicationDelegate
  Core/
    ManagedWindow.swift           window snapshot model
    WindowManager.swift           window enumeration + floating/priority state
  Support/
    CGSBridge.swift                private CGS window-server calls
    PermissionsManager.swift       Screen Recording / Accessibility checks
    HotKeyManager.swift            Carbon global hotkey registration
    ShortcutModel.swift            shortcut model + persistence
  UI/
    StatusBarController.swift      NSStatusItem, popover, settings window
    MenuContentView.swift          window picker SwiftUI view
    SettingsView.swift             Settings window (General/Shortcuts/About)
    ShortcutRecorderView.swift     click-to-record shortcut control
```

## Disclaimer

Personal utility, not affiliated with or endorsed by AfloatX / jslegendre.
