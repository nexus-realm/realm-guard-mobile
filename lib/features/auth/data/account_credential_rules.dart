import '../../../core/security/password_validation_rules.dart';
import 'username_rules.dart';

/// Validation **partagée** des identifiants d'un compte de synchronisation
/// (onboarding et Réglages). Source unique des messages d'erreur pour rester
/// cohérent d'un écran à l'autre. Le mot de passe du compte suit exactement la
/// même politique que le mot de passe du coffre ([PasswordValidationRules]).
class AccountCredentialRules {
  const AccountCredentialRules._();

  /// Message d'erreur FR pour le nom d'utilisateur, ou `null` si valide.
  static String? validateUsername(String value) =>
      UsernameRules.validate(value);

  /// Message d'erreur FR pour le mot de passe du compte, ou `null` si valide.
  static String? validatePassword(String value) {
    if (value.trim().isEmpty) return 'Veuillez saisir un mot de passe.';
    if (!PasswordValidationRules.isStrong(value)) {
      return 'Au moins 12 caractères, avec majuscule, minuscule, chiffre et '
          'caractère spécial.';
    }
    return null;
  }
}
