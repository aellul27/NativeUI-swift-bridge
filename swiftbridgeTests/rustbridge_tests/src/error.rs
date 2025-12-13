use std::{
    ffi::CStr,
    os::raw::c_char,
};

use crate::ffi;

/// Fetches the last Swift bridge error message (if any) and clears it.
pub fn take_last_error() -> Option<String> {
    let ptr = unsafe { ffi::swiftbridge_last_error() };
    if ptr.is_null() {
        return None;
    }

    let msg = unsafe { CStr::from_ptr(ptr as *const c_char) }
        .to_string_lossy()
        .into_owned();

    unsafe { ffi::swiftbridge_clear_last_error() };

    Some(msg)
}

/// Clears any existing Swift bridge error.
pub fn clear_last_error() {
    unsafe { ffi::swiftbridge_clear_last_error() }
}
