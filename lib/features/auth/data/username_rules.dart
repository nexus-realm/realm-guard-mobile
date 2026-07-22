/// Règles de validation du **nom d'utilisateur** de compte de synchronisation.
///
/// Choix produit : le serveur n'impose aucun format (zero-knowledge sur le
/// handle), donc ces contraintes sont purement côté client — un identifiant
/// court, lisible et sans ambiguïté (pas d'espace, pas de casse surprenante).
class UsernameRules {
  const UsernameRules._();

  /// Longueur minimale.
  static const int minLength = 3;

  /// Caractères autorisés : lettres, chiffres, point, tiret bas, tiret.
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9._-]+$');

  /// Renvoie un message d'erreur **français**, ou `null` si le nom est valide.
  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return "Le nom d'utilisateur doit contenir au moins $minLength caractères.";
    }
    if (!_allowed.hasMatch(trimmed)) {
      return "Lettres, chiffres, « . _ - » uniquement (pas d'espace).";
    }
    return null;
  }

  /// `true` si le nom respecte toutes les règles.
  static bool isValid(String value) => validate(value) == null;
}
