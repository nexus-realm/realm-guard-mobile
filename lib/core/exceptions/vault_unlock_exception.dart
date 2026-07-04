/// Levée quand le déverrouillage du coffre échoue (mot de passe incorrect, base
/// corrompue, erreur Keystore, ...).
///
/// La [cause] d'origine est conservée pour le diagnostic uniquement et n'est
/// **délibérément pas** incluse dans [toString], afin qu'aucun détail interne ne
/// soit exposé à l'UI ou aux logs qui afficheraient l'exception.
class VaultUnlockException implements Exception {
  const VaultUnlockException([this.cause]);

  /// Erreur sous-jacente, pour le debug seulement. Jamais montrée à l'utilisateur.
  final Object? cause;

  @override
  String toString() => 'VaultUnlockException';
}
