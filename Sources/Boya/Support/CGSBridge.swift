import CoreGraphics
import Foundation

/// Thin bridge to undocumented CoreGraphics/SkyLight "CGS" window-server calls.
///
/// Apple exposes no public API to change the z-order level of a window owned
/// by another process. Every "always-on-top" utility that isn't a MacForge-style
/// injected plugin (Afloat, Lungo, HoverView, ...) relies on these private
/// symbols, which live in SkyLight.framework and are transitively loaded into
/// every AppKit process. Symbol names/signatures have been stable across macOS
/// releases for years but are NOT documented or guaranteed by Apple, can break
/// on a future OS update, and make the app ineligible for Mac App Store
/// distribution. Verify behavior after any macOS upgrade.
enum CGSBridge {

    typealias CGSConnectionID = Int32

    private typealias MainConnectionIDFn = @convention(c) () -> CGSConnectionID
    private typealias SetWindowLevelFn = @convention(c) (CGSConnectionID, CGWindowID, Int32) -> Int32
    private typealias OrderWindowFn = @convention(c) (CGSConnectionID, CGWindowID, Int32, CGWindowID) -> Int32

    // kCGSOrderAbove = 1, kCGSOrderBelow = -1, kCGSOrderOut = 0
    private static let orderAbove: Int32 = 1
    private static let orderBelow: Int32 = -1

    private static let handle: UnsafeMutableRawPointer? = {
        // RTLD_DEFAULT usually resolves these since AppKit pulls SkyLight in,
        // but fall back to an explicit dlopen of the private framework path.
        if let h = dlopen(nil, RTLD_NOW), dlsym(h, "CGSMainConnectionID") != nil {
            return h
        }
        return dlopen(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            RTLD_NOW
        )
    }()

    private static let mainConnectionID: MainConnectionIDFn? = {
        guard let handle, let sym = dlsym(handle, "CGSMainConnectionID") else { return nil }
        return unsafeBitCast(sym, to: MainConnectionIDFn.self)
    }()

    private static let setWindowLevelFn: SetWindowLevelFn? = {
        guard let handle, let sym = dlsym(handle, "CGSSetWindowLevel") else { return nil }
        return unsafeBitCast(sym, to: SetWindowLevelFn.self)
    }()

    private static let orderWindowFn: OrderWindowFn? = {
        guard let handle, let sym = dlsym(handle, "CGSOrderWindow") else { return nil }
        return unsafeBitCast(sym, to: OrderWindowFn.self)
    }()

    /// True when the private symbols resolved. If false, floating silently
    /// becomes a no-op rather than crashing the app.
    static var isAvailable: Bool {
        mainConnectionID != nil && setWindowLevelFn != nil && orderWindowFn != nil
    }

    private static var connection: CGSConnectionID? = {
        mainConnectionID?()
    }()

    @discardableResult
    static func setLevel(of windowID: CGWindowID, to level: CGWindowLevel) -> Bool {
        guard let connection, let setWindowLevelFn else { return false }
        return setWindowLevelFn(connection, windowID, Int32(level)) == 0
    }

    /// Orders `windowID` directly above `relativeTo` (pass 0 to send to the
    /// very top of its level).
    @discardableResult
    static func orderAbove(_ windowID: CGWindowID, relativeTo: CGWindowID = 0) -> Bool {
        guard let connection, let orderWindowFn else { return false }
        return orderWindowFn(connection, windowID, orderAbove, relativeTo) == 0
    }

    @discardableResult
    static func orderBelow(_ windowID: CGWindowID, relativeTo: CGWindowID) -> Bool {
        guard let connection, let orderWindowFn else { return false }
        return orderWindowFn(connection, windowID, orderBelow, relativeTo) == 0
    }

    /// Public, documented constants — only the *setter* (CGSSetWindowLevel) is private.
    static var floatingLevel: CGWindowLevel { kCGFloatingWindowLevel }
    static var normalLevel: CGWindowLevel { kCGNormalWindowLevel }
}
