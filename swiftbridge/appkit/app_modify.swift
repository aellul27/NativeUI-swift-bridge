//
//  File.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//


import AppKit

private func windowFromPointer(_ pointer: UnsafeMutableRawPointer, caller: String) -> NSWindow? {
    guard let window = NSApplication.shared.windows.first(where: { Unmanaged.passUnretained($0).toOpaque() == pointer }) else {
        swiftbridge_set_last_error("\(caller) received an unknown window pointer")
        return nil
    }
    return window
}

@_cdecl("swift_appkit_set_title")
public func swift_appkit_set_title(window_ptr: UnsafeMutableRawPointer?, title: UnsafePointer<CChar>?) {
    guard let window_ptr else {
        swiftbridge_set_last_error("swift_appkit_set_title received a null window pointer")
        return
    }
    guard let title else {
        swiftbridge_set_last_error("swift_appkit_set_title received a null title pointer")
        return
    }
    let t = String(cString: title)

    if Thread.isMainThread {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_title") else {
            return
        }
        window.title = t
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_title") else {
            return
        }
        window.title = t
    }
}

@_cdecl("swift_appkit_set_location")
public func swift_appkit_set_location(
    _ window_ptr: UnsafeMutableRawPointer?,
    _ x: Double,
    _ y: Double
) {
    guard let window_ptr else {
        swiftbridge_set_last_error("swift_appkit_set_location received a null window pointer")
        return
    }

    if Thread.isMainThread {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_location") else {
            return
        }
        let newOrigin = NSPoint(x: x, y: y)
        window.setFrameOrigin(newOrigin)
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_location") else {
            return
        }
        let newOrigin = NSPoint(x: x, y: y)
        window.setFrameOrigin(newOrigin)
    }
}

@_cdecl("swift_appkit_set_size")
public func swift_appkit_set_size(
    _ window_ptr: UnsafeMutableRawPointer?,
    _ width: Double,
    _ height: Double
) {
    guard let window_ptr else {
        swiftbridge_set_last_error("swift_appkit_set_size received a null window pointer")
        return
    }

    if Thread.isMainThread {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_size") else {
            return
        }
        var frame = window.frame
        frame.size = NSSize(width: width, height: height)
        window.setFrame(frame, display: true)
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(window_ptr, caller: "swift_appkit_set_size") else {
            return
        }
        var frame = window.frame
        frame.size = NSSize(width: width, height: height)
        window.setFrame(frame, display: true)
    }
}
