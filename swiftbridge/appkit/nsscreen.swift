//
//  nsscreen.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//

import AppKit
import CoreGraphics


private struct SwiftNSScreenArrayHeader {
    var count: Int32
    var reserved: Int32
    /// Pointer to the first element of the screen pointer array.
    /// Points into the same Swift-owned buffer returned by `swift_nsscreen_get_screen_array`.
    var items: UnsafeMutablePointer<UnsafeRawPointer?>?
}

private var gScreenArrayBuffer = ReusableRawBuffer()

@_cdecl("swift_nsscreen_primary")
public func swift_nsscreen_primary() -> UnsafeRawPointer? {
    guard let screen = NSScreen.main else { return nil }
    // toOpaque() returns UnsafeMutableRawPointer; convert to UnsafeRawPointer explicitly
    return UnsafeRawPointer(Unmanaged.passUnretained(screen).toOpaque())
}

// Typed wrapper to avoid needing explicit generic specialization at the call site.
// This returns the same tuple shape as `makeArrayView` but with concrete Header/Element types
private func makeNSScreenArrayView(
    count: Int,
    buffer: inout ReusableRawBuffer
) -> (base: UnsafeMutableRawPointer, header: UnsafeMutablePointer<SwiftNSScreenArrayHeader>, elements: UnsafeMutablePointer<UnsafeRawPointer?>)? {
    return makeArrayView(count: count, buffer: &buffer)
}

/// Returns a pointer to a Swift-owned buffer containing:
/// - `SwiftNSScreenArrayHeader` (count)
/// - followed by `count` `UnsafeRawPointer?` screen pointers
///
/// The returned pointer remains valid until the next call to this function.
/// The caller must not free it.
@_cdecl("swift_nsscreen_get_screen_array")
public func swift_nsscreen_get_screen_array() -> UnsafeRawPointer? {
    let screens = NSScreen.screens
    let count = screens.count

    guard let view = makeNSScreenArrayView(count: count, buffer: &gScreenArrayBuffer) else { return nil }

    view.header.pointee = SwiftNSScreenArrayHeader(
        count: Int32(count),
        reserved: 0,
        items: view.elements
    )
    writeUnretainedObjectPointers(screens, to: view.elements)

    // view.base is UnsafeMutableRawPointer — convert to UnsafeRawPointer for the public API
    return UnsafeRawPointer(view.base)
}

@_cdecl("swift_nsscreen_width")
public func swift_nsscreen_width(_ screenPtr: UnsafeRawPointer?) -> Double {
    guard let screenPtr else { return 0 }
    let screen = Unmanaged<NSScreen>.fromOpaque(screenPtr).takeUnretainedValue()
    return Double(screen.frame.size.width)
}

@_cdecl("swift_nsscreen_height")
public func swift_nsscreen_height(_ screenPtr: UnsafeRawPointer?) -> Double {
    guard let screenPtr else { return 0 }
    let screen = Unmanaged<NSScreen>.fromOpaque(screenPtr).takeUnretainedValue()
    return Double(screen.frame.size.height)
}
