import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 440, height: 320)
    }
}

private struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("reapplyOnLaunch") private var reapplyOnLaunch = true
    @State private var screenRecordingGranted = PermissionsManager.hasScreenRecordingAccess
    @State private var accessibilityGranted = PermissionsManager.hasAccessibilityAccess

    var body: some View {
        Form {
            Section {
                Toggle("Launch Boya at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        try? newValue
                            ? SMAppService.mainApp.register()
                            : SMAppService.mainApp.unregister()
                    }
                Toggle("Keep floating windows floating after relaunch", isOn: $reapplyOnLaunch)
            }

            Section("Permissions") {
                permissionRow(
                    title: "Screen Recording",
                    detail: "Needed to read window titles of other apps.",
                    granted: screenRecordingGranted
                ) {
                    PermissionsManager.requestScreenRecordingAccess()
                    PermissionsManager.openScreenRecordingSettings()
                }

                permissionRow(
                    title: "Accessibility",
                    detail: "Reserved for future window move/resize support.",
                    granted: accessibilityGranted
                ) {
                    PermissionsManager.openAccessibilitySettings()
                }
            }
        }
        .padding()
        .onAppear {
            screenRecordingGranted = PermissionsManager.hasScreenRecordingAccess
            accessibilityGranted = PermissionsManager.hasAccessibilityAccess
        }
    }

    @ViewBuilder
    private func permissionRow(title: String, detail: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .labelStyle(.iconOnly)
            } else {
                Button("Open Settings…", action: action)
            }
        }
    }
}

private struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                ForEach(ShortcutAction.allCases) { action in
                    ShortcutRecorderView(action: action)
                }
            } footer: {
                Text("Click a shortcut, then press a key combo with at least one modifier key (⌘ ⌥ ⌃ ⇧). Press Escape to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

private struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            Text("Boya")
                .font(.title2).fontWeight(.semibold)
            Text("Version \(version)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Pick any open window from the menu bar and keep it floating above everything else. Float several at once — the most recently floated window stays on top of the stack.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 320)
            Text("Inspired by AfloatX (MacForge plugin by jslegendre).")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
