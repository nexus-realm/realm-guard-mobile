import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realmguard/features/auth/data/server_config.dart';
import 'package:realmguard/features/auth/service/session_store.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_ffi.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/src/rust/api/pairing.dart';

/// Faux FFI de pairing : valeurs déterministes, échecs simulables.
class _FakeFfi implements PairingFfi {
  bool failSeal = false;
  bool failOpen = false;

  final startState = Uint8List.fromList([1, 1, 1]);
  final startQr = Uint8List.fromList([2, 2, 2, 2]);
  final sealResponse = Uint8List.fromList([7, 7, 7]);
  final sealSas = '246810';
  final openVaultKey = Uint8List.fromList([5, 5, 5, 5]);
  final openSas = '135790';

  @override
  PairingStart start() => PairingStart(state: startState, qr: startQr);

  @override
  PairingSealed seal(Uint8List qr, Uint8List vaultKey) {
    if (failSeal) throw Exception('seal');
    return PairingSealed(response: sealResponse, sas: sealSas);
  }

  @override
  PairingOpened open(Uint8List state, Uint8List response) {
    if (failOpen) throw Exception('open');
    return PairingOpened(vaultKey: openVaultKey, sas: openSas);
  }
}

class _FakeSession implements SessionStore {
  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;
}

void main() {
  const config = ServerConfig(baseUrl: 'http://test.local');

  PairingService build(
    MockClient client, {
    _FakeFfi? ffi,
    _FakeSession? session,
  }) => PairingService(
    ffi: ffi ?? _FakeFfi(),
    httpClient: client,
    session: session ?? _FakeSession(),
    config: config,
  );

  test('startNewDevice enveloppe le QR cœur avec un relay_id de transport', () {
    final ffi = _FakeFfi();
    final client = MockClient((req) async => http.Response('', 404));
    final s = build(client, ffi: ffi).startNewDevice();

    expect(s.state, ffi.startState);
    final envelope = jsonDecode(s.qrPayload) as Map<String, dynamic>;
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(envelope['i'] as String), isTrue);
    expect(envelope['i'], s.relayId);
    expect(base64.decode(envelope['q'] as String), ffi.startQr);
  });

  test(
    'pairScannedDevice scelle, dépose (POST Bearer) et renvoie le SAS',
    () async {
      final ffi = _FakeFfi();
      final session = _FakeSession()..token = 'tok';
      String? authHeader;
      String? path;
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        if (req.method == 'POST' && req.url.path.startsWith('/pairing/')) {
          authHeader = req.headers['authorization'];
          path = req.url.path;
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }
        return http.Response('not found', 404);
      });

      final qrPayload = jsonEncode({
        'i': 'relay0123',
        'q': base64.encode([9, 9]),
      });
      final sas = await build(client, ffi: ffi, session: session)
          .pairScannedDevice(
            qrPayload: qrPayload,
            vaultKey: Uint8List.fromList([1]),
          );

      expect(sas, ffi.sealSas);
      expect(authHeader, 'Bearer tok');
      expect(path, '/pairing/relay0123');
      expect(base64.decode(body!['response'] as String), ffi.sealResponse);
    },
  );

  test('pairScannedDevice sans session → sessionExpired', () async {
    final client = MockClient((req) async => http.Response('', 204));
    final qrPayload = jsonEncode({
      'i': 'r',
      'q': base64.encode([1]),
    });

    expect(
      () => build(client).pairScannedDevice(
        qrPayload: qrPayload,
        vaultKey: Uint8List.fromList([1]),
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.sessionExpired,
        ),
      ),
    );
  });

  test('pairScannedDevice avec QR illisible → invalidQr', () async {
    final session = _FakeSession()..token = 'tok';
    final client = MockClient((req) async => http.Response('', 204));

    expect(
      () => build(client, session: session).pairScannedDevice(
        qrPayload: 'ceci-n-est-pas-du-json',
        vaultKey: Uint8List.fromList([1]),
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.invalidQr,
        ),
      ),
    );
  });

  test('pairScannedDevice rejeté (401) → sessionExpired', () async {
    final session = _FakeSession()..token = 'tok';
    final client = MockClient((req) async => http.Response('', 401));
    final qrPayload = jsonEncode({
      'i': 'r',
      'q': base64.encode([1]),
    });

    expect(
      () => build(client, session: session).pairScannedDevice(
        qrPayload: qrPayload,
        vaultKey: Uint8List.fromList([1]),
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.sessionExpired,
        ),
      ),
    );
  });

  test('receiveVaultKey poll (404 puis 200) → VaultKey + SAS', () async {
    final ffi = _FakeFfi();
    var calls = 0;
    final client = MockClient((req) async {
      if (req.method == 'GET' && req.url.path == '/pairing/r1') {
        calls++;
        if (calls < 2) return http.Response('', 404);
        return http.Response(
          jsonEncode({
            'response': base64.encode([3, 3, 3]),
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final session = PairingSession(
      state: Uint8List(0),
      relayId: 'r1',
      qrPayload: '',
    );
    final receipt = await build(client, ffi: ffi).receiveVaultKey(
      session,
      timeout: const Duration(seconds: 1),
      interval: const Duration(milliseconds: 5),
    );

    expect(receipt.vaultKey, ffi.openVaultKey);
    expect(receipt.sas, ffi.openSas);
    expect(calls, 2);
  });

  test('receiveVaultKey blob illisible (open échoue) → corrupted', () async {
    final ffi = _FakeFfi()..failOpen = true;
    final client = MockClient(
      (req) async => http.Response(
        jsonEncode({
          'response': base64.encode([1]),
        }),
        200,
      ),
    );
    final session = PairingSession(
      state: Uint8List.fromList([0]),
      relayId: 'r1',
      qrPayload: '',
    );

    expect(
      () => build(client, ffi: ffi).receiveVaultKey(
        session,
        timeout: const Duration(seconds: 1),
        interval: const Duration(milliseconds: 5),
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.corrupted,
        ),
      ),
    );
  });

  test('receiveVaultKey expire si rien n\'est déposé → timeout', () async {
    final client = MockClient((req) async => http.Response('', 404));
    final session = PairingSession(
      state: Uint8List.fromList([0]),
      relayId: 'r1',
      qrPayload: '',
    );

    expect(
      () => build(client).receiveVaultKey(
        session,
        timeout: const Duration(milliseconds: 30),
        interval: const Duration(milliseconds: 5),
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.timeout,
        ),
      ),
    );
  });
}
