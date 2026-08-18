import 'package:flutter/material.dart';

import '../../../shared/widgets/app_snackbar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/add_credential_view_model.dart';
import 'widgets/credential_form.dart';

class AddCredentialPage extends StatefulWidget {
  final VaultEditor repository;

  const AddCredentialPage({required this.repository, super.key});

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  late final AddCredentialViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _credentialFormKey = GlobalKey<CredentialFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = AddCredentialViewModel(widget.repository);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final draft = _credentialFormKey.currentState!.buildDraft();
    final success = await _viewModel.submit(draft);

    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      final message = _viewModel.errorMessage;
      if (message != null && message.isNotEmpty) {
        AppSnackbar.error(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel identifiant')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ViewTitle(topTitle: 'Coffre', title: 'Identifiant_'),
                  const SizedBox(height: 24),
                  CredentialForm(
                    key: _credentialFormKey,
                    formKey: _formKey,
                    profiles: _viewModel.profiles,
                    enabled: !_viewModel.isSubmitting,
                  ),
                  const SizedBox(height: 32),
                  GradientElevatedButton(
                    onPressed: _viewModel.isSubmitting ? null : _submit,
                    child: _viewModel.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
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
