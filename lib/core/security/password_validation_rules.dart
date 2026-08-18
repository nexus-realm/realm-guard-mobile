import 'password_validation_rule.dart';

/// Politique de mot de passe **applicable à l'ensemble de l'app** : mot de passe
/// du coffre (onboarding, changement) et mot de passe de compte de synchronisation
/// suivent les mêmes exigences.
class PasswordValidationRules {
  static List<PasswordValidationRule> getPasswordValidationRules(
    String password,
  ) {
    return [
      PasswordValidationRule(
        label: 'Au moins 12 caractères',
        validate: (pwd) => pwd.length >= 12,
      ),
      PasswordValidationRule(
        label: 'Contient au moins une lettre majuscule',
        validate: (pwd) => pwd.contains(RegExp(r'[A-Z]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins une lettre minuscule',
        validate: (pwd) => pwd.contains(RegExp(r'[a-z]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins un chiffre',
        validate: (pwd) => pwd.contains(RegExp(r'[0-9]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins un caractère spécial',
        validate: (pwd) => pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }

  /// `true` si le mot de passe respecte **toutes** les règles de la politique.
  static bool isStrong(String password) {
    final pwd = password.trim();
    if (pwd.isEmpty) return false;
    return getPasswordValidationRules(pwd).every((rule) => rule.validate(pwd));
  }
}
