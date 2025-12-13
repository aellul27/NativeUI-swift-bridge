//
//  File.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//


import AppKit

@_cdecl("swift_set_title")
public func swift_set_title(title: UnsafePointer<CChar>) {
    let t = String(cString: title)
    DispatchQueue.main.async {
        NSApp.windows.first?.title = t
    }
}
