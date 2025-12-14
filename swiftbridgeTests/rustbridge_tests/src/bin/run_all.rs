use std::{
    thread,
    time::Duration,
};

use rustbridge_tests::{
    appkit::{
        app_modify,
        app_run::{SwiftApp, SwiftWindow},
        nsscreen,
    },
    error::{clear_last_error, take_last_error},
};

fn assert_ok(name: &str, ok: bool) {
    if !ok {
        eprintln!("FAIL: {name}");
        std::process::exit(1);
    }
}

fn assert_contains(name: &str, haystack: &str, needle: &str) {
    if !haystack.contains(needle) {
        eprintln!("FAIL: {name}: expected '{needle}' in '{haystack}'");
        std::process::exit(1);
    }
}

fn main() {
    // This binary runs on the process main thread.
    // That matters because several Swift functions enforce main-thread usage.

    clear_last_error();

    // 1) Error buffer basics
    assert_ok("initial last_error is None", take_last_error().is_none());

    // 2) swift_appkit_create_app: success on main thread
    let _app = SwiftApp::new().unwrap_or_else(|e| {
        eprintln!("FAIL: SwiftApp::new on main thread: {e}");
        std::process::exit(1);
    });

    // 3) swift_appkit_create_app: fails off main thread
    let err = thread::spawn(|| {
        clear_last_error();
        SwiftApp::new().err().unwrap_or_else(|| "expected error".to_string())
    })
    .join()
    .expect("join");
    assert_contains("create_app off-main error", &err, "main thread");

    // 4) NSScreen APIs: success on main thread
    match nsscreen::primary() {
        Ok(Some(screen)) => {
            let w = nsscreen::width(screen).unwrap_or_else(|e| {
                eprintln!("FAIL: nsscreen width: {e}");
                std::process::exit(1);
            });
            let h = nsscreen::height(screen).unwrap_or_else(|e| {
                eprintln!("FAIL: nsscreen height: {e}");
                std::process::exit(1);
            });
            assert_ok("primary screen width>0", w > 0.0);
            assert_ok("primary screen height>0", h > 0.0);
        }
        Ok(None) => {
            // Acceptable on headless systems; just ensure we didn't set an error.
            assert_ok("primary screen none without error", take_last_error().is_none());
        }
        Err(e) => {
            eprintln!("FAIL: nsscreen primary on main thread: {e}");
            std::process::exit(1);
        }
    }

    // 5) NSScreen array: success on main thread
    unsafe {
        let screens = nsscreen::get_screen_array_borrowed().unwrap_or_else(|e| {
            eprintln!("FAIL: get_screen_array: {e}");
            std::process::exit(1);
        });
        if let Some(first) = screens.first().copied() {
            let w = nsscreen::width(first).unwrap();
            let h = nsscreen::height(first).unwrap();
            assert_ok("screen[0] width>0", w > 0.0);
            assert_ok("screen[0] height>0", h > 0.0);
        }
    }

    // 6) NSScreen APIs: fail off main thread
    let err = thread::spawn(|| {
        clear_last_error();
        // calling primary off-main should return an error (the wrapper also consumes last_error)
        nsscreen::primary()
            .err()
            .unwrap_or_else(|| "expected error".to_string())
    })
    .join()
    .expect("join");
    assert_contains("nsscreen_primary off-main error", &err, "main thread");

    // 7) Window lifecycle + modification
    let window = SwiftWindow::new(300.0, 300.0, 300.0, 200.0, "Rust bridge tests").unwrap_or_else(|e| {
        eprintln!("FAIL: create_window: {e}");
        std::process::exit(1);
    });

    // Success paths: should not set last_error. These are async on Swift side.
    app_modify::set_title(window.as_ptr(), "Updated title").unwrap_or_else(|e| {
        eprintln!("FAIL: set_title: {e}");
        std::process::exit(1);
    });
    app_modify::set_location(window.as_ptr(), 10.0, 10.0).unwrap_or_else(|e| {
        eprintln!("FAIL: set_location: {e}");
        std::process::exit(1);
    });

    // Error paths: null window pointer
    clear_last_error();
    let err = app_modify::set_title(std::ptr::null_mut(), "x").err().unwrap();
    assert_contains("set_title null window", &err, "null window pointer");

    clear_last_error();
    let err = app_modify::set_location(std::ptr::null_mut(), 0.0, 0.0).err().unwrap();
    assert_contains("set_location null window", &err, "null window pointer");

    // 8) swift_appkit_run error path (null)
    let err = SwiftApp::run_with_null_for_test().unwrap_or_else(|| "expected error".to_string());
    assert_contains("appkit_run null ptr", &err, "null app pointer");

    // Give the main queue a moment to process the async title/location calls.
    thread::sleep(Duration::from_millis(50));

    println!("OK: rustbridge_tests run_all completed");
}
