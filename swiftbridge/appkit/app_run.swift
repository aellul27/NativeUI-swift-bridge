//
//  swift_app_run.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//

import AppKit

// C ABI function to get a pointer to the shared NSApplication
@_cdecl("swift_appkit_create_app")
public func swift_appkit_create_app() -> UnsafeMutableRawPointer? {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_appkit_create_app must be called on the main thread")
        return nil
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    return Unmanaged.passUnretained(app).toOpaque()
}

// C ABI function to create a window using the provided app pointer
@_cdecl("swift_appkit_create_window")
public func swift_appkit_create_window(
    _ x: Double,
    _ y: Double,
    _ width: Double,
    _ height: Double,
    _ titlePtr: UnsafePointer<CChar>?
) -> UnsafeMutableRawPointer? {
    guard let titlePtr else {
        swiftbridge_set_last_error("swift_appkit_create_window received a null title pointer")
        return nil
    }

    let makeWindow: () -> UnsafeMutableRawPointer? = {
        let title = String(cString: titlePtr)

        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = title
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Keep the window alive across the FFI boundary.
        return Unmanaged.passRetained(window).toOpaque()
    }

    if Thread.isMainThread {
        return makeWindow()
    }
    var result: UnsafeMutableRawPointer?
    DispatchQueue.main.sync {
        result = makeWindow()
    }
    return result
}

// C ABI function to run the AppKit event loop using the provided app pointer
@_cdecl("swift_appkit_run")
public func swift_appkit_run(_ appPtr: UnsafeRawPointer?) {
    guard Thread.isMainThread else {
        swiftbridge_set_last_error("swift_appkit_run must be called on the main thread")
        return
    }
    guard let appPtr = appPtr else {
        swiftbridge_set_last_error("swift_appkit_run received a null app pointer")
        return
    }
    let app = Unmanaged<NSApplication>.fromOpaque(appPtr).takeUnretainedValue()

    app.activate(ignoringOtherApps: true)
    app.run()
}

@_cdecl("swift_appkit_window_release")
public func swift_appkit_window_release(_ windowPtr: UnsafeMutableRawPointer?) {
    guard let windowPtr else { return }
    Unmanaged<NSWindow>.fromOpaque(windowPtr).release()
}
