/// Résultat d'une synchronisation **manuelle** (pull-to-refresh) : donne un retour
/// explicite à l'utilisateur, contrairement aux cycles automatiques qui sont
/// best-effort et silencieux.
enum SyncStatus { success, failure, unavailable }

class SyncOutcome {
  const SyncOutcome.success() : status = SyncStatus.success, message = null;

  /// Aucune synchro possible : pas de compte de synchronisation actif sur cet
  /// appareil (l'app reste pleinement utilisable hors-ligne).
  const SyncOutcome.unavailable()
    : status = SyncStatus.unavailable,
      message = null;

  /// Échec, avec un message **utilisateur** (français) à afficher.
  const SyncOutcome.failure(this.message) : status = SyncStatus.failure;

  final SyncStatus status;
  final String? message;

  bool get isSuccess => status == SyncStatus.success;
  bool get isFailure => status == SyncStatus.failure;
  bool get isUnavailable => status == SyncStatus.unavailable;
}
