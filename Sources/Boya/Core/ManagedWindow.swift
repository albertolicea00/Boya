import AppKit
import CoreGraphics

/// Snapshot of an on-screen window owned by another process, as reported by
/// `CGWindowListCopyWindowInfo`. Identity is the CGWindowID, which is stable
/// for the lifetime of the window.
struct ManagedWindow: Identifiable, Hashable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    let appIcon: NSImage?

    var displayTitle: String {
        title.isEmpty ? ownerName : title
    }
}
