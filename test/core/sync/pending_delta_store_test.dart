import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/sync/pending_delta_store.dart';

/// File FIFO des deltas locaux en attente de poussée, sur une base en mémoire.
void main() {
  late AppDatabase db;
  late DriftPendingDeltaStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftPendingDeltaStore(db);
  });

  tearDown(() => db.close());

  Uint8List payload(int fill) => Uint8List.fromList([fill, fill]);

  test('file vide au départ', () async {
    expect(await store.count(), 0);
    expect(await store.peek(10), isEmpty);
  });

  test('enfile et compte les deltas', () async {
    await store.enqueue(payload(1));
    await store.enqueue(payload(2));

    expect(await store.count(), 2);
  });

  test('peek respecte l\'ordre d\'enfilement et la limite', () async {
    await store.enqueue(payload(1));
    await store.enqueue(payload(2));
    await store.enqueue(payload(3));

    final head = await store.peek(2);

    expect(head, hasLength(2));
    expect(head[0].payload, payload(1));
    expect(head[1].payload, payload(2));
    expect(head[0].id, lessThan(head[1].id));
  });

  test('ack retire les deltas acquittés et laisse la suite', () async {
    await store.enqueue(payload(1));
    await store.enqueue(payload(2));
    await store.enqueue(payload(3));
    final head = await store.peek(2);

    await store.ack(head.map((d) => d.id).toList());

    expect(await store.count(), 1);
    expect((await store.peek(10)).single.payload, payload(3));
  });

  test('ack d\'une liste vide ne touche à rien', () async {
    await store.enqueue(payload(1));

    await store.ack(const []);

    expect(await store.count(), 1);
  });

  test('deux payloads identiques restent deux entrées distinctes', () async {
    await store.enqueue(payload(7));
    await store.enqueue(payload(7));

    final all = await store.peek(10);
    expect(all, hasLength(2));
    expect(all[0].id, isNot(all[1].id));
  });
}
