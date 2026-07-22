//! Pont FFI vers le **pairing d'appareil** du cœur : transfert E2E de la VaultKey
//! d'un appareil source vers un nouvel appareil (X25519 + AEAD + SAS), en **deux
//! tours** — la VaultKey ne part qu'après confirmation du SAS. Opérations légères →
//! fonctions **synchrones**. Le `relay_id` (routage du relais serveur) est une
//! enveloppe **transport** gérée côté Dart ; ici on ne manipule que les payloads
//! opaques du cœur.

use realm_guard_core::crypto::{
    pairing_new_device_confirm, pairing_open, pairing_source_begin, pairing_source_seal,
    pairing_start,
};

/// Résultat du démarrage côté **nouvel appareil**.
pub struct PairingStart {
    /// État à conserver (contient le secret éphémère) jusqu'au tour 1.
    pub state: Vec<u8>,
    /// Payload QR du cœur (à envelopper côté Dart puis afficher).
    pub qr: Vec<u8>,
}

/// Résultat du **tour 1** côté appareil source.
pub struct PairingSourceBegin {
    /// État à conserver jusqu'au scellage (contient la clé AEAD dérivée).
    pub state: Vec<u8>,
    /// Tour 1 à déposer au relais : la clé publique éphémère seule (aucun secret).
    pub hello: Vec<u8>,
    /// SAS à afficher. **Ne sceller qu'après** confirmation par l'utilisateur.
    pub sas: String,
    /// Clé d'identité du nouvel appareil, extraite du QR (liée au transcript). À
    /// inscrire au registre **uniquement après** confirmation du SAS.
    pub device_public_key: Vec<u8>,
}

/// Résultat du **tour 1** côté nouvel appareil.
pub struct PairingConfirm {
    /// État à conserver jusqu'à l'ouverture (contient la clé AEAD dérivée).
    pub state: Vec<u8>,
    /// SAS à afficher (doit correspondre à celui de la source).
    pub sas: String,
}

/// Résultat de l'ouverture (**tour 2**) côté nouvel appareil.
pub struct PairingOpened {
    /// VaultKey reçue (octets).
    pub vault_key: Vec<u8>,
    /// Identifiant du compte que le nouvel appareil rejoint.
    pub account_id: Vec<u8>,
}

/// **Nouvel appareil** — démarre le pairing (paire éphémère X25519 + payload QR), en
/// incorporant sa clé d'identité `device_public_key` au QR et à l'état.
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_new_device_start(device_public_key: Vec<u8>) -> Result<PairingStart, String> {
    let result = pairing_start(&device_public_key).map_err(|e| e.to_string())?;
    Ok(PairingStart {
        state: result.state,
        qr: result.qr,
    })
}

/// **Appareil source, tour 1** — scanne le QR et dérive le SAS. Ne publie que sa clé
/// publique : **aucun secret ne circule** tant que le SAS n'est pas confirmé.
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_source_begin_round(qr: Vec<u8>) -> Result<PairingSourceBegin, String> {
    let result = pairing_source_begin(&qr).map_err(|e| e.to_string())?;
    Ok(PairingSourceBegin {
        state: result.state,
        hello: result.hello,
        sas: result.sas,
        device_public_key: result.device_public_key,
    })
}

/// **Nouvel appareil, tour 1** — reçoit la clé publique de la source et dérive le SAS
/// à comparer.
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_new_device_confirm_round(
    state: Vec<u8>,
    hello: Vec<u8>,
) -> Result<PairingConfirm, String> {
    let result = pairing_new_device_confirm(&state, &hello).map_err(|e| e.to_string())?;
    Ok(PairingConfirm {
        state: result.state,
        sas: result.sas,
    })
}

/// **Appareil source, tour 2** — scelle `{account_id, vault_key}`.
///
/// À n'appeler qu'**après** confirmation du SAS par l'utilisateur : c'est ce qui
/// empêche un MITM d'obtenir la VaultKey.
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_source_seal_round(
    state: Vec<u8>,
    account_id: Vec<u8>,
    vault_key: Vec<u8>,
) -> Result<Vec<u8>, String> {
    pairing_source_seal(&state, &account_id, &vault_key).map_err(|e| e.to_string())
}

/// **Nouvel appareil, tour 2** — ouvre le blob scellé → VaultKey + account_id.
/// **Échoue** si le blob ne s'ouvre pas (mauvais destinataire / altération).
#[flutter_rust_bridge::frb(sync)]
pub fn pairing_new_device_open(state: Vec<u8>, sealed: Vec<u8>) -> Result<PairingOpened, String> {
    let result = pairing_open(&state, &sealed).map_err(|e| e.to_string())?;
    Ok(PairingOpened {
        vault_key: result.vault_key,
        account_id: result.account_id,
    })
}
