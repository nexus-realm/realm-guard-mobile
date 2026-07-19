import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/sync/data/sync_exception.dart';
import 'package:realmguard/features/sync/data/sync_outcome.dart';
import 'package:realmguard/features/sync/service/sync_controller.dart';
import 'package:realmguard/features/sync/service/sync_engine.dart';
import 'package:realmguard/features/sync/service/sync_socket.dart';

/// Faux engine : compte les cycles, peut bloquer (gates) ou lever (throwOn, avec
/// l'erreur [thrown]).
class _FakeRunner implements SyncRunner {
  int calls = 0;
  int throwOn = -1;
  Object thrown = Exception('réseau');
  final List<Completer<void>> gates;

  _FakeRunner({this.gates = const []});

  @override
  Future<void> sync() async {
    final i = calls++;
    if (i == throwOn) throw thrown;
    if (i < gates.length) await gates[i].future;
  }
}

class _FakeSocket implements SyncSocket {
  final StreamController<void> ctrl = StreamController<void>.broadcast();
  int connects = 0;
  int disconnects = 0;

  @override
  Stream<void> get nudges => ctrl.stream;
  @override
  Future<void> connect() async => connects++;
  @override
  Future<void> disconnect() async => disconnects++;

  void nudge() => ctrl.add(null);
}

void main() {
  test('start : connecte le WS et lance un cycle initial', () async {
    final runner = _FakeRunner();
    final socket = _FakeSocket();

    await SyncController(engine: runner, socket: socket).start();
    await pumpEventQueue(); // le cycle initial passe par le verrou (1 microtâche)

    expect(socket.connects, 1);
    expect(runner.calls, 1);
  });

  test('un nudge déclenche un cycle', () async {
    final runner = _FakeRunner();
    final socket = _FakeSocket();
    final controller = SyncController(engine: runner, socket: socket);

    await controller.start(); // calls = 1
    socket.nudge();
    await pumpEventQueue();

    expect(runner.calls, 2);
  });

  test(
    'coalescence : les déclencheurs pendant un cycle en fusionnent un seul',
    () async {
      final gate = Completer<void>();
      final runner = _FakeRunner(gates: [gate]); // le cycle #0 se bloque
      final controller = SyncController(engine: runner, socket: _FakeSocket());

      final first = controller.requestSync(); // #0 démarre et se bloque
      await pumpEventQueue();
      expect(runner.calls, 1);

      controller.requestSync(); // en cours → pending
      controller.requestSync(); // pending reste
      await pumpEventQueue();
      expect(runner.calls, 1); // aucun cycle concurrent

      gate.complete();
      await first;
      await pumpEventQueue();
      expect(runner.calls, 2); // exactement un cycle de rattrapage
    },
  );

  test(
    'best-effort : une erreur est avalée, le contrôleur reste utilisable',
    () async {
      final runner = _FakeRunner()..throwOn = 0;
      final controller = SyncController(engine: runner, socket: _FakeSocket());

      await controller.requestSync(); // #0 lève, avalé
      expect(runner.calls, 1);

      await controller.requestSync(); // toujours fonctionnel
      expect(runner.calls, 2);
    },
  );

  test('stop : coupe le WS et cesse de réagir aux nudges', () async {
    final runner = _FakeRunner();
    final socket = _FakeSocket();
    final controller = SyncController(engine: runner, socket: socket);

    await controller.start(); // calls = 1
    await controller.stop();

    expect(socket.disconnects, 1);
    socket.nudge();
    await pumpEventQueue();
    expect(runner.calls, 1); // plus de réaction après stop
  });

  group('syncNow (manuel)', () {
    test('succès → SyncStatus.success', () async {
      final runner = _FakeRunner();
      final controller = SyncController(engine: runner, socket: _FakeSocket());

      final outcome = await controller.syncNow();

      expect(outcome.status, SyncStatus.success);
      expect(runner.calls, 1);
    });

    test('SyncException → failure porte le message utilisateur', () async {
      final runner = _FakeRunner()
        ..throwOn = 0
        ..thrown = const SyncException.network();
      final controller = SyncController(engine: runner, socket: _FakeSocket());

      final outcome = await controller.syncNow();

      expect(outcome.status, SyncStatus.failure);
      expect(outcome.message, 'Serveur injoignable. Vérifiez votre connexion.');
    });

    test('erreur inattendue → failure avec message générique', () async {
      final runner = _FakeRunner()..throwOn = 0; // Exception générique
      final controller = SyncController(engine: runner, socket: _FakeSocket());

      final outcome = await controller.syncNow();

      expect(outcome.status, SyncStatus.failure);
      expect(outcome.message, isNotNull);
    });

    test(
      'attend un cycle auto en cours (sérialisé, pas de double-push)',
      () async {
        final gate = Completer<void>();
        final runner = _FakeRunner(gates: [gate]); // cycle auto #0 se bloque
        final controller = SyncController(
          engine: runner,
          socket: _FakeSocket(),
        );

        controller.requestSync(); // auto #0 démarre, tient le verrou, se bloque
        await pumpEventQueue();
        expect(runner.calls, 1);

        final manual = controller.syncNow(); // en file derrière le verrou
        await pumpEventQueue();
        expect(runner.calls, 1); // pas encore lancé

        gate.complete();
        final outcome = await manual;

        expect(outcome.status, SyncStatus.success);
        expect(runner.calls, 2); // le manuel a tourné après l'auto
      },
    );
  });
}
