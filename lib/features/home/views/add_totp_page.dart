import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/add_totp_view_model.dart';
import 'widgets/totp_form.dart';

class AddTotpPage extends StatefulWidget {
  final TotpEditor repository;

  const AddTotpPage({required this.repository, super.key});

  @override
  State<AddTotpPage> createState() => _AddTotpPageState();
}

class _AddTotpPageState extends State<AddTotpPage> {
  late final AddTotpViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _totpFormKey = GlobalKey<TotpFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = AddTotpViewModel(widget.repository);
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

    final draft = _totpFormKey.currentState!.buildDraft();
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
      appBar: AppBar(title: const Text('Nouveau code TOTP')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ViewTitle(topTitle: 'Coffre', title: 'TOTP_'),
                  AppSpacing.gapLg,
                  TotpForm(
                    key: _totpFormKey,
                    formKey: _formKey,
                    profiles: _viewModel.profiles,
                    enabled: !_viewModel.isSubmitting,
                  ),
                  AppSpacing.gapXl,
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
