/// Version du cœur `realm-guard-core`, exposée via FFI.
/// Sert de point de validation de l'intégration Rust ↔ Flutter (P0.5).
#[flutter_rust_bridge::frb(sync)]
pub fn core_version() -> String {
    realm_guard_core::core_version().to_string()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
