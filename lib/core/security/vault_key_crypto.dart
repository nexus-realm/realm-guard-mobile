import 'dart:typed_data';

import '../../src/rust/api/vault_key.dart';

/// Enrobage **local** de la VaultKey sous la KEK (dérivée du mot de passe maître).
///
/// Abstraction injectable : l'implémentation réelle délègue au FFI Rust, les tests
/// fournissent un faux. Opérations **synchrones** (AEAD léger).
abstract interface class VaultKeyCrypto {
  /// Génère une VaultKey aléatoire (clé racine du coffre).
  Uint8List generate();

  /// Enrobe la VaultKey sous la KEK → blob local sérialisé.
  Uint8List wrap(List<int> kek, List<int> vaultKey);

  /// Désenrobe la VaultKey. Lève si la KEK est fausse (mauvais mot de passe) ou si
  /// le blob est altéré.
  Uint8List unwrap(List<int> kek, List<int> wrapped);
}

/// Implémentation réelle : appelle les fonctions FFI générées (synchrones).
class FrbVaultKeyCrypto implements VaultKeyCrypto {
  const FrbVaultKeyCrypto();

  @override
  Uint8List generate() => generateVaultKey();

  @override
  Uint8List wrap(List<int> kek, List<int> vaultKey) =>
      wrapVaultKey(kek: kek, vaultKey: vaultKey);

  @override
  Uint8List unwrap(List<int> kek, List<int> wrapped) =>
      unwrapVaultKey(kek: kek, wrapped: wrapped);
}
