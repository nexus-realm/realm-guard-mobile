import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/secure_clipboard.dart';

/// [SecureClipboard] wraps a native channel (Android sensitive flag +
/// compare-then-clear). The native round-trip isn't reachable from the VM, but
/// the Dart contract **is**: which method is invoked with which args, the
/// auto-clear timer, its cancellation, and the no-plugin fallback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fr.nexusrealm.realmguard/secure_clipboard');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    SecureClipboard.debugReset();
  });

  test('copySensitive marque la copie comme sensible côté natif', () {
    fakeAsync((async) {
      const SecureClipboard().copySensitive('s3cret');
      async.flushMicrotasks();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'copy');
      final args = calls.single.arguments as Map;
      expect(args['text'], 's3cret');
      expect(args['sensitive'], true);
    });
  });

  test('le presse-papiers est vidé après le délai, valeur à l\'appui', () {
    fakeAsync((async) {
      const SecureClipboard().copySensitive('s3cret');
      async.flushMicrotasks();
      calls.clear();

      // Rien ne se déclenche avant l'échéance.
      async.elapse(SecureClipboard.clearDelay - const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(calls, isEmpty);

      // À l'échéance : effacement en passant la valeur attendue (compare-then-clear).
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'clear');
      expect((calls.single.arguments as Map)['expected'], 's3cret');
    });
  });

  test('une nouvelle copie annule l\'effacement programmé de la précédente', () {
    fakeAsync((async) {
      const clip = SecureClipboard();
      clip.copySensitive('first');
      async.flushMicrotasks();

      // Avant l'échéance de « first », on recopie « second ».
      async.elapse(const Duration(seconds: 10));
      clip.copySensitive('second');
      async.flushMicrotasks();
      calls.clear();

      // Le timer de « first » ne doit jamais tirer ; seul « second » est effacé.
      async.elapse(SecureClipboard.clearDelay);
      async.flushMicrotasks();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'clear');
      expect((calls.single.arguments as Map)['expected'], 'second');
    });
  });

  test('sans plugin natif, copySensitive retombe sur Clipboard.setData', () async {
    // Simule l'absence du plugin : le canal jette MissingPluginException et la
    // copie doit retomber sur le presse-papiers Flutter (aucune perte de copie).
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw MissingPluginException('no clipboard channel'),
    );

    // Clipboard.setData rides SystemChannels.platform (JSONMethodCodec — a plain
    // MethodChannel('flutter/platform') would decode with the wrong codec).
    final platformCalls = <MethodCall>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await const SecureClipboard().copySensitive('fallback');

    final setData = platformCalls
        .where((c) => c.method == 'Clipboard.setData')
        .toList();
    expect(setData, hasLength(1), reason: 'doit copier malgré tout');
    expect((setData.single.arguments as Map)['text'], 'fallback');
  });
}
