import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_crdt.dart';
import 'package:realmguard/core/sync/vault_doc_store.dart';
import 'package:realmguard/core/sync/vault_fields.dart';

import '../../support/sync_test_doubles.dart';

Uint8List _id(int fill) => Uint8List.fromList(List.filled(16, fill));

VaultCrdt _crdt(
  FakeCrdtFfi ffi,
  InMemoryVaultDocStore store,
  InMemoryPendingDeltaStore pending,
) => VaultCrdt(
  ffi: ffi,
  store: store,
  pending: pending,
  vaultKey: Uint8List.fromList([1, 2, 3]),
  deviceId: _id(8),
  now: () => DateTime.fromMillisecondsSinceEpoch(1000),
);

void main() {
  group('VaultCrdt.putEntry', () {
    test(
      'création : add_entry + set_field, persiste, enfile les deltas',
      () async {
        final ffi = FakeCrdtFfi();
        final store = InMemoryVaultDocStore();
        final pending = InMemoryPendingDeltaStore();

        final deltas = await _crdt(ffi, store, pending).putEntry(
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
        // add_entry + 2 set_field ⇒ 3 deltas, retournés ET enfilés.
        expect(deltas.length, 3);
        expect(await pending.count(), 3);
      },
    );

    test(
      'mise à jour : pas d\'add_entry, HLC poursuivie, curseur préservé',
      () async {
        final ffi = FakeCrdtFfi();
        final pending = InMemoryPendingDeltaStore();
        // Coffre déjà semé, avec un curseur de tirage à 5.
        final store = InMemoryVaultDocStore()
          ..state = VaultDocState(
            doc: Uint8List.fromList([0]),
            clock: HlcTick(wallMs: BigInt.from(1000), counter: 0),
            cursor: 5,
          );

        await _crdt(ffi, store, pending).putEntry(
          entryId: _id(1),
          fields: {VaultFields.credentialPassword: const TextValue('pw')},
          isNew: false,
        );

        expect(ffi.added, isEmpty);
        expect(ffi.setFields.last.counter, 1); // (1000,0) → (1000,1)
        expect(store.state!.cursor, 5); // curseur intact
        expect(await pending.count(), 1);
      },
    );

    test('onChanged notifié après une écriture locale', () async {
      var changes = 0;
      final crdt = VaultCrdt(
        ffi: FakeCrdtFfi(),
        store: InMemoryVaultDocStore(),
        pending: InMemoryPendingDeltaStore(),
        vaultKey: Uint8List.fromList([1, 2, 3]),
        deviceId: _id(8),
        now: () => DateTime.fromMillisecondsSinceEpoch(1000),
        onChanged: () => changes++,
      );

      await crdt.putEntry(
        entryId: _id(1),
        fields: {VaultFields.kind: const IntValue(1)},
        isNew: true,
      );

      expect(changes, 1);
    });

    test('save + enqueue enveloppés dans la transaction fournie', () async {
      var txCalls = 0;
      final store = InMemoryVaultDocStore();
      final pending = InMemoryPendingDeltaStore();
      final crdt = VaultCrdt(
        ffi: FakeCrdtFfi(),
        store: store,
        pending: pending,
        vaultKey: Uint8List.fromList([1, 2, 3]),
        deviceId: _id(8),
        now: () => DateTime.fromMillisecondsSinceEpoch(1000),
        transaction: (action) async {
          txCalls++;
          await action();
        },
      );

      await crdt.putEntry(
        entryId: _id(1),
        fields: {VaultFields.kind: const IntValue(1)},
        isNew: true,
      );

      expect(txCalls, 1); // une transaction pour l'écriture
      expect(store.state, isNotNull); // save fait dedans
      expect(await pending.count(), greaterThan(0)); // enqueue fait dedans
    });
  });

  group('VaultCrdt.removeEntry', () {
    test('retire, persiste (curseur intact), enfile un delta', () async {
      final ffi = FakeCrdtFfi();
      final pending = InMemoryPendingDeltaStore();
      final store = InMemoryVaultDocStore()
        ..state = VaultDocState(
          doc: Uint8List.fromList([1, 2, 3]),
          clock: HlcTick(wallMs: BigInt.zero, counter: 0),
          cursor: 9,
        );

      final deltas = await _crdt(ffi, store, pending).removeEntry(_id(1));

      expect(ffi.removed, [_id(1)]);
      expect(deltas.length, 1);
      expect(store.state!.cursor, 9);
      expect(await pending.count(), 1);
    });

    test('coffre non semé : sans effet', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();
      final pending = InMemoryPendingDeltaStore();

      final deltas = await _crdt(ffi, store, pending).removeEntry(_id(1));

      expect(deltas, isEmpty);
      expect(store.saves, 0);
      expect(await pending.count(), 0);
    });
  });

  group('VaultCrdt.seed', () {
    test('construit, persiste une fois, enfile tous les deltas', () async {
      final ffi = FakeCrdtFfi();
      final store = InMemoryVaultDocStore();
      final pending = InMemoryPendingDeltaStore();

      await _crdt(ffi, store, pending).seed([
        SeedEntry(
          entryId: _id(1),
          fields: {VaultFields.kind: const IntValue(0)},
        ),
        SeedEntry(
          entryId: _id(2),
          fields: {VaultFields.kind: const IntValue(1)},
        ),
      ]);

      expect(ffi.added, [_id(1), _id(2)]);
      expect(store.saves, 1);
      // 2 entrées × (add_entry + 1 set_field) ⇒ 4 deltas enfilés.
      expect(await pending.count(), 4);
    });
  });
}
