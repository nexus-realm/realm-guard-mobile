import 'password_validation_rule.dart';

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
}
