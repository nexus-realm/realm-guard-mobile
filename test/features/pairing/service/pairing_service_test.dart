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

/// Faux FFI de pairing (deux tours) : valeurs déterministes, échecs simulables.
class _FakeFfi implements PairingFfi {
  bool failBegin = false;
  bool failOpen = false;

  final startState = Uint8List.fromList([1, 1, 1]);
  final startQr = Uint8List.fromList([2, 2, 2, 2]);
  final beginState = Uint8List.fromList([6, 6, 6]);
  final beginHello = Uint8List.fromList([8, 8]);
  final beginSas = '246810';
  final beginDevicePk = Uint8List.fromList(List<int>.filled(32, 3));
  final confirmState = Uint8List.fromList([4, 4]);
  final confirmSas = '246810';
  final sealed = Uint8List.fromList([7, 7, 7]);
  final openVaultKey = Uint8List.fromList([5, 5, 5, 5]);
  final openAccountId = Uint8List.fromList(List<int>.filled(16, 0)..[15] = 1);

  Uint8List? lastStartDevicePk;
  Uint8List? lastSealAccountId;
  Uint8List? lastSealState;
  Uint8List? lastConfirmHello;

  @override
  PairingStart start(Uint8List devicePublicKey) {
    lastStartDevicePk = devicePublicKey;
    return PairingStart(state: startState, qr: startQr);
  }

  @override
  PairingSourceBegin begin(Uint8List qr) {
    if (failBegin) throw Exception('begin');
    return PairingSourceBegin(
      state: beginState,
      hello: beginHello,
      sas: beginSas,
      devicePublicKey: beginDevicePk,
    );
  }

  @override
  PairingConfirm confirm(Uint8List state, Uint8List hello) {
    lastConfirmHello = hello;
    return PairingConfirm(state: confirmState, sas: confirmSas);
  }

  @override
  Uint8List seal(Uint8List state, Uint8List accountId, Uint8List vaultKey) {
    lastSealState = state;
    lastSealAccountId = accountId;
    return sealed;
  }

