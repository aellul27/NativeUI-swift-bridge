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
    _ titlePtr: UnsafePointer<CChar>
) -> UnsafeMutableRawPointer? {
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

    // Note: Do not call app.run() here—let the caller run the app event loop
    return Unmanaged.passUnretained(window).toOpaque()
}

// C ABI function to run the AppKit event loop using the provided app pointer
@_cdecl("swift_appkit_run")
public func swift_appkit_run(_ appPtr: UnsafeRawPointer?) {
    guard let appPtr = appPtr else { return }
    let app = Unmanaged<NSApplication>.fromOpaque(appPtr).takeUnretainedValue()

    app.activate(ignoringOtherApps: true)
    app.run()
}
