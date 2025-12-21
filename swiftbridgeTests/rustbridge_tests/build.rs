use std::{
    env,
    fs,
    path::{Path, PathBuf},
    process::Command,
};

fn repo_root_from_manifest(manifest_dir: &Path) -> PathBuf {
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
    env::var("SWIFTBRIDGE_XCODE_CONFIGURATION").unwrap_or_else(|_| "Release".to_string())
}

fn xcode_project_path(repo_root: &Path) -> PathBuf {
    repo_root.join("swiftbridge.xcodeproj")
}

fn build_and_copy_framework(repo_root: &Path, out_dir: &Path) -> PathBuf {
    let project = xcode_project_path(repo_root);
    if !project.exists() {
        panic!("Missing Xcode project at {project:?}");
    }

    // Build the project.
    let mut build_cmd = Command::new("xcodebuild");
    build_cmd
        .arg("-project")
        .arg(&project)
        .arg("-configuration")
        .arg(xcode_configuration())
        .arg("build")
        .current_dir(repo_root);
    run(&mut build_cmd);

    // Copy the framework from build/<CONFIGURATION>/swiftbridge.framework
    let framework_src = repo_root.join("build").join(xcode_configuration()).join("swiftbridge.framework");
    if !framework_src.is_dir() {
        panic!("Expected framework not found at {framework_src:?}");
    }

    let framework_dst = out_dir.join("swiftbridge.framework");
    if framework_dst.exists() {
        fs::remove_dir_all(&framework_dst).unwrap();
    }
    fs::create_dir_all(out_dir).unwrap();
    fs::rename(&framework_src, &framework_dst).expect("Failed to copy framework");

    // Delete the build directory
    let build_dir = repo_root.join("build");
    if build_dir.exists() {
        fs::remove_dir_all(&build_dir).expect("Failed to remove build directory");
    }

    framework_dst
}

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"));
    let repo_root = repo_root_from_manifest(&manifest_dir);

    println!("cargo:rerun-if-changed={}", repo_root.join("swiftbridge.xcodeproj").join("project.pbxproj").display());
    println!("cargo:rerun-if-changed={}", repo_root.join("swiftbridge").display());

    let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
    let framework_dir = build_and_copy_framework(&repo_root, &out_dir);

    println!("cargo:rustc-link-search=framework={}", framework_dir.parent().unwrap().display());
    println!("cargo:rustc-link-lib=framework=swiftbridge");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", framework_dir.parent().unwrap().display());
}
