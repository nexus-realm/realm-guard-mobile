//! Pont FFI vers le **pairing d'appareil** du cœur : transfert E2E de la VaultKey
//! d'un appareil source vers un nouvel appareil (X25519 + AEAD + SAS). Opérations
//! légères → fonctions **synchrones**. Le `relay_id` (routage du relais serveur) est
//! une enveloppe **transport** gérée côté Dart ; ici on ne manipule que le payload QR
//! opaque du cœur.

use realm_guard_core::crypto::{pairing_open, pairing_seal, pairing_start};

/// Résultat du démarrage côté **nouvel appareil**.
pub struct PairingStart {
    /// État à conserver (contient le secret éphémère) jusqu'à la réception.
    pub state: Vec<u8>,
    /// Payload QR du cœur (à envelopper côté Dart puis afficher).
    pub qr: Vec<u8>,
}

/// Résultat du scellage côté **appareil source**.
pub struct PairingSealed {
    /// Réponse scellée à déposer au relais.
    pub response: Vec<u8>,
    /// SAS à afficher (doit correspondre à celui du nouvel appareil).
    pub sas: String,
}

/// Résultat de l'ouverture côté **nouvel appareil**.
pub struct PairingOpened {
    /// VaultKey reçue (octets).
    pub vault_key: Vec<u8>,
    /// SAS à afficher (doit correspondre à celui de la source).
    pub sas: String,
}

/// **Nouvel appareil** — démarre le pairing (paire éphémère X25519 + payload QR).
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_new_device_start() -> Result<PairingStart, String> {
    let result = pairing_start().map_err(|e| e.to_string())?;
    Ok(PairingStart {
        state: result.state,
        qr: result.qr,
    })
}

/// **Appareil source** — scelle la VaultKey vers le nouvel appareil décrit par le QR.
/// Renvoie la réponse à déposer + le SAS à afficher.
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_source_seal(qr: Vec<u8>, vault_key: Vec<u8>) -> Result<PairingSealed, String> {
    let result = pairing_seal(&qr, &vault_key).map_err(|e| e.to_string())?;
    Ok(PairingSealed {
        response: result.response,
        sas: result.sas,
    })
}

/// **Nouvel appareil** — ouvre la réponse scellée → VaultKey + SAS. **Échoue** si le
/// blob ne s'ouvre pas (mauvais destinataire / altération).
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_new_device_open(state: Vec<u8>, response: Vec<u8>) -> Result<PairingOpened, String> {
    let result = pairing_open(&state, &response).map_err(|e| e.to_string())?;
    Ok(PairingOpened {
        vault_key: result.vault_key,
        sas: result.sas,
    })
}
