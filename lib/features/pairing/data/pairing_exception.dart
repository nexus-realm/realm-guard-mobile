/// Catégorie d'échec du pairing d'appareil.
enum PairingErrorKind {
  invalidQr,
  corrupted,
  timeout,
  sessionExpired,
  deviceRejected,
  network,
  server,
}

/// Erreur de pairing, porteuse d'un message **utilisateur** (français).
class PairingException implements Exception {
  /// Catégorie de l'erreur.
  final PairingErrorKind kind;

  /// Message destiné à l'utilisateur.
  final String message;

  const PairingException(this.kind, this.message);

  const PairingException.invalidQr()
    : this(PairingErrorKind.invalidQr, 'QR de pairing invalide ou illisible.');

  const PairingException.corrupted()
    : this(
        PairingErrorKind.corrupted,
        'Réponse de pairing corrompue ou destinée à un autre appareil.',
      );

  const PairingException.timeout()
    : this(PairingErrorKind.timeout, 'Délai de pairing dépassé. Réessayez.');

  const PairingException.sessionExpired()
    : this(
        PairingErrorKind.sessionExpired,
        'Session expirée. Reconnectez-vous.',
      );

  /// Le serveur refuse l'authentification par clé d'appareil : appareil non inscrit
  /// au compte, ou révoqué.
  const PairingException.deviceRejected()
    : this(
        PairingErrorKind.deviceRejected,
        "Cet appareil n'est pas autorisé sur ce compte (non inscrit ou révoqué).",
      );

  const PairingException.network()
    : this(
        PairingErrorKind.network,
        'Serveur injoignable. Vérifiez votre connexion.',
      );

  const PairingException.server()
    : this(PairingErrorKind.server, 'Erreur du serveur. Réessayez plus tard.');

  @override
  String toString() => 'PairingException($kind): $message';
}
