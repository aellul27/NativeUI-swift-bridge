use crate::{
    error::take_last_error,
    ffi::{self, SwiftNSScreenArrayHeader},
};

#[derive(Clone, Copy, Debug)]
pub struct ScreenPtr(pub *const std::ffi::c_void);

pub fn primary() -> Result<Option<ScreenPtr>, String> {
    let ptr = unsafe { ffi::swift_nsscreen_primary() };
    if ptr.is_null() {
        if let Some(err) = take_last_error() {
            return Err(err);
        }
        return Ok(None);
    }
    Ok(Some(ScreenPtr(ptr)))
}

/// Returns a borrowed slice of screen pointers.
///
/// Safety/lifetime:
/// - The returned slice points into a Swift-owned buffer.
/// - It is only valid until the next call to `get_screen_array`.
/// - Do not store it.
pub unsafe fn get_screen_array_borrowed() -> Result<&'static [ScreenPtr], String> {
    let header_ptr = ffi::swift_nsscreen_get_screen_array();
    if header_ptr.is_null() {
        return Err(take_last_error().unwrap_or_else(|| "swift_nsscreen_get_screen_array failed".to_string()));
    }

    let header: &SwiftNSScreenArrayHeader = &*header_ptr;
    if header.count < 0 {
        return Err("swift_nsscreen_get_screen_array returned negative count".to_string());
    }
    if header.count == 0 {
        return Ok(&[]);
    }
    if header.items.is_null() {
        return Err("swift_nsscreen_get_screen_array returned null items with count>0".to_string());
    }

    let raw = std::slice::from_raw_parts(header.items, header.count as usize);
    let screens: Vec<ScreenPtr> = raw.iter().map(|p| ScreenPtr(*p as *const _)).collect();

    // We must return a slice that lives long enough for our caller to inspect synchronously.
    // Since the underlying buffer is Swift-owned and only valid until next call, we expose
    // a copied Vec-backed slice by leaking it for the duration of the process.
    // This is acceptable for a small test runner.
    Ok(Box::leak(screens.into_boxed_slice()))
}

pub fn width(screen: ScreenPtr) -> Result<f64, String> {
    let w = unsafe { ffi::swift_nsscreen_width(screen.0) };
    if w == 0.0 {
        if let Some(err) = take_last_error() {
            return Err(err);
        }
    }
    Ok(w)
}

pub fn height(screen: ScreenPtr) -> Result<f64, String> {
    let h = unsafe { ffi::swift_nsscreen_height(screen.0) };
    if h == 0.0 {
        if let Some(err) = take_last_error() {
            return Err(err);
        }
    }
    Ok(h)
}
