import 'dart:typed_data';

import '../../../src/rust/api/pairing.dart';

/// Pairing d'appareil côté FFI, en **deux tours** (abstraction pour la testabilité).
/// L'implémentation réelle délègue au FFI Rust (synchrone : X25519 + AEAD légers) ;
/// les tests fournissent un faux.
abstract interface class PairingFfi {
  /// Nouvel appareil : paire éphémère + payload QR, portant sa clé d'identité
  /// [devicePublicKey] (liée au transcript).
  PairingStart start(Uint8List devicePublicKey);

  /// **Tour 1, source** : dérive le SAS et publie sa clé publique seule. Aucun
  /// secret ne circule à ce stade.
  PairingSourceBegin begin(Uint8List qr);

  /// **Tour 1, nouvel appareil** : dérive le SAS à comparer.
  PairingConfirm confirm(Uint8List state, Uint8List hello);

  /// **Tour 2, source** : scelle `{accountId, vaultKey}`. À n'appeler qu'après
  /// confirmation du SAS.
  Uint8List seal(Uint8List state, Uint8List accountId, Uint8List vaultKey);

  /// **Tour 2, nouvel appareil** : ouvre le blob. Lève si mauvais destinataire.
  PairingOpened open(Uint8List state, Uint8List sealed);
}

/// Implémentation réelle : appelle les fonctions FFI générées.
class FrbPairingFfi implements PairingFfi {
  const FrbPairingFfi();

  @override
  PairingStart start(Uint8List devicePublicKey) =>
      pairingNewDeviceStart(devicePublicKey: devicePublicKey);

  @override
  PairingSourceBegin begin(Uint8List qr) => pairingSourceBeginRound(qr: qr);

  @override
  PairingConfirm confirm(Uint8List state, Uint8List hello) =>
      pairingNewDeviceConfirmRound(state: state, hello: hello);

  @override
  Uint8List seal(Uint8List state, Uint8List accountId, Uint8List vaultKey) =>
      pairingSourceSealRound(
        state: state,
        accountId: accountId,
        vaultKey: vaultKey,
      );

  @override
  PairingOpened open(Uint8List state, Uint8List sealed) =>
      pairingNewDeviceOpen(state: state, sealed: sealed);
}
