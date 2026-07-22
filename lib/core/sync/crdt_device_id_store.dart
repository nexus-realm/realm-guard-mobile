import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identité d'appareil **du CRDT** : un identifiant aléatoire de 16 octets,
/// généré une fois et persisté. Sert uniquement de départage (tiebreak) des
/// horloges HLC entre appareils.
///
/// **Distinct de la clé d'appareil Ed25519** (compte / synchro) : disponible
/// même en mode hors-ligne pur (pas de compte), et sans lier les écritures du
/// coffre à l'identité de compte visible du serveur dans la structure des deltas.
abstract interface class CrdtDeviceIdStore {
  /// Id d'appareil CRDT (16 o), créé au premier appel puis stable.
  Future<Uint8List> getOrCreate();
}

/// Implémentation adossée au keystore de l'OS via `flutter_secure_storage`.
class SecureCrdtDeviceIdStore implements CrdtDeviceIdStore {
  static const _key = 'crdt_device_id_v1';

  final FlutterSecureStorage _storage;

  const SecureCrdtDeviceIdStore(this._storage);

  @override
  Future<Uint8List> getOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) {
      final bytes = base64.decode(existing);
      if (bytes.length == 16) return bytes;
    }
    final rng = Random.secure();
    final id = Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );
    await _storage.write(key: _key, value: base64.encode(id));
    return id;
  }
}
