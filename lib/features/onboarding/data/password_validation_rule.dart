class PasswordValidationRule {
  final String label;
  final bool Function(String password) validate;

  PasswordValidationRule({
    required this.label,
    required this.validate,
  });
}
