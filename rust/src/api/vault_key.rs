//! Pont FFI pour la **VaultKey** — enrobage **local** (sous la KEK, déverrouillage
//! du coffre) et **serveur** (sous la clé exportée OPAQUE, stockage multi-appareils).
//!
//! La VaultKey est déjà enrobée localement par la KEK (dérivée du mot de passe via
//! Argon2id). Pour le stockage serveur (multi-appareils), ce blob est **ré-enrobé**
//! sous une clé dérivée de l'`export_key` OPAQUE — défense en profondeur : sans
//! rejouer OPAQUE (donc sans le mot de passe), le blob stocké est inutilisable.
//!
//! Le [`Ciphertext`] est sérialisé (postcard, codec partagé du cœur) → le Dart ne
//! manipule que des **octets opaques** (le `wrapped_key` téléversé tel quel). Ces
//! opérations (HKDF + AEAD sur ~32 o) sont légères : fonctions **synchrones**.

use realm_guard_core::codec;
use realm_guard_core::crypto::{
    generate_vault_key_bytes, open_with_export_key, seal_with_export_key, unwrap_vault_key_bytes,
    wrap_vault_key_bytes, Ciphertext,
};

/// Enrobe la VaultKey (déjà enrobée par la KEK) sous la clé exportée OPAQUE.
///
/// `wrapped_vault_key` = état local (VaultKey enrobée par la KEK). Renvoie le blob
/// sérialisé à téléverser au serveur (`PUT /vault/key`).
#[flutter_rust_bridge::frb(sync)]
pub fn seal_vault_key(export_key: Vec<u8>, wrapped_vault_key: Vec<u8>) -> Result<Vec<u8>, String> {
    let sealed =
        seal_with_export_key(&export_key, &wrapped_vault_key).map_err(|e| e.to_string())?;
    codec::encode(&sealed).map_err(|e| e.to_string())
}

/// Désenrobe le blob serveur avec la clé exportée OPAQUE.
///
/// `sealed` = blob récupéré du serveur (`GET /vault/key`). Renvoie la VaultKey
/// enrobée par la KEK (état local). **Échoue** si l'`export_key` ne correspond pas
/// (mauvais mot de passe re-dérivé) ou si le blob a été altéré.
#[flutter_rust_bridge::frb(sync)]
pub fn open_vault_key(export_key: Vec<u8>, sealed: Vec<u8>) -> Result<Vec<u8>, String> {
    let ciphertext: Ciphertext = codec::decode(&sealed).map_err(|e| e.to_string())?;
    open_with_export_key(&export_key, &ciphertext).map_err(|e| e.to_string())
}

/// Génère une **VaultKey** aléatoire (32 octets) — la clé racine du coffre local.
#[flutter_rust_bridge::frb(sync)]
pub fn generate_vault_key() -> Result<Vec<u8>, String> {
    generate_vault_key_bytes().map_err(|e| e.to_string())
}

/// Enrobe la VaultKey sous la **KEK** (dérivée du mot de passe maître) pour le
/// stockage **local**. Renvoie le blob sérialisé (postcard).
#[flutter_rust_bridge::frb(sync)]
pub fn wrap_vault_key(kek: Vec<u8>, vault_key: Vec<u8>) -> Result<Vec<u8>, String> {
    let wrapped = wrap_vault_key_bytes(&kek, &vault_key).map_err(|e| e.to_string())?;
    codec::encode(&wrapped).map_err(|e| e.to_string())
}

/// Désenrobe la VaultKey locale avec la KEK. **Échoue** si la KEK est fausse
/// (mauvais mot de passe) ou si le blob a été altéré.
#[flutter_rust_bridge::frb(sync)]
pub fn unwrap_vault_key(kek: Vec<u8>, wrapped: Vec<u8>) -> Result<Vec<u8>, String> {
    let ciphertext: Ciphertext = codec::decode(&wrapped).map_err(|e| e.to_string())?;
    unwrap_vault_key_bytes(&kek, &ciphertext).map_err(|e| e.to_string())
}
