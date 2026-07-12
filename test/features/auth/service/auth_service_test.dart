import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realmguard/features/auth/data/auth_exception.dart';
import 'package:realmguard/features/auth/data/server_config.dart';
import 'package:realmguard/features/auth/service/auth_service.dart';
import 'package:realmguard/features/auth/service/opaque_client.dart';
import 'package:realmguard/features/auth/service/session_store.dart';
import 'package:realmguard/src/rust/api/opaque.dart';

/// Faux client OPAQUE : renvoie des octets factices ; peut simuler l'échec du
/// `loginFinish` (mot de passe faux détecté côté client).
class _FakeOpaque implements OpaqueClient {
  bool failLoginFinish = false;

  Uint8List _bytes(int seed) => Uint8List.fromList([seed, seed + 1, seed + 2]);

  @override
  Future<OpaqueClientStart> registerStart(String password) async =>
      OpaqueClientStart(state: _bytes(1), message: _bytes(2));

  @override
  Future<OpaqueRegisterFinish> registerFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) async => OpaqueRegisterFinish(upload: _bytes(3), exportKey: _bytes(4));

  @override
  Future<OpaqueClientStart> loginStart(String password) async =>
      OpaqueClientStart(state: _bytes(5), message: _bytes(6));

  @override
  Future<OpaqueLoginFinish> loginFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) async {
    if (failLoginFinish) throw Exception('mot de passe faux');
    return OpaqueLoginFinish(
      finalization: _bytes(7),
      sessionKey: _bytes(8),
      exportKey: _bytes(9),
    );
  }
}

/// Stockage de session en mémoire.
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

  AuthService build(
    MockClient client, {
    _FakeOpaque? opaque,
    _FakeSession? session,
  }) => AuthService(
    opaque: opaque ?? _FakeOpaque(),
    httpClient: client,
    session: session ?? _FakeSession(),
    config: config,
  );

  String b64(List<int> bytes) => base64.encode(bytes);

  test('register enchaîne start puis finish sans lever', () async {
    final client = MockClient((req) async {
      switch (req.url.path) {
        case '/auth/register/start':
          return http.Response(jsonEncode({'response': b64([1, 2, 3])}), 200);
        case '/auth/register/finish':
          return http.Response('', 201);
      }
      return http.Response('not found', 404);
    });

    await build(client).register('alice', 'motdepasse');
  });

  test('register renvoie 409 → usernameTaken', () async {
    final client = MockClient((req) async => http.Response('', 409));

    expect(
      () => build(client).register('alice', 'pw'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.kind,
          'kind',
          AuthErrorKind.usernameTaken,
        ),
      ),
    );
  });

  test('login réussi stocke le token de session', () async {
    final session = _FakeSession();
    final client = MockClient((req) async {
      switch (req.url.path) {
        case '/auth/login/start':
          return http.Response(
            jsonEncode({'response': b64([1, 2, 3]), 'flow_id': 'flow-1'}),
            200,
          );
        case '/auth/login/finish':
          return http.Response(jsonEncode({'session_token': 'tok-123'}), 200);
      }
      return http.Response('not found', 404);
    });

    await build(client, session: session).login('alice', 'motdepasse');
    expect(session.token, 'tok-123');
  });

  test('mot de passe faux (échec client) → invalidCredentials', () async {
    final opaque = _FakeOpaque()..failLoginFinish = true;
    final client = MockClient((req) async {
      if (req.url.path == '/auth/login/start') {
        return http.Response(
          jsonEncode({'response': b64([1, 2, 3]), 'flow_id': 'flow-1'}),
          200,
        );
      }
      return http.Response('', 200);
    });

    expect(
      () => build(client, opaque: opaque).login('alice', 'mauvais'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.kind,
          'kind',
          AuthErrorKind.invalidCredentials,
        ),
      ),
    );
  });

  test('login rejeté par le serveur (401) → invalidCredentials', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/auth/login/start') {
        return http.Response(
          jsonEncode({'response': b64([1, 2, 3]), 'flow_id': 'flow-1'}),
          200,
        );
      }
      return http.Response('', 401);
    });

    expect(
      () => build(client).login('alice', 'pw'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.kind,
          'kind',
          AuthErrorKind.invalidCredentials,
        ),
      ),
    );
  });

  test('serveur injoignable → network', () async {
    final client = MockClient((req) async => throw http.ClientException('boom'));

    expect(
      () => build(client).register('alice', 'pw'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.kind,
          'kind',
          AuthErrorKind.network,
        ),
      ),
    );
  });
}
