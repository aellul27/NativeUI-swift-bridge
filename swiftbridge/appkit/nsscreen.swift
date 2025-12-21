//
//  nsscreen.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//

import AppKit
import CoreGraphics

private struct SwiftNSScreenArrayHeader {
    let count: Int32
    let reserved: Int32
    let items: UnsafePointer<UnsafeRawPointer?>?
}

private var gScreenArrayBuffer = ReusableRawBuffer()
private var gScreensStrongRefs: [NSScreen] = []
private var gPrimaryScreenStrongRef: NSScreen? = NSScreen.main

private struct NSScreenArrayViewBuffer {
    let base: UnsafeMutableRawPointer
    let header: UnsafeMutablePointer<SwiftNSScreenArrayHeader>
    let elements: UnsafeMutablePointer<UnsafeRawPointer?>
}

@_cdecl("swift_nsscreen_primary")
public func swift_nsscreen_primary() -> UnsafeRawPointer? {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_nsscreen_primary must be called on the main thread")
        return nil
    }
    guard let screen = NSScreen.main else { return nil }
    gPrimaryScreenStrongRef = screen
    // toOpaque() returns UnsafeMutableRawPointer; convert to UnsafeRawPointer explicitly
    return UnsafeRawPointer(Unmanaged.passUnretained(screen).toOpaque())
}

// Typed wrapper to avoid needing explicit generic specialization at the call site.
// This returns the same tuple shape as `makeArrayView` but with concrete Header/Element types
private func makeNSScreenArrayView(
    count: Int,
    buffer: inout ReusableRawBuffer
) -> NSScreenArrayViewBuffer? {
    guard let view: ArrayView<SwiftNSScreenArrayHeader, UnsafeRawPointer?> = makeArrayView(
        count: count,
        buffer: &buffer
    ) else {
        return nil
    }
    return NSScreenArrayViewBuffer(base: view.base, header: view.header, elements: view.elements)
}

/// Returns a pointer to a Swift-owned buffer containing:
/// - `SwiftNSScreenArrayHeader` (count)
/// - followed by `count` `UnsafeRawPointer?` screen pointers
///
/// The returned pointer remains valid until the next call to this function.
/// The caller must not free it.
@_cdecl("swift_nsscreen_get_screen_array")
public func swift_nsscreen_get_screen_array() -> UnsafeRawPointer? {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_nsscreen_get_screen_array must be called on the main thread")
        return nil
    }
    let screens = NSScreen.screens
    let count = screens.count

    // Keep screens alive until the next call (pointers are unretained/borrowed).
    gScreensStrongRefs = screens

    guard let view = makeNSScreenArrayView(count: count, buffer: &gScreenArrayBuffer) else { return nil }

    view.header.pointee = SwiftNSScreenArrayHeader(
        count: Int32(count),
        reserved: 0,
        items: UnsafePointer(view.elements)
    )
    writeUnretainedObjectPointers(screens, to: view.elements)

    // view.base is UnsafeMutableRawPointer — convert to UnsafeRawPointer for the public API
    return UnsafeRawPointer(view.base)
}

@_cdecl("swift_nsscreen_width")
public func swift_nsscreen_width(_ screenPtr: UnsafeRawPointer?) -> Double {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_nsscreen_width must be called on the main thread")
        return 0
    }
    guard let screenPtr else {
        swiftbridge_set_last_error("swift_nsscreen_width received a null screen pointer")
        return 0
    }
    let screen = Unmanaged<NSScreen>.fromOpaque(screenPtr).takeUnretainedValue()
    return Double(screen.frame.size.width)
}

@_cdecl("swift_nsscreen_height")
public func swift_nsscreen_height(_ screenPtr: UnsafeRawPointer?) -> Double {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_nsscreen_height must be called on the main thread")
        return 0
    }
    guard let screenPtr else {
        swiftbridge_set_last_error("swift_nsscreen_height received a null screen pointer")
        return 0
    }
    let screen = Unmanaged<NSScreen>.fromOpaque(screenPtr).takeUnretainedValue()
    return Double(screen.frame.size.height)
}
