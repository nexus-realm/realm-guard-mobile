/// Catégorie d'échec de synchronisation.
enum SyncErrorKind {
  /// Session absente/expirée : l'appelant doit se ré-authentifier.
  sessionExpired,

  /// **410 Gone** au tirage : le curseur précède le snapshot serveur (deltas
  /// compactés). Signal de contrôle — l'appelant doit repartir du snapshot.
  cursorGone,

  /// Serveur injoignable / erreur réseau.
  network,

  /// Réponse serveur inattendue.
  server,
}

/// Erreur de synchronisation, porteuse d'un message **utilisateur** (français).
class SyncException implements Exception {
  final SyncErrorKind kind;
  final String message;

  const SyncException(this.kind, this.message);

  const SyncException.sessionExpired()
    : this(SyncErrorKind.sessionExpired, 'Session expirée. Reconnectez-vous.');

  const SyncException.cursorGone()
    : this(
        SyncErrorKind.cursorGone,
        'Historique de synchronisation compacté : reprise depuis un instantané.',
      );

  const SyncException.network()
    : this(
        SyncErrorKind.network,
        'Serveur injoignable. Vérifiez votre connexion.',
      );

  const SyncException.server()
    : this(SyncErrorKind.server, 'Erreur du serveur. Réessayez plus tard.');

  @override
  String toString() => 'SyncException($kind): $message';
}
