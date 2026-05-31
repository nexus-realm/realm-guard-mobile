import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/add_credential_view_model.dart';

class AddCredentialPage extends StatefulWidget {
  final VaultEditor repository;

  const AddCredentialPage({required this.repository, super.key});

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  late final AddCredentialViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  int? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _viewModel = AddCredentialViewModel(widget.repository);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dataController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final success = await _viewModel.submit(
      title: _titleController.text,
      data: _dataController.text,
      profileId: _selectedProfileId,
    );

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ViewTitle(topTitle: 'Coffre', title: 'Identifiant_'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_viewModel.isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Veuillez saisir un titre.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataController,
                      enabled: !_viewModel.isSubmitting,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Données',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileSelector(),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSelector() {
    if (_viewModel.profiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<int?>(
      initialValue: _selectedProfileId,
      decoration: const InputDecoration(labelText: 'Profil associé (optionnel)'),
      items: [
        const DropdownMenuItem<int?>(child: Text('Aucun profil')),
        ..._viewModel.profiles.map(
          (Profile profile) => DropdownMenuItem<int?>(
            value: profile.id,
            child: Text(profile.name),
          ),
        ),
      ],
      onChanged: _viewModel.isSubmitting
          ? null
          : (value) => setState(() => _selectedProfileId = value),
    );
  }
}
