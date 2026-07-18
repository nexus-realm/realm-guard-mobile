import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/features/sync/data/sync_exception.dart';
import 'package:realmguard/features/sync/data/sync_models.dart';
import 'package:realmguard/features/sync/service/sync_api.dart';
import 'package:realmguard/features/sync/service/sync_engine.dart';

import '../../../support/sync_test_doubles.dart';

/// Faux client réseau : deltas poussés enregistrés, pages de tirage scriptées,
/// 410 puis snapshot simulables.
class _FakeSyncApi implements SyncApi {
  final List<Uint8List> pushed = [];
  int nextSeq = 1;
  final List<DeltaPage> pullPages;
  int _pullCall = 0;
  bool goneOnce;
  RemoteSnapshot? snapshot;

  _FakeSyncApi({
    this.pullPages = const [],
    this.goneOnce = false,
    this.snapshot,
  });

  @override
  Future<int> pushDelta(Uint8List delta) async {
    pushed.add(delta);
    return nextSeq++;
  }

  @override
  Future<DeltaPage> pullDeltas({required int since, int? limit}) async {
    if (goneOnce) {
      goneOnce = false;
      throw const SyncException.cursorGone();
    }
    if (_pullCall < pullPages.length) return pullPages[_pullCall++];
    return const DeltaPage(deltas: [], latest: 0);
  }

  @override
  Future<int> putSnapshot(Uint8List snapshot, {required int coversSeq}) async =>
      0;

  @override
  Future<RemoteSnapshot?> getSnapshot() async => snapshot;
}

Uint8List _b(int x) => Uint8List.fromList([x]);
final _vaultKey = Uint8List.fromList([1, 2, 3]);

SyncEngine _engine(
  _FakeSyncApi api, {
  required InMemoryVaultDocStore store,
  required InMemoryPendingDeltaStore pending,
  required FakeCrdtFfi ffi,
  required FakeReprojector reprojector,
}) => SyncEngine(
  api: api,
  store: store,
  pending: pending,
  ffi: ffi,
  reprojector: reprojector,
  vaultKey: _vaultKey,
);

void main() {
  group('SyncEngine.push', () {
    test('draine la file et ack chaque delta poussé', () async {
      final api = _FakeSyncApi();
      final pending = InMemoryPendingDeltaStore();
      await pending.enqueue(_b(10));
      await pending.enqueue(_b(20));

      await _engine(
        api,
        store: InMemoryVaultDocStore(),
        pending: pending,
        ffi: FakeCrdtFfi(),
        reprojector: FakeReprojector(),
      ).push();

      expect(api.pushed.map((d) => d.first), [10, 20]);
      expect(await pending.count(), 0); // tout acquitté
    });
  });

  group('SyncEngine.pull', () {
    test('fusionne les deltas, avance curseur + horloge, reprojette', () async {
      final api = _FakeSyncApi(
        pullPages: [
          DeltaPage(
            deltas: [
              RemoteDelta(seq: 1, payload: _b(101)),
              RemoteDelta(seq: 2, payload: _b(102)),
            ],
            latest: 2,
          ),
        ],
      );
      final store = InMemoryVaultDocStore();
      final ffi = FakeCrdtFfi()
        ..maxHlcValue = HlcTick(wallMs: BigInt.from(500), counter: 3);
      final reprojector = FakeReprojector();

      await _engine(
        api,
        store: store,
        pending: InMemoryPendingDeltaStore(),
        ffi: ffi,
        reprojector: reprojector,
      ).pull();

      expect(ffi.merged.map((d) => d.first), [101, 102]);
      expect(store.state!.cursor, 2);
      // Horloge avancée au-delà du max reçu.
      expect(store.state!.clock.wallMs, BigInt.from(500));
      expect(store.state!.clock.counter, 3);
      expect(reprojector.reprojected.length, 1);
    });

    test('page vide : ni sauvegarde ni reprojection', () async {
      final store = InMemoryVaultDocStore();
      final reprojector = FakeReprojector();

      await _engine(
        _FakeSyncApi(),
        store: store,
        pending: InMemoryPendingDeltaStore(),
        ffi: FakeCrdtFfi(),
        reprojector: reprojector,
      ).pull();

      expect(store.saves, 0);
      expect(reprojector.reprojected, isEmpty);
    });

    test('410 ⇒ repart du snapshot (merge + curseur = coversSeq)', () async {
      final api = _FakeSyncApi(
        goneOnce: true,
        snapshot: RemoteSnapshot(payload: _b(200), coversSeq: 10),
      );
      final store = InMemoryVaultDocStore();
      final ffi = FakeCrdtFfi();
      final reprojector = FakeReprojector();

      await _engine(
        api,
        store: store,
        pending: InMemoryPendingDeltaStore(),
        ffi: ffi,
        reprojector: reprojector,
      ).pull();

      // Snapshot fusionné, curseur repositionné, base reprojetée.
      expect(ffi.merged.map((d) => d.first), [200]);
      expect(store.state!.cursor, 10);
      expect(reprojector.reprojected.length, 1);
    });
  });
}
