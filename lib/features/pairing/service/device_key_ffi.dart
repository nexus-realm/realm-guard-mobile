import 'dart:typed_data';

import '../../../src/rust/api/device_key.dart';

/// Clés d'identité d'appareil (Ed25519) côté FFI — abstraction pour la testabilité.
/// L'implémentation réelle délègue au cœur (synchrone : opérations légères).
abstract interface class DeviceKeyFfi {
  /// Génère la paire d'identité de cet appareil.
  DeviceKeypair generate();

  /// Signe un défi (nonce serveur) avec la graine secrète.
  Uint8List sign(Uint8List secret, Uint8List challenge);
}

/// Implémentation réelle : appelle les fonctions FFI générées.
class FrbDeviceKeyFfi implements DeviceKeyFfi {
  const FrbDeviceKeyFfi();

  @override
  DeviceKeypair generate() => deviceGenerateKeypair();

  @override
  Uint8List sign(Uint8List secret, Uint8List challenge) =>
      deviceSignChallenge(secret: secret, challenge: challenge);
}
