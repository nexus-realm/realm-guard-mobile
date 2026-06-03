/// Stratégie appliquée aux identifiants liés lors de la suppression d'un profil.
enum ProfileDeletionStrategy {
  /// Les identifiants liés sont conservés mais dissociés (profileId → null).
  dissociate,

  /// Les identifiants liés sont supprimés avec le profil.
  cascade,
}
