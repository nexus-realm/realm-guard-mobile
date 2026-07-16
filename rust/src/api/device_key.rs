//! Pont FFI vers les **clés d'identité d'appareil** (Ed25519) du cœur.
//!
//! Le nouvel appareil génère sa paire **localement** : la graine secrète est renvoyée
//! à Dart pour être persistée en **secure storage** et ne quitte jamais l'appareil ;
//! seule la clé publique voyage (QR, puis registre du compte). La signature du défi
//! d'authentification se fait ici. Opérations légères → fonctions **synchrones**.

use realm_guard_core::crypto::{device_sign, generate_device_keypair};

/// Paire de clés d'identité d'appareil.
pub struct DeviceKeypair {
    /// Clé publique (32 o) — placée dans le QR puis inscrite au registre du compte.
    pub public: Vec<u8>,
    /// Graine secrète (32 o) — à persister en secure storage, jamais transmise.
    pub secret: Vec<u8>,
}

/// Génère la paire de clés d'identité de cet appareil.
#[flutter_rust_bridge::frb(sync)]
pub fn device_generate_keypair() -> Result<DeviceKeypair, String> {
    let keypair = generate_device_keypair().map_err(|e| e.to_string())?;
    Ok(DeviceKeypair {
        public: keypair.public,
        secret: keypair.secret,
    })
}

/// Signe un défi (nonce serveur) avec la graine secrète de cet appareil.
#[flutter_rust_bridge::frb(sync)]
pub fn device_sign_challenge(secret: Vec<u8>, challenge: Vec<u8>) -> Result<Vec<u8>, String> {
    device_sign(&secret, &challenge).map_err(|e| e.to_string())
}
