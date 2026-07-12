//! Pont FFI vers l'enrobage de la **VaultKey sous la clé exportée OPAQUE**.
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
use realm_guard_core::crypto::{open_with_export_key, seal_with_export_key, Ciphertext};

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
