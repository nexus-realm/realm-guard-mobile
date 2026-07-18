import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_crdt.dart';
import 'package:realmguard/core/sync/vault_doc_store.dart';
import 'package:realmguard/core/sync/vault_fields.dart';

import '../../support/sync_test_doubles.dart';

Uint8List _id(int fill) => Uint8List.fromList(List.filled(16, fill));

VaultCrdt _crdt(FakeCrdtFfi ffi, InMemoryVaultDocStore store) => VaultCrdt(
  ffi: ffi,
  store: store,
  vaultKey: Uint8List.fromList([1, 2, 3]),
  deviceId: _id(8),
  now: () => DateTime.fromMillisecondsSinceEpoch(1000),
);

void main() {
  group('VaultCrdt.putEntry', () {
    test('création : doc vide, add_entry + set_field, doc persisté', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();

      final deltas = await _crdt(ffi, store).putEntry(
        entryId: _id(1),
        fields: {
          VaultFields.kind: const IntValue(1),
          VaultFields.credentialTitle: const TextValue('GitHub'),
        },
        isNew: true,
      );

      expect(ffi.added, [_id(1)]);
      expect(ffi.setFields.length, 2);
      expect(store.state, isNotNull);
      expect(store.saves, 1);
      // add_entry + 2 set_field.
      expect(deltas.length, 3);
    });

    test('mise à jour : pas d\'add_entry, horloge poursuivie', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();
      final crdt = _crdt(ffi, store);

      // 1re écriture (création) : clock → (1000, 1) après 2 champs.
      await crdt.putEntry(
        entryId: _id(1),
        fields: {
          VaultFields.kind: const IntValue(1),
          VaultFields.credentialTitle: const TextValue('GitHub'),
        },
        isNew: true,
      );
      ffi.added.clear();

      // 2e écriture (mise à jour) : reprend l'horloge persistée → (1000, 2).
      await crdt.putEntry(
        entryId: _id(1),
        fields: {VaultFields.credentialPassword: const TextValue('pw')},
        isNew: false,
      );

      expect(ffi.added, isEmpty);
      expect(ffi.setFields.last.fieldId, VaultFields.credentialPassword);
      expect(ffi.setFields.last.counter, 2); // continuité HLC
      expect(store.state!.clock.counter, 2);
      expect(store.saves, 2);
    });
  });

  group('VaultCrdt.removeEntry', () {
    test('retire l\'entrée et persiste', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore()
        ..state = VaultDocState(
          doc: Uint8List.fromList([1, 2, 3]),
          clock: HlcTick(wallMs: BigInt.zero, counter: 0),
        );

      final deltas = await _crdt(ffi, store).removeEntry(_id(1));

      expect(ffi.removed, [_id(1)]);
      expect(deltas.length, 1);
      expect(store.saves, 1);
    });

    test('coffre non semé : sans effet', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();

      final deltas = await _crdt(ffi, store).removeEntry(_id(1));

      expect(deltas, isEmpty);
      expect(ffi.removed, isEmpty);
      expect(store.saves, 0);
    });
  });

  group('VaultCrdt.seed', () {
    test('construit depuis vide et persiste une seule fois', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();

      await _crdt(ffi, store).seed([
        SeedEntry(entryId: _id(1), fields: {VaultFields.kind: const IntValue(0)}),
        SeedEntry(entryId: _id(2), fields: {VaultFields.kind: const IntValue(1)}),
      ]);

      expect(ffi.added, [_id(1), _id(2)]);
      expect(store.state, isNotNull);
      expect(store.saves, 1); // une seule persistance pour tout le seed
    });
  });
}