  @override
  PairingOpened open(Uint8List state, Uint8List sealed) {
    if (failOpen) throw Exception('open');
    return PairingOpened(vaultKey: openVaultKey, accountId: openAccountId);
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

  test('beginPairing (tour 1) ne dépose que le hello — aucun secret', () async {
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
    final handshake = await build(
      client,
      ffi: ffi,
      session: session,
    ).beginPairing(qrPayload: qrPayload);

    expect(handshake.sas, ffi.beginSas);
    expect(handshake.relayId, 'relay0123');
    // La clé d'appareil vient du QR (à inscrire après confirmation seulement).
    expect(handshake.devicePublicKey, ffi.beginDevicePk);
    expect(authHeader, 'Bearer tok');
    expect(path, '/pairing/relay0123');
    // **Sécurité** : le tour 1 ne dépose que le hello, jamais le blob scellé.
    expect(base64.decode(body!['response'] as String), ffi.beginHello);
    expect(ffi.lastSealAccountId, isNull);
  });

  test('sealVaultKey (tour 2) scelle et dépose sur le même relais', () async {
    final ffi = _FakeFfi();
    final session = _FakeSession()..token = 'tok';
    final posted = <String, Uint8List>{};
    final client = MockClient((req) async {
      if (req.method == 'POST' && req.url.path.startsWith('/pairing/')) {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        posted[req.url.path] = base64.decode(body['response'] as String);
        return http.Response('', 204);
      }
      return http.Response('not found', 404);
    });

    final service = build(client, ffi: ffi, session: session);
    final qrPayload = jsonEncode({
      'i': 'relay0123',
      'q': base64.encode([9, 9]),
    });
    final handshake = await service.beginPairing(qrPayload: qrPayload);
    await service.sealVaultKey(
      handshake: handshake,
      accountId: account,
      vaultKey: Uint8List.fromList([1]),
    );

    // Le blob est scellé avec l'état du tour 1, et déposé sur le même relay_id.
    expect(ffi.lastSealState, ffi.beginState);
    expect(ffi.lastSealAccountId!.length, 16);
    expect(posted['/pairing/relay0123'], ffi.sealed);
  });

  test('beginPairing sans session → sessionExpired', () async {
    final client = MockClient((req) async => http.Response('', 204));
    final qrPayload = jsonEncode({
      'i': 'r',
      'q': base64.encode([1]),
    });

    expect(
      () => build(client).beginPairing(qrPayload: qrPayload),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.sessionExpired,
        ),
      ),
    );
  });

  test('beginPairing avec QR illisible → invalidQr', () async {
    final session = _FakeSession()..token = 'tok';
    final client = MockClient((req) async => http.Response('', 204));

    expect(
      () => build(
        client,
        session: session,
      ).beginPairing(qrPayload: 'ceci-n-est-pas-du-json'),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.invalidQr,
        ),
      ),
    );
  });

  test('beginPairing rejeté (401) → sessionExpired', () async {
    final session = _FakeSession()..token = 'tok';
    final client = MockClient((req) async => http.Response('', 401));
    final qrPayload = jsonEncode({
      'i': 'r',
      'q': base64.encode([1]),
    });

    expect(
      () => build(client, session: session).beginPairing(qrPayload: qrPayload),
      throwsA(
        isA<PairingException>().having(
          (e) => e.kind,
          'kind',
          PairingErrorKind.sessionExpired,
        ),
      ),
    );
  });

  test(
    'awaitSourceHello (tour 1) poll (404 puis 200) → SAS avant tout transfert',
    () async {
      final ffi = _FakeFfi();
      final hello = Uint8List.fromList([3, 3, 3]);
      var calls = 0;
      final client = MockClient((req) async {
        if (req.method == 'GET' && req.url.path == '/pairing/r1') {
          calls++;
          if (calls < 2) return http.Response('', 404);
          return http.Response(
            jsonEncode({'response': base64.encode(hello)}),
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
      final handshake = await build(client, ffi: ffi).awaitSourceHello(
        session,
        timeout: const Duration(seconds: 1),
        interval: const Duration(milliseconds: 5),
      );

      expect(handshake.sas, ffi.confirmSas);
      expect(handshake.state, ffi.confirmState);
      expect(ffi.lastConfirmHello, hello);
      expect(calls, 2);
    },
  );

  test('awaitVaultKey (tour 2) → VaultKey + compte', () async {
    final ffi = _FakeFfi();
    final client = MockClient(
      (req) async => http.Response(
        jsonEncode({
          'response': base64.encode([3, 3, 3]),
        }),
        200,
      ),
    );

    final session = PairingSession(
      state: Uint8List(0),
      relayId: 'r1',
      qrPayload: '',
    );
    final handshake = PairingHandshake(
      state: ffi.confirmState,
      sas: ffi.confirmSas,
    );
    final receipt = await build(client, ffi: ffi).awaitVaultKey(
      session,
      handshake,
      timeout: const Duration(seconds: 1),
      interval: const Duration(milliseconds: 5),
    );

    expect(receipt.vaultKey, ffi.openVaultKey);
    // Le compte rejoint est reformaté en UUID textuel depuis les 16 octets du blob.
    expect(receipt.accountId, account);
  });

  test('awaitVaultKey blob illisible (open échoue) → corrupted', () async {
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
    final handshake = PairingHandshake(
      state: ffi.confirmState,
      sas: ffi.confirmSas,
    );

    expect(
      () => build(client, ffi: ffi).awaitVaultKey(
        session,
        handshake,
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

  test('awaitSourceHello expire si la source ne vient pas → timeout', () async {
    final client = MockClient((req) async => http.Response('', 404));
    final session = PairingSession(
      state: Uint8List.fromList([0]),
      relayId: 'r1',
      qrPayload: '',
    );

    expect(
      () => build(client).awaitSourceHello(
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
