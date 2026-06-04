import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/vault_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/password_form.dart';
import '../viewmodels/change_password_view_model.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.vaultService, super.key});

  final VaultService vaultService;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late final ChangePasswordViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _currentObscured = true;

  @override
  void initState() {
    super.initState();
    _viewModel = ChangePasswordViewModel(vaultService: widget.vaultService);
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentValid = _formKey.currentState?.validate() ?? false;
    final newValid = _newPasswordFormKey.currentState?.validate() ?? false;
    if (!currentValid || !newValid) return;

    final ok = await _viewModel.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmation: _confirmController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe maître mis à jour.')),
      );
      context.pop();
    } else {
      final message = _viewModel.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe maître')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final enabled = !_viewModel.isSubmitting;
            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Saisissez votre mot de passe actuel puis le nouveau. Votre '
                    'coffre sera re-chiffré ; toutes vos données sont '
                    'conservées.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  AppSpacing.gapLg,
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _currentController,
                      enabled: enabled,
                      obscureText: _currentObscured,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        suffixIcon: IconButton(
                          tooltip: _currentObscured ? 'Afficher' : 'Masquer',
                          icon: Icon(
                            _currentObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _currentObscured = !_currentObscured,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Veuillez saisir votre mot de passe actuel.'
                          : null,
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text(
                    'Nouveau mot de passe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppSpacing.gapSm,
                  PasswordForm(
                    formKey: _newPasswordFormKey,
                    passwordController: _newController,
                    passwordConfirmationController: _confirmController,
                    enabled: enabled,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    onPasswordChanged: (_) => setState(() {}),
                    onConfirmPasswordChanged: (_) => setState(() {}),
                  ),
                  AppSpacing.gapXl,
                  GradientElevatedButton(
                    onPressed: enabled ? _submit : null,
                    child: _viewModel.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Changer le mot de passe'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
