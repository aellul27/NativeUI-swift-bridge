use std::{
    ffi::CString,
    ptr,
};

use crate::{
    error::take_last_error,
    ffi,
};

pub struct SwiftApp {
    app_ptr: *mut std::ffi::c_void,
}

unsafe impl Send for SwiftApp {}
unsafe impl Sync for SwiftApp {}

impl SwiftApp {
    /// Creates the shared NSApplication.
    ///
    /// Note: The Swift implementation requires this be called on the process main thread.
    pub fn new() -> Result<Self, String> {
        let app_ptr = unsafe { ffi::swift_appkit_create_app() };
        if app_ptr.is_null() {
            return Err(take_last_error().unwrap_or_else(|| "swift_appkit_create_app failed".to_string()));
        }
        Ok(Self { app_ptr })
    }

    pub fn as_ptr(&self) -> *mut std::ffi::c_void {
        self.app_ptr
    }

    /// Runs the AppKit event loop (blocking).
    ///
    /// For automated tests, prefer validating error paths (e.g. null pointer) instead.
    pub fn run(&self) {
        unsafe { ffi::swift_appkit_run(self.app_ptr) }
    }

    /// Calls swift_appkit_run with a null pointer to validate error handling.
    pub fn run_with_null_for_test() -> Option<String> {
        unsafe { ffi::swift_appkit_run(ptr::null_mut()) };
        take_last_error()
    }
}

pub struct SwiftWindow {
    window_ptr: *mut std::ffi::c_void,
}

unsafe impl Send for SwiftWindow {}
unsafe impl Sync for SwiftWindow {}

impl SwiftWindow {
    pub fn new(x: f64, y: f64, width: f64, height: f64, title: &str) -> Result<Self, String> {
        let c_title = CString::new(title).map_err(|_| "Window title contained NUL".to_string())?;
        let window_ptr = unsafe { ffi::swift_appkit_create_window(x, y, width, height, c_title.as_ptr()) };
        if window_ptr.is_null() {
            return Err(take_last_error().unwrap_or_else(|| "swift_appkit_create_window failed".to_string()));
        }
        Ok(Self { window_ptr })
    }

    pub fn as_ptr(&self) -> *mut std::ffi::c_void {
        self.window_ptr
    }
}

impl Drop for SwiftWindow {
    fn drop(&mut self) {
        if !self.window_ptr.is_null() {
            unsafe { ffi::swift_window_release(self.window_ptr) };
            self.window_ptr = std::ptr::null_mut();
        }
    }
}
