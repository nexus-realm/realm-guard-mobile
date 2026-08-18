import 'dart:typed_data';

import '../../../src/rust/api/vault_key.dart';

/// Enrobage/désenrobage de la VaultKey sous la **clé exportée OPAQUE**
/// (abstraction pour la testabilité).
///
/// L'implémentation réelle délègue au FFI Rust ; les tests fournissent un faux.
/// Le `Ciphertext` est sérialisé côté Rust → ici on ne manipule que des octets.
abstract interface class VaultKeyCipher {
  /// Enrobe la VaultKey (déjà enrobée par la KEK) → blob à téléverser.
  Uint8List seal(Uint8List exportKey, Uint8List wrappedVaultKey);

  /// Désenrobe le blob serveur → VaultKey enrobée par la KEK. Lève si
  /// l'`exportKey` ne correspond pas ou si le blob est altéré.
  Uint8List open(Uint8List exportKey, Uint8List sealed);
}

/// Implémentation réelle : appelle les fonctions FFI générées (synchrones :
/// HKDF + AEAD, opérations légères).
class FrbVaultKeyCipher implements VaultKeyCipher {
  const FrbVaultKeyCipher();

  @override
  Uint8List seal(Uint8List exportKey, Uint8List wrappedVaultKey) =>
      sealVaultKey(exportKey: exportKey, wrappedVaultKey: wrappedVaultKey);

  @override
  Uint8List open(Uint8List exportKey, Uint8List sealed) =>
      openVaultKey(exportKey: exportKey, sealed: sealed);
}
