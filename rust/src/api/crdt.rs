//! Pont FFI vers le **CRDT du coffre** (`realm_guard_core::model::VaultDoc`).
//!
//! API **fonctionnelle** : Dart détient les octets du `VaultDoc` (source de vérité,
//! persistée) ; chaque mutation renvoie le doc ré-encodé **et** le **delta** à
//! propager (push serveur). Opérations légères (décodage/mutation/ré-encodage d'un
//! coffre) → **synchrones**.
//!
//! **Périmètre P3.3a — structurel seulement.** Les valeurs de champ sont des
//! `Ciphertext` **opaques** (encodés postcard) : le chiffrement clair↔Ciphertext et
//! la source d'horloge HLC vivent dans la couche appelante (P3.3b), qui fournit ici
//! la valeur déjà chiffrée et le timestamp `(wall_ms, counter)` déjà calculé.

use realm_guard_core::codec;
use realm_guard_core::crdt::{DeviceId, Hlc, Timestamp};
use realm_guard_core::crypto::{Ciphertext, decrypt_entry_bytes, encrypt_entry_bytes};
use realm_guard_core::model::{EntryId, FieldId, VaultDoc};

/// Un `VaultDoc` ré-encodé + le delta produit par une mutation.
pub struct CrdtMutation {
    /// VaultDoc complet ré-encodé (à persister — source de vérité locale).
    pub doc: Vec<u8>,
    /// Delta à propager au serveur.
    pub delta: Vec<u8>,
}

/// Un champ énuméré : identifiant + valeur (`Ciphertext` encodé, opaque).
pub struct CrdtField {
    pub field_id: u16,
    pub value: Vec<u8>,
}

/// État d'horloge HLC d'un appareil, threadé par Dart (pas d'`HlcClock` vivant).
pub struct HlcTick {
    pub wall_ms: u64,
    pub counter: u32,
}

fn decode_doc(bytes: &[u8]) -> Result<VaultDoc<Ciphertext>, String> {
    codec::decode(bytes).map_err(|e| e.to_string())
}

fn encode_doc(doc: &VaultDoc<Ciphertext>) -> Result<Vec<u8>, String> {
    codec::encode(doc).map_err(|e| e.to_string())
}

fn to_id16(bytes: &[u8], what: &str) -> Result<[u8; 16], String> {
    bytes
        .try_into()
        .map_err(|_| format!("{what} doit faire 16 octets"))
}

/// `VaultDoc` vide, encodé.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_new() -> Result<Vec<u8>, String> {
    encode_doc(&VaultDoc::<Ciphertext>::new())
}

/// Marque une entrée présente (add-wins). Renvoie le doc + le delta.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_add_entry(
    doc: Vec<u8>,
    entry_id: Vec<u8>,
    device_id: Vec<u8>,
) -> Result<CrdtMutation, String> {
    let mut doc = decode_doc(&doc)?;
    let delta = doc.add_entry(
        EntryId::from_bytes(to_id16(&entry_id, "entry_id")?),
        DeviceId::from_bytes(to_id16(&device_id, "device_id")?),
    );
    Ok(CrdtMutation {
        doc: encode_doc(&doc)?,
        delta: encode_doc(&delta)?,
    })
}

/// Retire une entrée. Renvoie le doc + le delta.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_remove_entry(doc: Vec<u8>, entry_id: Vec<u8>) -> Result<CrdtMutation, String> {
    let mut doc = decode_doc(&doc)?;
    let delta = doc.remove_entry(&EntryId::from_bytes(to_id16(&entry_id, "entry_id")?));
    Ok(CrdtMutation {
        doc: encode_doc(&doc)?,
        delta: encode_doc(&delta)?,
    })
}

/// Écrit un champ (LWW). `value` = `Ciphertext` encodé (opaque) ; le timestamp
/// `(wall_ms, counter)` est fourni par l'appelant (source d'horloge côté Dart).
/// Renvoie le doc + le delta.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_set_field(
    doc: Vec<u8>,
    entry_id: Vec<u8>,
    field_id: u16,
    value: Vec<u8>,
    wall_ms: u64,
    counter: u32,
    device_id: Vec<u8>,
) -> Result<CrdtMutation, String> {
    let mut doc = decode_doc(&doc)?;
    let ciphertext: Ciphertext = codec::decode(&value).map_err(|e| e.to_string())?;
    let timestamp = Timestamp::new(
        Hlc { wall_ms, counter },
        DeviceId::from_bytes(to_id16(&device_id, "device_id")?),
    );
    let delta = doc.set_field(
        EntryId::from_bytes(to_id16(&entry_id, "entry_id")?),
        FieldId(field_id),
        ciphertext,
        timestamp,
    );
    Ok(CrdtMutation {
        doc: encode_doc(&doc)?,
        delta: encode_doc(&delta)?,
    })
}

