import AppKit
import ApplicationServices
import CoreGraphics

/// Tracks the two macOS privacy permissions Boya depends on:
/// - Screen Recording: required since macOS Catalina for `CGWindowListCopyWindowInfo`
///   to return real window titles for windows owned by other processes (without it,
///   titles come back empty/"Window").
/// - Accessibility: not required for the current float/order feature set (which
///   only calls CGS window-server functions), but reserved for a future
///   move/resize feature via AXUIElement. Exposed now so Settings can show it.
enum PermissionsManager {

    static var hasScreenRecordingAccess: Bool {
        // CGPreflightScreenCaptureAccess is the public, non-prompting check
        // (macOS 11+). Prompting happens the first time a screen-capture API
        // is actually invoked.
        CGPreflightScreenCaptureAccess()
    }

    static var hasAccessibilityAccess: Bool {
        AXIsProcessTrusted()
    }

    static func requestScreenRecordingAccess() {
        _ = CGRequestScreenCaptureAccess()
    }

    static func openScreenRecordingSettings() {
        openPane(
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )
    }

    static func openAccessibilitySettings() {
        openPane(
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }

    private static func openPane(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
