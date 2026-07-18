import 'dart:async';
import 'dart:io';

import '../../auth/data/server_config.dart';
import '../../auth/service/session_store.dart';

/// Transport de **réveil** temps réel : émet un *nudge* (« quelque chose a changé,
/// tire ») à chaque signal du serveur. Le nudge ne porte pas de donnée utile — le
/// client tire par curseur. Abstrait pour la testabilité du contrôleur.
abstract interface class SyncSocket {
  /// Flux de nudges (un événement par frame reçue).
  Stream<void> get nudges;

  /// Ouvre la connexion (reconnexion gérée par l'implémentation).
  Future<void> connect();

  /// Ferme la connexion et cesse toute reconnexion.
  Future<void> disconnect();
}

/// Implémentation WebSocket (`dart:io`) de `/sync/ws`, gated par Bearer. Émet un
/// nudge par frame, et se **reconnecte avec backoff** tant qu'elle n'est pas
/// fermée explicitement. Best-effort : le WS accélère, les déclencheurs (poll de
/// secours) garantissent la correction si un nudge est perdu.
class WsSyncSocket implements SyncSocket {
  final SessionStore _session;
  final ServerConfig _config;
  final Future<void> Function() _ensureSession;

  final StreamController<void> _nudges = StreamController<void>.broadcast();
  WebSocket? _ws;
  bool _closed = false;
  Duration _backoff = _minBackoff;

  static const Duration _minBackoff = Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 30);

  WsSyncSocket({
    required SessionStore session,
    required ServerConfig config,
    required Future<void> Function() ensureSession,
  }) : _session = session,
       _config = config,
       _ensureSession = ensureSession;

  @override
  Stream<void> get nudges => _nudges.stream;

  @override
  Future<void> connect() async {
    _closed = false;
    unawaited(_loop());
  }

  Future<void> _loop() async {
    while (!_closed) {
      try {
        final token = await _token();
        final ws = await WebSocket.connect(
          _wsUrl(),
          headers: {'authorization': 'Bearer $token'},
        );
        _ws = ws;
        _backoff = _minBackoff; // connexion réussie → reset du backoff
        await for (final _ in ws) {
          if (_closed) break;
          _nudges.add(null); // frame reçue = nudge
        }
      } catch (_) {
        // Connexion / écoute échouée → on retente après backoff.
      }
      _ws = null;
      if (_closed) break;
      await Future<void>.delayed(_backoff);
      final doubled = _backoff * 2;
      _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
    }
  }

  @override
  Future<void> disconnect() async {
    _closed = true;
    await _ws?.close();
    _ws = null;
  }

  Future<String> _token() async {
    final existing = await _session.read();
    if (existing != null) return existing;
    await _ensureSession();
    final token = await _session.read();
    if (token == null) throw StateError('session absente');
    return token;
  }

  String _wsUrl() {
    final base = _config.baseUrl.replaceFirst(RegExp('^http'), 'ws');
    return '$base/sync/ws';
  }
}
