use std::{
    env,
    path::{Path, PathBuf},
    process::Command,
};

fn repo_root_from_manifest(manifest_dir: &Path) -> PathBuf {
    // swiftbridgeTests/rustbridge_tests -> repo_root is ../../
    manifest_dir
        .parent()
        .and_then(|p| p.parent())
        .expect("Expected rustbridge_tests to be located at swiftbridgeTests/rustbridge_tests")
        .to_path_buf()
}

fn run(cmd: &mut Command) {
    let status = cmd.status().expect("failed to spawn process");
    if !status.success() {
        panic!("Command failed: {cmd:?}");
    }
}

fn xcode_configuration() -> String {
    env::var("SWIFTBRIDGE_XCODE_CONFIGURATION").unwrap_or_else(|_| "Debug".to_string())
}

fn xcode_scheme() -> String {
    env::var("SWIFTBRIDGE_XCODE_SCHEME").unwrap_or_else(|_| "swiftbridge".to_string())
}

fn xcode_project_path(repo_root: &Path) -> PathBuf {
    repo_root.join("swiftbridge.xcodeproj")
}

fn build_swiftbridge_framework(repo_root: &Path, derived_data: &Path) {
    let project = xcode_project_path(repo_root);
    if !project.exists() {
        panic!("Missing Xcode project at {project:?}");
    }

    // Build the framework.
    let mut cmd = Command::new("xcodebuild");
    cmd.arg("-project")
        .arg(project)
        .arg("-scheme")
        .arg(xcode_scheme())
        .arg("-configuration")
        .arg(xcode_configuration())
        .arg("-sdk")
        .arg("macosx")
        .arg("-derivedDataPath")
        .arg(derived_data)
        .arg("build")
        .current_dir(repo_root);
    run(&mut cmd);
}

fn parse_build_setting(output: &str, key: &str) -> Option<String> {
    // Typical line: "    CONFIGURATION_BUILD_DIR = /path/to/Build/Products/Debug"
    for line in output.lines() {
        let trimmed = line.trim_start();
        if let Some(rest) = trimmed.strip_prefix(key) {
            let rest = rest.trim_start();
            if let Some(rest) = rest.strip_prefix('=') {
                return Some(rest.trim().to_string());
            }
        }
    }
    None
}

fn resolve_framework_dir_via_xcode(repo_root: &Path, derived_data: &Path) -> PathBuf {
    let project = xcode_project_path(repo_root);

    let output = Command::new("xcodebuild")
        .arg("-project")
        .arg(project)
        .arg("-scheme")
        .arg(xcode_scheme())
        .arg("-configuration")
        .arg(xcode_configuration())
        .arg("-sdk")
        .arg("macosx")
        .arg("-derivedDataPath")
        .arg(derived_data)
        .arg("-showBuildSettings")
        .current_dir(repo_root)
        .output()
        .expect("failed to run xcodebuild -showBuildSettings");

    if !output.status.success() {
        panic!(
            "xcodebuild -showBuildSettings failed. stdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let build_dir = parse_build_setting(&stdout, "CONFIGURATION_BUILD_DIR")
        .or_else(|| parse_build_setting(&stdout, "BUILT_PRODUCTS_DIR"))
        .unwrap_or_else(|| {
            panic!(
                "Could not locate CONFIGURATION_BUILD_DIR/BUILT_PRODUCTS_DIR in xcodebuild output:\n{stdout}"
            )
        });

    PathBuf::from(build_dir)
}

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"));
    let repo_root = repo_root_from_manifest(&manifest_dir);

    // Re-run if any of the Swift sources or project settings change.
    println!("cargo:rerun-if-changed={}", repo_root.join("swiftbridge.xcodeproj").join("project.pbxproj").display());
    println!("cargo:rerun-if-changed={}", repo_root.join("swiftbridge").display());

    // Allow overriding the framework search directory.
    // Should point to a directory containing swiftbridge.framework.
    if let Ok(dir) = env::var("SWIFTBRIDGE_FRAMEWORK_DIR") {
        let p = PathBuf::from(dir);
        if !p.join("swiftbridge.framework").is_dir() {
            panic!("SWIFTBRIDGE_FRAMEWORK_DIR does not contain swiftbridge.framework: {p:?}");
        }
        println!("cargo:rustc-link-search=framework={}", p.display());
        println!("cargo:rustc-link-lib=framework=swiftbridge");
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}", p.display());
        println!("cargo:rerun-if-env-changed=SWIFTBRIDGE_FRAMEWORK_DIR");
        return;
    }

    // Build the Xcode project and discover the output directory from build settings.
    let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
    let derived_data = out_dir.join("swiftbridge_xcode_deriveddata");

    build_swiftbridge_framework(&repo_root, &derived_data);
    let framework_dir = resolve_framework_dir_via_xcode(&repo_root, &derived_data);

    if !framework_dir.join("swiftbridge.framework").is_dir() {
        panic!(
            "Xcode build succeeded but swiftbridge.framework was not found at {}/swiftbridge.framework",
            framework_dir.display()
        );
    }

    println!("cargo:rustc-link-search=framework={}", framework_dir.display());
    println!("cargo:rustc-link-lib=framework=swiftbridge");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", framework_dir.display());

    println!("cargo:rerun-if-env-changed=SWIFTBRIDGE_XCODE_CONFIGURATION");
    println!("cargo:rerun-if-env-changed=SWIFTBRIDGE_XCODE_SCHEME");
}
