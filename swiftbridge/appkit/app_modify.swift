//
//  File.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//


import AppKit

@_cdecl("swift_appkit_set_title")
public func swift_set_title(window_ptr: UnsafeMutableRawPointer?, title: UnsafePointer<CChar>?) {
    guard let window_ptr else {
        swiftbridge_set_last_error("swift_set_title received a null window pointer")
        return
    }
    guard let title else {
        swiftbridge_set_last_error("swift_set_title received a null title pointer")
        return
    }
    let t = String(cString: title)
    DispatchQueue.main.async {
        let window = Unmanaged<NSWindow>.fromOpaque(window_ptr).takeUnretainedValue()
        window.title = t
    }
}

@_cdecl("swift_appkit_set_location")
public func swift_set_location(
    _ window_ptr: UnsafeMutableRawPointer?,
    _ x: Double,
    _ y: Double
) {
    guard let window_ptr else {
        swiftbridge_set_last_error("swift_set_location received a null window pointer")
        return
    }
    DispatchQueue.main.async {
        let newOrigin = NSPoint(x: x, y: y)
        let window = Unmanaged<NSWindow>.fromOpaque(window_ptr).takeUnretainedValue()
        window.setFrameOrigin(newOrigin)
    }
}
