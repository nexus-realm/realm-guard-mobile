import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../data/totp_draft.dart';
import '../viewmodels/add_totp_view_model.dart';
import 'scan_totp_page.dart';
import 'widgets/totp_form.dart';

class AddTotpPage extends StatefulWidget {
  final TotpEditor repository;

  const AddTotpPage({required this.repository, super.key});

  @override
  State<AddTotpPage> createState() => _AddTotpPageState();
}

class _AddTotpPageState extends State<AddTotpPage> {
  late final AddTotpViewModel _viewModel;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<TotpFormState> _totpFormKey = GlobalKey<TotpFormState>();

  // Valeurs initiales du formulaire (renseignées après un scan QR réussi).
  TotpDraft? _initialDraft;

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

  Future<void> _scan() async {
    final draft = await Navigator.of(
      context,
    ).push<TotpDraft>(MaterialPageRoute(builder: (_) => const ScanTotpPage()));
    if (draft == null || !mounted) return;
    setState(() {
      _initialDraft = draft;
      // Nouvelles clés : recrée le formulaire avec les valeurs scannées.
      _formKey = GlobalKey<FormState>();
      _totpFormKey = GlobalKey<TotpFormState>();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code lu. Vérifiez puis enregistrez.')),
    );
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
                  SecondaryButton(
                    onPressed: _viewModel.isSubmitting ? null : _scan,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text('Scanner un QR code'),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  TotpForm(
                    key: _totpFormKey,
                    formKey: _formKey,
                    profiles: _viewModel.profiles,
                    initial: _initialDraft,
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
