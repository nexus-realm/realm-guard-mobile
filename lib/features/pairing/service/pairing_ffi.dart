import 'dart:typed_data';

import '../../../src/rust/api/pairing.dart';

/// Pairing d'appareil côté FFI (abstraction pour la testabilité). L'implémentation
/// réelle délègue au FFI Rust (synchrone : X25519 + AEAD légers) ; les tests
/// fournissent un faux.
abstract interface class PairingFfi {
  /// Nouvel appareil : paire éphémère + payload QR, portant sa clé d'identité
  /// [devicePublicKey] (liée au transcript).
  PairingStart start(Uint8List devicePublicKey);

  /// Appareil source : scelle `{accountId, vaultKey}` vers le nouvel appareil.
  PairingSealed seal(Uint8List qr, Uint8List accountId, Uint8List vaultKey);

  /// Nouvel appareil : ouvre la réponse scellée. Lève si mauvais destinataire.
  PairingOpened open(Uint8List state, Uint8List response);
}

/// Implémentation réelle : appelle les fonctions FFI générées.
class FrbPairingFfi implements PairingFfi {
  const FrbPairingFfi();

  @override
  PairingStart start(Uint8List devicePublicKey) =>
      pairingNewDeviceStart(devicePublicKey: devicePublicKey);

  @override
  PairingSealed seal(Uint8List qr, Uint8List accountId, Uint8List vaultKey) =>
      pairingSourceSeal(qr: qr, accountId: accountId, vaultKey: vaultKey);

  @override
  PairingOpened open(Uint8List state, Uint8List response) =>
      pairingNewDeviceOpen(state: state, response: response);
}
