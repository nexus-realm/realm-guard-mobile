import 'dart:typed_data';

import '../../../src/rust/api/pairing.dart';

/// Pairing d'appareil côté FFI (abstraction pour la testabilité). L'implémentation
/// réelle délègue au FFI Rust (synchrone : X25519 + AEAD légers) ; les tests
/// fournissent un faux.
abstract interface class PairingFfi {
  /// Nouvel appareil : paire éphémère + payload QR.
  PairingStart start();

  /// Appareil source : scelle la VaultKey vers le nouvel appareil.
  PairingSealed seal(Uint8List qr, Uint8List vaultKey);

  /// Nouvel appareil : ouvre la réponse scellée. Lève si mauvais destinataire.
  PairingOpened open(Uint8List state, Uint8List response);
}

/// Implémentation réelle : appelle les fonctions FFI générées.
class FrbPairingFfi implements PairingFfi {
  const FrbPairingFfi();

  @override
  PairingStart start() => pairingNewDeviceStart();

  @override
  PairingSealed seal(Uint8List qr, Uint8List vaultKey) =>
      pairingSourceSeal(qr: qr, vaultKey: vaultKey);

  @override
  PairingOpened open(Uint8List state, Uint8List response) =>
      pairingNewDeviceOpen(state: state, response: response);
}
