use std::{ffi::c_void, os::raw::c_char};

#[repr(C)]
pub struct SwiftNSScreenArrayHeader {
    pub count: i32,
    pub reserved: i32,
    pub items: *const *const c_void,
}

#[link(name = "swiftbridge", kind = "framework")]
unsafe extern "C" {
    // Error reporting (Swift-owned buffer; valid until next call)
    pub fn swiftbridge_last_error() -> *const c_char;
    pub fn swiftbridge_clear_last_error();

    // AppKit
    pub fn swift_appkit_create_app() -> *mut c_void;

    pub fn swift_appkit_create_window(
        x: f64,
        y: f64,
        width: f64,
        height: f64,
        title: *const c_char,
    ) -> *mut c_void;

    pub fn swift_appkit_window_release(window_ptr: *mut c_void);

    pub fn swift_appkit_set_title(window_ptr: *mut c_void, title: *const c_char);

    pub fn swift_appkit_set_location(window_ptr: *mut c_void, x: f64, y: f64);

    pub fn swift_appkit_set_size(window_ptr: *mut c_void, width: f64, height: f64);

    pub fn swift_appkit_run(app_ptr: *mut c_void);

    // NSScreen
    pub fn swift_nsscreen_primary() -> *const c_void;

    /// Returns a pointer to a Swift-owned buffer:
    /// - header (count + items pointer)
    /// - followed by `count` screen pointers (items points to the first one)
    /// Valid until the next call; do not free.
    pub fn swift_nsscreen_get_screen_array() -> *const SwiftNSScreenArrayHeader;

    pub fn swift_nsscreen_width(screen_ptr: *const c_void) -> f64;
    pub fn swift_nsscreen_height(screen_ptr: *const c_void) -> f64;
}
