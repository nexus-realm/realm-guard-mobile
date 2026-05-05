import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../features/onboarding/data/password_validation_rules.dart';

class PasswordForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController? passwordConfirmationController;
  final AutovalidateMode autoValidateMode;
  final bool enabled;
  final void Function(String password)? onPasswordChanged;
  final void Function(String confirmation)? onConfirmPasswordChanged;

  const PasswordForm({
    super.key,
    required this.formKey,
    required this.passwordController,
    this.passwordConfirmationController,
    this.autoValidateMode = AutovalidateMode.disabled,
    this.enabled = true,
    this.onPasswordChanged,
    this.onConfirmPasswordChanged,
  });

  @override
  State<StatefulWidget> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  bool _isPasswordObscured = true;
  bool _isPasswordConfirmationObscured = true;

  @override
  void dispose() {
    widget.passwordController.clear();
    widget.passwordController.dispose();
    if (widget.passwordConfirmationController != null) {
      widget.passwordConfirmationController?.clear();
      widget.passwordConfirmationController?.dispose();
    }
    super.dispose();
  }

  bool _isPasswordValid(String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return false;
    final rules = PasswordValidationRules.getPasswordValidationRules(trimmed);
    return rules.every((rule) => rule.validate(trimmed));
  }

  String? _passwordValidator(String? value) {
    final password = (value ?? '').trim();

    if (password.isEmpty) {
      return 'Veuillez saisir un mot de passe.';
    }

    if (widget.passwordConfirmationController != null &&
        !_isPasswordValid(password)) {
      return 'Le mot de passe ne respecte pas toutes les conditions.';
    }

    return null;
  }

  String? _passwordConfirmationValidator(String? value) {
    final confirmation = (value ?? '').trim();
    final password = widget.passwordController.text.trim();

    if (confirmation.isEmpty) {
      return 'Veuillez confirmer le mot de passe.';
    }

    if (confirmation != password) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }

  Widget _buildPasswordValidationRules() {
    final password = widget.passwordController.text;
    final rules = PasswordValidationRules.getPasswordValidationRules(password);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rules.map((rule) {
            final isValid = rule.validate(password);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: isValid ? AppColors.success : AppColors.grey2,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rule.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isValid ? AppColors.success : AppColors.grey2,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: widget.autoValidateMode,
      child: Column(
        spacing: 12,
        children: [
          TextFormField(
            controller: widget.passwordController,
            obscureText: _isPasswordObscured,
            enabled: widget.enabled,
            validator: _passwordValidator,
            onChanged: (value) {
              setState(() {});
              widget.onPasswordChanged?.call(value);
            },
            decoration: InputDecoration(
              labelText: 'Mot de passe maitre',
              suffixIcon: IconButton(
                tooltip: _isPasswordObscured
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          if (widget.passwordConfirmationController != null) ...[
            TextFormField(
              controller: widget.passwordConfirmationController,
              obscureText: _isPasswordConfirmationObscured,
              enabled: widget.enabled,
              validator: _passwordConfirmationValidator,
              onChanged: (value) {
                setState(() {});
                widget.onConfirmPasswordChanged?.call(value);
              },
              decoration: InputDecoration(
                labelText: 'Confirmation du mot de passe',
                suffixIcon: IconButton(
                  tooltip: _isPasswordConfirmationObscured
                      ? 'Afficher la confirmation'
                      : 'Masquer la confirmation',
                  onPressed: () {
                    setState(() {
                      _isPasswordConfirmationObscured =
                          !_isPasswordConfirmationObscured;
                    });
                  },
                  icon: Icon(
                    _isPasswordConfirmationObscured
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            _buildPasswordValidationRules(),
          ],
        ],
      ),
    );
  }
}
