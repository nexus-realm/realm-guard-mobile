import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/vault_doc_store.dart';

/// Persistance du `VaultDocState` sur la table `crdt_docs` (ligne unique, id 0)
/// d'une base en mémoire.
void main() {
  late AppDatabase db;
  late DriftVaultDocStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftVaultDocStore(db);
  });

  tearDown(() => db.close());

  VaultDocState state({
    List<int> doc = const [1, 2, 3],
    int wallMs = 1700000000000,
    int counter = 0,
    int cursor = 0,
  }) => VaultDocState(
    doc: Uint8List.fromList(doc),
    clock: HlcTick(wallMs: BigInt.from(wallMs), counter: counter),
    cursor: cursor,
  );

  test('load renvoie null tant que le coffre CRDT n\'est pas semé', () async {
    expect(await store.load(), isNull);
  });

  test('sauvegarde puis relit doc, horloge et curseur', () async {
    await store.save(state(counter: 7, cursor: 42));

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.doc, Uint8List.fromList([1, 2, 3]));
    expect(loaded.clock.wallMs, BigInt.from(1700000000000));
    expect(loaded.clock.counter, 7);
    expect(loaded.cursor, 42);
  });

  test(
    'une seconde sauvegarde écrase la ligne (pas d\'accumulation)',
    () async {
      await store.save(state(doc: [1], cursor: 1));
      await store.save(state(doc: [9, 9], cursor: 2));

      expect(await db.select(db.crdtDocs).get(), hasLength(1));
      final loaded = await store.load();
      expect(loaded!.doc, Uint8List.fromList([9, 9]));
      expect(loaded.cursor, 2);
    },
  );

  test('copyWith n\'avance que le curseur', () async {
    await store.save(state(counter: 3, cursor: 5));
    final loaded = await store.load();

    await store.save(loaded!.copyWith(cursor: 12));

    final advanced = await store.load();
    expect(advanced!.cursor, 12);
    expect(advanced.clock.counter, 3, reason: 'horloge inchangée');
    expect(advanced.doc, loaded.doc);
  });
}
