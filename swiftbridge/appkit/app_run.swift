//
//  swift_app_run.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//

import AppKit

// C ABI function called from Rust
@_cdecl("swift_appkit_run")
public func swift_appkit_run(
    _ x: Double,
    _ y: Double,
    _ width: Double,
    _ height: Double,
    _ titlePtr: UnsafePointer<CChar>
) {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)

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

    app.run() // still blocks
}
