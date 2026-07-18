import 'dart:typed_data';

import '../../src/rust/api/crdt.dart';

export '../../src/rust/api/crdt.dart' show CrdtField, CrdtMutation, HlcTick;

/// CRDT du coffre côté FFI (abstraction pour la testabilité). L'implémentation
/// réelle délègue aux fonctions FFI Rust générées — synchrones : décodage /
/// mutation / (dé)chiffrement d'un coffre chargé en mémoire. Les tests
/// fournissent un faux (aucune lib native requise).
abstract interface class CrdtFfi {
  /// `VaultDoc` vide, encodé.
  Uint8List newDoc();

  /// Génère un identifiant d'entrée (16 o) via le CSPRNG de l'OS.
  Uint8List newEntryId();

  /// `DeviceId` (16 o) dérivé d'une clé publique d'appareil Ed25519 (32 o).
  Uint8List deviceIdFromKey(Uint8List publicKey);

  /// Marque une entrée présente (add-wins). Renvoie le doc + le delta.
  CrdtMutation addEntry(Uint8List doc, Uint8List entryId, Uint8List deviceId);

  /// Retire une entrée (tombstone add-wins). Renvoie le doc + le delta.
  CrdtMutation removeEntry(Uint8List doc, Uint8List entryId);

  /// Écrit un champ (LWW). `value` = `Ciphertext` encodé ; `(wallMs, counter)` =
  /// timestamp HLC fourni par l'appelant. Renvoie le doc + le delta.
  CrdtMutation setField(
    Uint8List doc,
    Uint8List entryId,
    int fieldId,
    Uint8List value,
    BigInt wallMs,
    int counter,
    Uint8List deviceId,
  );

  /// Fusionne un delta (ou un snapshot). Idempotent / commutatif.
  Uint8List merge(Uint8List doc, Uint8List delta);

  /// Identifiants (16 o) des entrées présentes.
  List<Uint8List> entryIds(Uint8List doc);

  /// Champs d'une entrée : `(fieldId, Ciphertext encodé)`.
  List<CrdtField> entryFields(Uint8List doc, Uint8List entryId);

  /// Chiffre la valeur d'un champ (clé propre à l'entrée) → `Ciphertext` encodé.
  Uint8List encryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List plaintext,
  );

  /// Déchiffre la valeur d'un champ (issue de [entryFields]) → clair.
  Uint8List decryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List value,
  );

  /// Fait avancer l'horloge HLC locale portée par `(wallMs, counter)`.
  HlcTick hlcTick(BigInt lastWallMs, int lastCounter, BigInt nowMs);

  /// Plus grand HLC du doc (tous registres, présents ou tombstonés) ; `(0, 0)`
  /// si vide. Pour avancer l'horloge locale après un merge distant.
  HlcTick maxHlc(Uint8List doc);
}

/// Implémentation réelle : appelle les fonctions FFI générées.
class FrbCrdtFfi implements CrdtFfi {
  const FrbCrdtFfi();

  @override
  Uint8List newDoc() => crdtNew();

  @override
  Uint8List newEntryId() => crdtNewEntryId();

  @override
  Uint8List deviceIdFromKey(Uint8List publicKey) =>
      crdtDeviceIdFromKey(publicKey: publicKey);

  @override
  CrdtMutation addEntry(Uint8List doc, Uint8List entryId, Uint8List deviceId) =>
      crdtAddEntry(doc: doc, entryId: entryId, deviceId: deviceId);

  @override
  CrdtMutation removeEntry(Uint8List doc, Uint8List entryId) =>
      crdtRemoveEntry(doc: doc, entryId: entryId);

  @override
  CrdtMutation setField(
    Uint8List doc,
    Uint8List entryId,
    int fieldId,
    Uint8List value,
    BigInt wallMs,
    int counter,
    Uint8List deviceId,
  ) => crdtSetField(
    doc: doc,
    entryId: entryId,
    fieldId: fieldId,
    value: value,
    wallMs: wallMs,
    counter: counter,
    deviceId: deviceId,
  );

  @override
  Uint8List merge(Uint8List doc, Uint8List delta) =>
      crdtMerge(doc: doc, delta: delta);

  @override
  List<Uint8List> entryIds(Uint8List doc) => crdtEntryIds(doc: doc);

  @override
  List<CrdtField> entryFields(Uint8List doc, Uint8List entryId) =>
      crdtEntryFields(doc: doc, entryId: entryId);

  @override
  Uint8List encryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List plaintext,
  ) => crdtEncryptField(
    vaultKey: vaultKey,
    entryId: entryId,
    plaintext: plaintext,
  );

  @override
  Uint8List decryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List value,
  ) => crdtDecryptField(vaultKey: vaultKey, entryId: entryId, value: value);

  @override
  HlcTick hlcTick(BigInt lastWallMs, int lastCounter, BigInt nowMs) =>
      crdtHlcTick(lastWallMs: lastWallMs, lastCounter: lastCounter, nowMs: nowMs);

  @override
  HlcTick maxHlc(Uint8List doc) => crdtMaxHlc(doc: doc);
}
