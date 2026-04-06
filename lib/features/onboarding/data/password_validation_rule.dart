class PasswordValidationRule {
  final String label;
  bool Function(String password) validate;

  PasswordValidationRule({
    required this.label,
    required this.validate,
  });
}
