import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realmguard/features/auth/data/server_config.dart';
import 'package:realmguard/features/auth/service/session_store.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/device_key_ffi.dart';
import 'package:realmguard/features/pairing/service/device_key_store.dart';
import 'package:realmguard/features/pairing/service/pairing_ffi.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/src/rust/api/device_key.dart';
import 'package:realmguard/src/rust/api/pairing.dart';

/// Faux FFI de pairing : valeurs déterministes, échecs simulables.
class _FakeFfi implements PairingFfi {
  bool failSeal = false;
  bool failOpen = false;

  final startState = Uint8List.fromList([1, 1, 1]);
  final startQr = Uint8List.fromList([2, 2, 2, 2]);
  final sealResponse = Uint8List.fromList([7, 7, 7]);
  final sealSas = '246810';
  final sealDevicePk = Uint8List.fromList(List<int>.filled(32, 3));
  final openVaultKey = Uint8List.fromList([5, 5, 5, 5]);
  final openSas = '135790';
  final openAccountId = Uint8List.fromList(List<int>.filled(16, 0)..[15] = 1);

  Uint8List? lastStartDevicePk;
  Uint8List? lastSealAccountId;

  @override
  PairingStart start(Uint8List devicePublicKey) {
    lastStartDevicePk = devicePublicKey;
    return PairingStart(state: startState, qr: startQr);
  }

  @override
  PairingSealed seal(Uint8List qr, Uint8List accountId, Uint8List vaultKey) {
    if (failSeal) throw Exception('seal');
    lastSealAccountId = accountId;
    return PairingSealed(
      response: sealResponse,
      sas: sealSas,
      devicePublicKey: sealDevicePk,
    );
  }

  @override
  PairingOpened open(Uint8List state, Uint8List response) {
    if (failOpen) throw Exception('open');
    return PairingOpened(
      vaultKey: openVaultKey,
      accountId: openAccountId,
      sas: openSas,
    );
  }
}

/// Faux FFI de clé d'appareil : paire fixe, signature déterministe.
class _FakeDeviceKeyFfi implements DeviceKeyFfi {
  final public = Uint8List.fromList(List<int>.filled(32, 8));
  final secret = Uint8List.fromList(List<int>.filled(32, 9));
  final signature = Uint8List.fromList(List<int>.filled(64, 4));
  int generateCalls = 0;
  Uint8List? lastSigned;

  @override
  DeviceKeypair generate() {
    generateCalls++;
    return DeviceKeypair(public: public, secret: secret);
  }

  @override
  Uint8List sign(Uint8List secret, Uint8List challenge) {
    lastSigned = challenge;
    return signature;
  }
}

/// Stockage d'identité d'appareil en mémoire.
class _FakeDeviceKeyStore implements DeviceKeyStore {
  StoredDeviceKey? key;

  @override
  Future<StoredDeviceKey?> read() async => key;

  @override
  Future<void> write(StoredDeviceKey value) async => key = value;

  @override
  Future<void> clear() async => key = null;
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

  const account = '00000000-0000-0000-0000-000000000001';

  PairingService build(
    MockClient client, {
    _FakeFfi? ffi,
    _FakeSession? session,
    _FakeDeviceKeyFfi? deviceKeyFfi,
    _FakeDeviceKeyStore? deviceKeyStore,
  }) => PairingService(
    ffi: ffi ?? _FakeFfi(),
    deviceKeyFfi: deviceKeyFfi ?? _FakeDeviceKeyFfi(),
    deviceKeyStore: deviceKeyStore ?? _FakeDeviceKeyStore(),
    httpClient: client,
    session: session ?? _FakeSession(),
    config: config,
  );

  test(
    'startNewDevice enveloppe le QR cœur avec un relay_id de transport',
    () async {
      final ffi = _FakeFfi();
      final client = MockClient((req) async => http.Response('', 404));
      final s = await build(client, ffi: ffi).startNewDevice();

      expect(s.state, ffi.startState);
      final envelope = jsonDecode(s.qrPayload) as Map<String, dynamic>;
      expect(
        RegExp(r'^[0-9a-f]{32}$').hasMatch(envelope['i'] as String),
        isTrue,
      );
      expect(envelope['i'], s.relayId);
      expect(base64.decode(envelope['q'] as String), ffi.startQr);
    },
  );

