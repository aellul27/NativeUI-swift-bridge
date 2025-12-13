# rustbridge_tests

Rust-side example + thorough(ish) FFI exercise for the Swift `swiftbridge.framework`.

Why this is a custom runner (not `cargo test`):
- Several Swift APIs enforce `Thread.isMainThread` (e.g. `swift_appkit_create_app`, `swift_appkit_run`, `swift_nsscreen_*`).
- The default Rust test harness executes tests on worker threads, so it would trip main-thread checks.

## Prereqs

By default, Cargo will invoke `xcodebuild` via `build.rs` to build `swiftbridge.framework`.

Requirements:
- Xcode + command line tools installed (`xcodebuild` available).

## Run

From repo root:

```sh
cd swiftbridgeTests/rustbridge_tests
cargo run --bin run_all
```

If you want to skip `xcodebuild` and point at an existing build, set the directory that *contains* `swiftbridge.framework`:

```sh
SWIFTBRIDGE_FRAMEWORK_DIR="$PWD/../../build/Debug" cargo run --bin run_all
```

To control the Xcode build used by `build.rs`:

```sh
SWIFTBRIDGE_XCODE_SCHEME=swiftbridge SWIFTBRIDGE_XCODE_CONFIGURATION=Debug cargo run --bin run_all
```

If your system refuses to load the framework at runtime, you can also set:

```sh
DYLD_FRAMEWORK_PATH="$PWD/../../build/Debug" cargo run --bin run_all
```
