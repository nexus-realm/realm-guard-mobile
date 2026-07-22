/// Catégorie d'échec de l'authentification.
enum AuthErrorKind {
  usernameTaken,
  invalidCredentials,
  sessionExpired,
  corruptedVaultKey,
  network,
  server,
  unexpected,
}

/// Erreur d'authentification, porteuse d'un message **utilisateur** (français).
class AuthException implements Exception {
  /// Catégorie de l'erreur.
  final AuthErrorKind kind;

  /// Message destiné à l'utilisateur.
  final String message;

  const AuthException(this.kind, this.message);

  const AuthException.usernameTaken()
    : this(AuthErrorKind.usernameTaken, "Ce nom d'utilisateur est déjà pris.");

  const AuthException.invalidCredentials()
    : this(AuthErrorKind.invalidCredentials, 'Identifiants invalides.');

  const AuthException.sessionExpired()
    : this(AuthErrorKind.sessionExpired, 'Session expirée. Reconnectez-vous.');

  const AuthException.corruptedVaultKey()
    : this(
        AuthErrorKind.corruptedVaultKey,
        'Clé de coffre illisible (données corrompues).',
      );

  const AuthException.network()
    : this(
        AuthErrorKind.network,
        'Serveur injoignable. Vérifiez votre connexion.',
      );

  const AuthException.server()
    : this(AuthErrorKind.server, 'Erreur du serveur. Réessayez plus tard.');

  @override
  String toString() => 'AuthException($kind): $message';
}
