use std::ffi::CString;

use crate::{
    error::take_last_error,
    ffi,
};

pub fn set_title(window_ptr: *mut std::ffi::c_void, title: &str) -> Result<(), String> {
    let c_title = CString::new(title).map_err(|_| "Title contained NUL".to_string())?;
    unsafe { ffi::swift_set_title(window_ptr, c_title.as_ptr()) };

    if let Some(err) = take_last_error() {
        // The Swift side records errors for null pointers; otherwise title is async.
        return Err(err);
    }
    Ok(())
}

pub fn set_location(window_ptr: *mut std::ffi::c_void, x: f64, y: f64) -> Result<(), String> {
    unsafe { ffi::swift_set_location(window_ptr, x, y) };

    if let Some(err) = take_last_error() {
        return Err(err);
    }
    Ok(())
}
