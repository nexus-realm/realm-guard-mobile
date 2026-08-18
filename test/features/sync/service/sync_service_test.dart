import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realmguard/features/auth/data/server_config.dart';
import 'package:realmguard/features/auth/service/session_store.dart';
import 'package:realmguard/features/sync/data/sync_exception.dart';
import 'package:realmguard/features/sync/service/sync_api.dart';

class _FakeSession implements SessionStore {
  String? token;
  _FakeSession(this.token);

  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}

const _config = ServerConfig(baseUrl: 'http://test');

SyncService _service(
  MockClient client, {
  String? token = 'tok',
  Future<void> Function()? ensureSession,
}) {
  final session = _FakeSession(token);
  return SyncService(
    httpClient: client,
    session: session,
    config: _config,
    ensureSession: ensureSession ?? () async => session.token = 'refreshed',
  );
}

void main() {
  group('SyncService.pushDelta', () {
    test('POST base64 + Bearer, renvoie le seq', () async {
      late http.Request captured;
      final service = _service(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({'seq': 7}), 201);
        }),
      );

      final seq = await service.pushDelta(Uint8List.fromList([1, 2, 3]));

      expect(seq, 7);
      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'http://test/sync/deltas');
      expect(captured.headers['authorization'], 'Bearer tok');
      expect(jsonDecode(captured.body), {
        'payload': base64.encode([1, 2, 3]),
      });
    });

    test('401 ⇒ sessionExpired', () async {
      final service = _service(MockClient((_) async => http.Response('', 401)));
      await expectLater(
        service.pushDelta(Uint8List(1)),
        throwsA(
          isA<SyncException>().having(
            (e) => e.kind,
            'kind',
            SyncErrorKind.sessionExpired,
          ),
        ),
      );
    });
  });

  group('SyncService.pullDeltas', () {
    test('since/limit en query, décode les payloads + latest', () async {
      late Uri url;
      final service = _service(
        MockClient((req) async {
          url = req.url;
          return http.Response(
            jsonEncode({
              'deltas': [
                {
                  'seq': 5,
                  'payload': base64.encode([9]),
                },
                {
                  'seq': 6,
                  'payload': base64.encode([8, 7]),
                },
              ],
              'latest': 6,
            }),
            200,
          );
        }),
      );

      final page = await service.pullDeltas(since: 4, limit: 100);

      expect(url.queryParameters, {'since': '4', 'limit': '100'});
      expect(page.latest, 6);
      expect(page.deltas.map((d) => d.seq), [5, 6]);
      expect(page.deltas[1].payload, [8, 7]);
    });

    test('410 ⇒ cursorGone', () async {
      final service = _service(MockClient((_) async => http.Response('', 410)));
      await expectLater(
        service.pullDeltas(since: 0),
        throwsA(
          isA<SyncException>().having(
            (e) => e.kind,
            'kind',
            SyncErrorKind.cursorGone,
          ),
        ),
      );
    });
  });

  group('SyncService snapshot', () {
    test('putSnapshot POST payload + covers_seq, renvoie purged', () async {
      late http.Request captured;
      final service = _service(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({'purged': 12}), 200);
        }),
      );

      final purged = await service.putSnapshot(
        Uint8List.fromList([4, 2]),
        coversSeq: 9,
      );

      expect(purged, 12);
      expect(captured.method, 'PUT');
      expect(jsonDecode(captured.body), {
        'payload': base64.encode([4, 2]),
        'covers_seq': 9,
      });
    });

    test('getSnapshot décode payload + covers_seq', () async {
      final service = _service(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'payload': base64.encode([1, 1]),
              'covers_seq': 3,
            }),
            200,
          ),
        ),
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot!.coversSeq, 3);
      expect(snapshot.payload, [1, 1]);
    });

    test('getSnapshot 404 ⇒ null', () async {
      final service = _service(MockClient((_) async => http.Response('', 404)));
      expect(await service.getSnapshot(), isNull);
    });
  });

  group('SyncService session & réseau', () {
    test('sans session : ré-auth puis utilise le nouveau token', () async {
      late http.Request captured;
      final service = _service(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({'seq': 1}), 201);
        }),
        token: null, // pas de session au départ
      );

      await service.pushDelta(Uint8List(1));
      // ensureSession par défaut pose le token 'refreshed'.
      expect(captured.headers['authorization'], 'Bearer refreshed');
    });

    test('ré-auth échoue ⇒ sessionExpired', () async {
      final service = _service(
        MockClient((_) async => http.Response(jsonEncode({'seq': 1}), 201)),
        token: null,
        ensureSession: () async => throw Exception('no device identity'),
      );
      await expectLater(
        service.pushDelta(Uint8List(1)),
        throwsA(
          isA<SyncException>().having(
            (e) => e.kind,
            'kind',
            SyncErrorKind.sessionExpired,
          ),
        ),
      );
    });

    test('erreur réseau ⇒ network', () async {
      final service = _service(
        MockClient((_) async => throw http.ClientException('boom')),
      );
      await expectLater(
        service.pullDeltas(since: 0),
        throwsA(
          isA<SyncException>().having(
            (e) => e.kind,
            'kind',
            SyncErrorKind.network,
          ),
        ),
      );
    });
  });
}
