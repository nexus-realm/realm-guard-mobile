import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/mutex.dart';

void main() {
  test('sérialise : aucune section critique ne chevauche une autre', () async {
    final mutex = Mutex();
    final log = <String>[];

    Future<void> op(String id) => mutex.run(() async {
      log.add('$id-start');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      log.add('$id-end');
    });

    // Lancées "en même temps" : doivent quand même s'exécuter l'une après l'autre.
    await Future.wait([op('a'), op('b'), op('c')]);

    expect(log, [
      'a-start', 'a-end',
      'b-start', 'b-end',
      'c-start', 'c-end',
    ]);
  });

  test('ordre FIFO préservé', () async {
    final mutex = Mutex();
    final order = <int>[];
    final futures = [
      for (var i = 0; i < 5; i++) mutex.run(() async => order.add(i)),
    ];
    await Future.wait(futures);
    expect(order, [0, 1, 2, 3, 4]);
  });

  test('une action qui lève ne bloque pas les suivantes', () async {
    final mutex = Mutex();
    final ran = <String>[];

    final failing = mutex.run(() async => throw Exception('boom'));
    final next = mutex.run(() async => ran.add('suivante'));

    await expectLater(failing, throwsException);
    await next;
    expect(ran, ['suivante']);
  });

  test('renvoie la valeur de l\'action', () async {
    expect(await Mutex().run(() async => 42), 42);
  });
}
