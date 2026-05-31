import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/add_profile_view_model.dart';

class AddProfilePage extends StatefulWidget {
  final VaultEditor repository;

  const AddProfilePage({required this.repository, super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  late final AddProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _emailControllers = [
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = AddProfileViewModel(widget.repository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _emailControllers) {
      controller.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }

  void _addEmailField() {
    setState(() => _emailControllers.add(TextEditingController()));
  }

  void _removeEmailField(int index) {
    setState(() {
      _emailControllers.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final emails = _emailControllers.map((c) => c.text).toList();
    final success = await _viewModel.submit(_nameController.text, emails);

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ViewTitle(topTitle: 'Coffre', title: 'Profil_'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_viewModel.isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Veuillez saisir un nom de profil.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Emails',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._buildEmailFields(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _viewModel.isSubmitting
                            ? null
                            : _addEmailField,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un email'),
                      ),
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
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildEmailFields() {
    return List.generate(_emailControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailControllers[index],
                enabled: !_viewModel.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email ${index + 1}',
                ),
              ),
            ),
            if (_emailControllers.length > 1)
              IconButton(
                tooltip: 'Supprimer cet email',
                onPressed: _viewModel.isSubmitting
                    ? null
                    : () => _removeEmailField(index),
                icon: const Icon(Icons.remove_circle_outline),
              ),
          ],
        ),
      );
    });
  }
}
