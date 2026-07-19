import 'dart:typed_data';

import 'crdt_ffi.dart';
import 'field_value.dart';
import 'vault_fields.dart';

/// Une entrée du coffre projetée depuis le `VaultDoc` : son identité stable, son
/// type, et ses champs **déchiffrés/décodés** (hors champ `kind`).
class DecodedEntry {
  /// `syncId` (16 o) — la clé stable de la ligne locale (⇔ `EntryId`).
  final Uint8List syncId;

  /// Type de l'entrée (route la projection vers la bonne table).
  final VaultKind kind;

  /// Champs présents, `FieldId → valeur`. N'inclut jamais [VaultFields.kind].
  final Map<int, FieldValue> fields;

  const DecodedEntry({
    required this.syncId,
    required this.kind,
    required this.fields,
  });
}

/// **Lecture** : `VaultDoc` → entrées décodées, prêtes à projeter en base locale.
class VaultProjection {
  final CrdtFfi _ffi;

  const VaultProjection(this._ffi);

  /// Décode toutes les entrées **présentes** de [docBytes] avec [vaultKey].
  ///
  /// Une entrée sans champ `kind`, ou d'un `kind` inconnu, est **ignorée**
  /// (tolérance aux versions futures : on ne projette pas ce qu'on ne comprend
  /// pas). Les entrées absentes (supprimées / tombstone) ne sont pas énumérées
  /// par le cœur, donc jamais projetées.
  List<DecodedEntry> decode(Uint8List docBytes, Uint8List vaultKey) {
    final entries = <DecodedEntry>[];
    for (final entryId in _ffi.entryIds(docBytes)) {
      VaultKind? kind;
      final fields = <int, FieldValue>{};
      for (final field in _ffi.entryFields(docBytes, entryId)) {
        final plaintext = _ffi.decryptField(vaultKey, entryId, field.value);
        final value = FieldValue.decode(plaintext);
        if (field.fieldId == VaultFields.kind) {
          if (value is IntValue) kind = VaultKind.fromCode(value.value);
        } else {
          fields[field.fieldId] = value;
        }
      }
      if (kind == null) continue;
      entries.add(DecodedEntry(syncId: entryId, kind: kind, fields: fields));
    }
    return entries;
  }
}

/// Résultat d'une écriture : nouveau doc à persister, deltas à pousser au
/// serveur, et l'horloge HLC avancée à conserver.
class VaultWriteResult {
  final Uint8List doc;
  final List<Uint8List> deltas;
  final HlcTick clock;

  const VaultWriteResult({
    required this.doc,
    required this.deltas,
    required this.clock,
  });
}

/// **Écriture** : applique une carte de champs à une entrée du `VaultDoc`, en
/// chiffrant chaque valeur (clé propre à l'entrée) et en faisant avancer
/// l'horloge HLC. Le doc reste la source de vérité locale ; les deltas partent
/// au serveur.
class VaultDocWriter {
  final CrdtFfi _ffi;

  const VaultDocWriter(this._ffi);

  /// Applique [fields] à [entryId] dans [doc]. Si [markPresent] (création),
  /// marque d'abord l'entrée présente (add-wins). Chaque champ est chiffré puis
  /// écrit en LWW avec un HLC **strictement croissant**, dérivé de [clock] et de
  /// [nowMs] (temps physique courant, ms epoch). Renvoie le doc mis à jour, les
  /// deltas produits (dans l'ordre appliqué) et l'horloge avancée.
  VaultWriteResult putFields({
    required Uint8List doc,
    required Uint8List entryId,
    required Uint8List deviceId,
    required Uint8List vaultKey,
    required Map<int, FieldValue> fields,
    required HlcTick clock,
    required BigInt nowMs,
    bool markPresent = false,
  }) {
    var currentDoc = doc;
    var currentClock = clock;
    final deltas = <Uint8List>[];

    if (markPresent) {
      final mutation = _ffi.addEntry(currentDoc, entryId, deviceId);
      currentDoc = mutation.doc;
      deltas.add(mutation.delta);
    }

    for (final field in fields.entries) {
      final ciphertext = _ffi.encryptField(
        vaultKey,
        entryId,
        field.value.encode(),
      );
      currentClock = _ffi.hlcTick(
        currentClock.wallMs,
        currentClock.counter,
        nowMs,
      );
      final mutation = _ffi.setField(
        currentDoc,
        entryId,
        field.key,
        ciphertext,
        currentClock.wallMs,
        currentClock.counter,
        deviceId,
      );
      currentDoc = mutation.doc;
      deltas.add(mutation.delta);
    }

    return VaultWriteResult(
      doc: currentDoc,
      deltas: deltas,
      clock: currentClock,
    );
  }
}