  test('startNewDevice crée puis réutilise l\'identité d\'appareil', () async {
    final ffi = _FakeFfi();
    final deviceKeyFfi = _FakeDeviceKeyFfi();
    final store = _FakeDeviceKeyStore();
    final client = MockClient((req) async => http.Response('', 404));
    final service = build(
      client,
      ffi: ffi,
      deviceKeyFfi: deviceKeyFfi,
      deviceKeyStore: store,
    );

    await service.startNewDevice();
    expect(deviceKeyFfi.generateCalls, 1);
    expect(store.key!.public, deviceKeyFfi.public);
    // La clé publique part bien dans le QR (liée au transcript par le cœur).
    expect(ffi.lastStartDevicePk, deviceKeyFfi.public);

    // Deuxième appel : identité réutilisée, pas de nouvelle génération.
    await service.startNewDevice();
    expect(deviceKeyFfi.generateCalls, 1);
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
      final outcome = await build(client, ffi: ffi, session: session)
          .pairScannedDevice(
            qrPayload: qrPayload,
            accountId: account,
            vaultKey: Uint8List.fromList([1]),
          );

      expect(outcome.sas, ffi.sealSas);
      // La clé d'appareil remontée vient du QR (à inscrire après confirmation).
      expect(outcome.devicePublicKey, ffi.sealDevicePk);
      // L'account_id est converti en 16 octets pour le cœur.
      expect(ffi.lastSealAccountId!.length, 16);
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
        accountId: account,
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
        accountId: account,
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
        accountId: account,
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
    // Le compte rejoint est reformaté en UUID textuel depuis les 16 octets du blob.
    expect(receipt.accountId, account);
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

  test('registerPairedDevice POST /devices avec Bearer → 201', () async {
    final session = _FakeSession()..token = 'tok';
    String? authHeader;
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      if (req.method == 'POST' && req.url.path == '/devices') {
        authHeader = req.headers['authorization'];
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 'dev-1'}), 201);
      }
      return http.Response('not found', 404);
    });

    await build(client, session: session).registerPairedDevice(
      devicePublicKey: Uint8List.fromList(List<int>.filled(32, 3)),
      name: 'Laptop',
    );

    expect(authHeader, 'Bearer tok');
    expect(body!['name'], 'Laptop');
    expect(base64.decode(body!['device_pk'] as String).length, 32);
  });

  test('registerPairedDevice sans session → sessionExpired', () async {
    final client = MockClient((req) async => http.Response('', 201));

    expect(
      () => build(client).registerPairedDevice(
        devicePublicKey: Uint8List.fromList(List<int>.filled(32, 3)),
        name: 'Laptop',
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

  test('authenticateDevice : défi → signature → session stockée', () async {
    final deviceKeyFfi = _FakeDeviceKeyFfi();
    final store = _FakeDeviceKeyStore()
      ..key = StoredDeviceKey(
        public: deviceKeyFfi.public,
        secret: deviceKeyFfi.secret,
      );
    final session = _FakeSession();
    final nonce = Uint8List.fromList(List<int>.filled(32, 2));
    Map<String, dynamic>? verifyBody;

    final client = MockClient((req) async {
      if (req.url.path == '/auth/device/challenge') {
        return http.Response(
          jsonEncode({'challenge': base64.encode(nonce)}),
          200,
        );
      }
      if (req.url.path == '/auth/device/verify') {
        verifyBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'session_token': 'device-tok'}), 200);
      }
      return http.Response('not found', 404);
    });

    await build(
      client,
      session: session,
      deviceKeyFfi: deviceKeyFfi,
      deviceKeyStore: store,
    ).authenticateDevice();

    // C'est bien le nonce du serveur qui est signé, et la session est persistée.
    expect(deviceKeyFfi.lastSigned, nonce);
    expect(
      base64.decode(verifyBody!['signature'] as String),
      deviceKeyFfi.signature,
    );
    expect(session.token, 'device-tok');
  });

  test('authenticateDevice : appareil refusé (401) → deviceRejected', () async {
    final deviceKeyFfi = _FakeDeviceKeyFfi();
    final store = _FakeDeviceKeyStore()
      ..key = StoredDeviceKey(
        public: deviceKeyFfi.public,
        secret: deviceKeyFfi.secret,
      );
    final session = _FakeSession();
    final client = MockClient((req) async {
      if (req.url.path == '/auth/device/challenge') {
        return http.Response(
          jsonEncode({
            'challenge': base64.encode([1, 2, 3]),
          }),
          200,
        );
      }
      return http.Response('', 401);
    });

    await expectLater(
      build(
        client,
        session: session,
        deviceKeyFfi: deviceKeyFfi,
        deviceKeyStore: store,
      ).authenticateDevice(),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.deviceRejected,
        ),
      ),
    );
    // Aucune session n'est posée sur un refus.
    expect(session.token, isNull);
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
