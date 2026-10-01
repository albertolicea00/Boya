import AppKit
import Combine
import CoreGraphics

/// Enumerates other apps' on-screen windows and owns the floating/priority
/// state machine.
///
/// Priority rule (there is no macOS convention to copy here, so this is a
/// deliberate design choice): floating windows form a LIFO stack. The most
/// recently floated window is reasserted to the very top; every other
/// floating window keeps its previous relative order underneath it. Nothing
/// is re-ordered when a window is *un*-floated — the remaining stack keeps
/// its existing relative order.
@MainActor
final class WindowManager: ObservableObject {

    static let shared = WindowManager()

    @Published private(set) var windows: [ManagedWindow] = []
    /// Front = highest priority (topmost).
    @Published private(set) var floatingStack: [CGWindowID] = []

    private var ownPID: pid_t { ProcessInfo.processInfo.processIdentifier }
    private var iconCache: [pid_t: NSImage] = [:]

    private init() {}

    var isCGSAvailable: Bool { CGSBridge.isAvailable }

    func isFloating(_ id: CGWindowID) -> Bool {
        floatingStack.contains(id)
    }

    /// Priority rank, 1-based, where 1 is topmost. Nil if not floating.
    func priority(of id: CGWindowID) -> Int? {
        guard let idx = floatingStack.firstIndex(of: id) else { return nil }
        return idx + 1
    }

    func refresh() {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else {
            windows = []
            return
        }

        var seenApps = Set<pid_t>()
        var result: [ManagedWindow] = []

        for entry in list {
            guard
                let layer = entry[kCGWindowLayer] as? Int, layer == 0,
                let wid = entry[kCGWindowNumber] as? Int,
                let pid = entry[kCGWindowOwnerPID] as? Int,
                pid != Int(ownPID)
            else { continue }

            let ownerName = entry[kCGWindowOwnerName] as? String ?? "Unknown"
            let title = entry[kCGWindowName] as? String ?? ""

            // Skip helper/background windows with no usable surface — common
            // for menu-extras, the Dock, system UI, etc. A zero-size bounds
            // rect is the reliable signal across apps.
            if let bounds = entry[kCGWindowBounds] as? [String: CGFloat],
               (bounds["Width"] ?? 0) < 40 || (bounds["Height"] ?? 0) < 40 {
                continue
            }

            result.append(
                ManagedWindow(
                    id: CGWindowID(wid),
                    ownerPID: pid_t(pid),
                    ownerName: ownerName,
                    title: title,
                    appIcon: icon(forPID: pid_t(pid))
                )
            )
            seenApps.insert(pid_t(pid))
        }

        // Drop floating entries for windows that disappeared (closed apps).
        floatingStack.removeAll { wid in !result.contains { $0.id == wid } }

        windows = result
    }

    func toggleFloating(_ window: ManagedWindow) {
        if isFloating(window.id) {
            unfloat(window.id)
        } else {
            float(window.id)
        }
    }

    private func float(_ id: CGWindowID) {
        guard CGSBridge.isAvailable else { return }
        CGSBridge.setLevel(of: id, to: CGSBridge.floatingLevel)

        floatingStack.removeAll { $0 == id }
        floatingStack.insert(id, at: 0)
        reassertOrder()
    }

    private func unfloat(_ id: CGWindowID) {
        guard CGSBridge.isAvailable else { return }
        CGSBridge.setLevel(of: id, to: CGSBridge.normalLevel)
        floatingStack.removeAll { $0 == id }
        // Remaining windows keep their relative order; no reassertion needed.
    }

    /// Re-applies window-server ordering so `floatingStack[0]` sits above
    /// `floatingStack[1]`, which sits above `floatingStack[2]`, etc. Called
    /// any time the stack's head changes.
    private func reassertOrder() {
        guard let top = floatingStack.first else { return }
        CGSBridge.orderAbove(top)
        for i in 1..<floatingStack.count {
            CGSBridge.orderBelow(floatingStack[i], relativeTo: floatingStack[i - 1])
        }
    }

    /// Floats the frontmost (non-Boya) window — used by the global hotkey.
    func toggleFloatingFrontmostWindow() {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ownPID else { return }
        refresh()
        if let match = windows.first(where: { $0.ownerPID == front.processIdentifier }) {
            toggleFloating(match)
        }
    }

    /// Promotes the next-highest floating window to the top of the stack —
    /// used by the "cycle priority" hotkey when more than one window floats.
    func cyclePriority() {
        guard floatingStack.count > 1 else { return }
        let next = floatingStack.removeFirst()
        floatingStack.append(next)
        reassertOrder()
    }

    private func icon(forPID pid: pid_t) -> NSImage? {
        if let cached = iconCache[pid] { return cached }
        guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        let icon = app.icon
        iconCache[pid] = icon
        return icon
    }
}
