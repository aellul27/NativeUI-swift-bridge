//
//  File.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//

import AppKit

private func windowFromPointer(_ pointer: UnsafeRawPointer, caller: String) -> NSWindow? {
    let matchesPointer: (NSWindow) -> Bool = {
        UnsafeRawPointer(Unmanaged.passUnretained($0).toOpaque()) == pointer
    }

    guard let window = NSApplication.shared.windows.first(where: matchesPointer) else {
        swiftbridge_set_last_error("\(caller) received an unknown window pointer")
        return nil
    }
    return window
}

@_cdecl("swift_appkit_set_title")
public func swift_appkit_set_title(windowPtr: UnsafeRawPointer?, title: UnsafePointer<CChar>?) {
    guard let windowPtr else {
        swiftbridge_set_last_error("swift_appkit_set_title received a null window pointer")
        return
    }
    guard let title else {
        swiftbridge_set_last_error("swift_appkit_set_title received a null title pointer")
        return
    }
    let titleString = String(cString: title)

    if Thread.isMainThread {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_title") else {
            return
        }
        window.title = titleString
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_title") else {
            return
        }
        window.title = titleString
    }
}

@_cdecl("swift_appkit_set_location")
public func swift_appkit_set_location(
    _ windowPtr: UnsafeRawPointer?,
    _ originX: Double,
    _ originY: Double
) {
    guard let windowPtr else {
        swiftbridge_set_last_error("swift_appkit_set_location received a null window pointer")
        return
    }

    if Thread.isMainThread {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_location") else {
            return
        }
        let newOrigin = NSPoint(x: originX, y: originY)
        window.setFrameOrigin(newOrigin)
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_location") else {
            return
        }
        let newOrigin = NSPoint(x: originX, y: originY)
        window.setFrameOrigin(newOrigin)
    }
}

@_cdecl("swift_appkit_set_size")
public func swift_appkit_set_size(
    _ windowPtr: UnsafeRawPointer?,
    _ width: Double,
    _ height: Double
) {
    guard let windowPtr else {
        swiftbridge_set_last_error("swift_appkit_set_size received a null window pointer")
        return
    }

    if Thread.isMainThread {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_size") else {
            return
        }
        var frame = window.frame
        frame.size = NSSize(width: width, height: height)
        window.setFrame(frame, display: true)
        return
    }

    DispatchQueue.main.async {
        guard let window = windowFromPointer(windowPtr, caller: "swift_appkit_set_size") else {
            return
        }
        var frame = window.frame
        frame.size = NSSize(width: width, height: height)
        window.setFrame(frame, display: true)
    }
}