/// Fusionne un delta (ou un état complet — snapshot). Idempotent / commutatif.
/// Renvoie le doc résultant.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_merge(doc: Vec<u8>, delta: Vec<u8>) -> Result<Vec<u8>, String> {
    let mut doc = decode_doc(&doc)?;
    let delta = decode_doc(&delta)?;
    doc.merge(&delta);
    encode_doc(&doc)
}

/// Identifiants (16 octets) des entrées **présentes**.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_entry_ids(doc: Vec<u8>) -> Result<Vec<Vec<u8>>, String> {
    let doc = decode_doc(&doc)?;
    Ok(doc.entry_ids().map(|e| e.as_bytes().to_vec()).collect())
}

/// Champs d'une entrée : `(field_id, Ciphertext encodé)`, pour la projection locale.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_entry_fields(doc: Vec<u8>, entry_id: Vec<u8>) -> Result<Vec<CrdtField>, String> {
    let doc = decode_doc(&doc)?;
    let id = EntryId::from_bytes(to_id16(&entry_id, "entry_id")?);
    let mut fields = Vec::new();
    for (field, ciphertext) in doc.entry_fields(&id) {
        fields.push(CrdtField {
            field_id: field.0,
            value: codec::encode(ciphertext).map_err(|e| e.to_string())?,
        });
    }
    Ok(fields)
}

/// `DeviceId` (16 o) dérivé de la clé publique d'appareil **Ed25519** (32 o) : ses 16
/// premiers octets. Unique et stable par appareil (128 bits d'une clé aléatoire) —
/// suffit au tiebreak HLC du CRDT.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_device_id_from_key(public_key: Vec<u8>) -> Result<Vec<u8>, String> {
    if public_key.len() < 16 {
        return Err("clé publique trop courte (16 octets minimum)".to_string());
    }
    Ok(public_key[..16].to_vec())
}

/// Génère un `EntryId` aléatoire (16 o) via le CSPRNG de l'OS — pour une nouvelle
/// entrée du coffre.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_new_entry_id() -> Result<Vec<u8>, String> {
    Ok(EntryId::generate()
        .map_err(|e| e.to_string())?
        .as_bytes()
        .to_vec())
}

/// Chiffre la valeur d'un champ (clé propre à l'entrée, dérivée de `vault_key` et
/// `entry_id`). Sortie = `Ciphertext` **encodé**, à passer à [`crdt_set_field`].
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_encrypt_field(
    vault_key: Vec<u8>,
    entry_id: Vec<u8>,
    plaintext: Vec<u8>,
) -> Result<Vec<u8>, String> {
    encrypt_entry_bytes(&vault_key, &entry_id, &plaintext).map_err(|e| e.to_string())
}

/// Déchiffre la valeur d'un champ (issue de [`crdt_entry_fields`]) → clair.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_decrypt_field(
    vault_key: Vec<u8>,
    entry_id: Vec<u8>,
    value: Vec<u8>,
) -> Result<Vec<u8>, String> {
    decrypt_entry_bytes(&vault_key, &entry_id, &value).map_err(|e| e.to_string())
}

/// Plus grand HLC du doc (tous les registres, présents ou tombstonés) →
/// `(wall_ms, counter)` ; `(0, 0)` si aucun champ n'a été écrit.
///
/// Après un merge distant, Dart avance son horloge locale au-delà de cette
/// valeur (via [`crdt_hlc_tick`] au prochain write) : sinon une écriture locale
/// estampillée d'un HLC inférieur à une valeur distante déjà fusionnée la
/// perdrait en LWW.
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_max_hlc(doc: Vec<u8>) -> Result<HlcTick, String> {
    let doc = decode_doc(&doc)?;
    let hlc = doc.max_hlc().unwrap_or_default();
    Ok(HlcTick {
        wall_ms: hlc.wall_ms,
        counter: hlc.counter,
    })
}

/// Fait avancer l'horloge HLC locale : renvoie le prochain `(wall_ms, counter)`
/// strictement supérieur, à persister par Dart et à passer à [`crdt_set_field`].
#[flutter_rust_bridge::frb(sync)]
pub fn crdt_hlc_tick(last_wall_ms: u64, last_counter: u32, now_ms: u64) -> HlcTick {
    let next = Hlc {
        wall_ms: last_wall_ms,
        counter: last_counter,
    }
    .next_local(now_ms);
    HlcTick {
        wall_ms: next.wall_ms,
        counter: next.counter,
    }
}
