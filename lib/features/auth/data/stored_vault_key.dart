import 'dart:typed_data';

/// VaultKey récupérée du serveur, **déjà désenrobée** de la couche OPAQUE : il
/// reste la VaultKey enrobée par la KEK ([wrappedVaultKey]) + le sel de dérivation
/// ([salt]) permettant à un nouvel appareil de re-dériver la KEK depuis le mot de
/// passe maître. Le serveur ne voit jamais la VaultKey en clair.
class StoredVaultKey {
  /// VaultKey enrobée par la KEK (état local, à désenrober avec la KEK).
  final Uint8List wrappedVaultKey;

  /// Sel Argon2id (non secret) de dérivation de la KEK.
  final Uint8List salt;

  const StoredVaultKey({required this.wrappedVaultKey, required this.salt});
}
