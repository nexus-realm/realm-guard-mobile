import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/add_profile_view_model.dart';
import 'widgets/profile_form.dart';

class AddProfilePage extends StatefulWidget {
  final VaultEditor repository;

  const AddProfilePage({required this.repository, super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  late final AddProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<ProfileFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = AddProfileViewModel(widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final draft = _profileFormKey.currentState!.buildDraft();
    final success = await _viewModel.submit(draft);

    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      final message = _viewModel.errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau profil')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ViewTitle(topTitle: 'Coffre', title: 'Profil_'),
                  const SizedBox(height: 24),
                  ProfileForm(
                    key: _profileFormKey,
                    formKey: _formKey,
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
