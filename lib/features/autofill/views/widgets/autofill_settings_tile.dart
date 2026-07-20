import 'package:flutter/material.dart';

import '../../viewmodels/autofill_settings_view_model.dart';

/// Tuile de réglage « Remplissage automatique » : affiche le statut du service
/// d'autofill de l'OS et permet de l'activer (ouvre les réglages système) ou de
/// le désactiver.
///
/// Se rafraîchit au retour au premier plan, car l'activation s'effectue dans les
/// réglages système, en dehors de l'application.
class AutofillSettingsTile extends StatefulWidget {
  const AutofillSettingsTile({required this.viewModel, super.key});

  final AutofillSettingsViewModel viewModel;

  @override
  State<AutofillSettingsTile> createState() => _AutofillSettingsTileState();
}

class _AutofillSettingsTileState extends State<AutofillSettingsTile>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.viewModel.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.viewModel.refresh();
    }
  }

  Future<void> _onChanged(bool value) async {
    if (value) {
      await widget.viewModel.enable();
    } else {
      await widget.viewModel.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return SwitchListTile(
          secondary: const Icon(Icons.keyboard_outlined),
          title: const Text('Remplissage automatique'),
          subtitle: Text(
            vm.isSupported
                ? 'Proposer vos identifiants dans les autres applications'
                : 'Indisponible sur cet appareil',
          ),
          value: vm.isEnabled,
          onChanged: vm.isSupported && !vm.isBusy ? _onChanged : null,
        );
      },
    );
  }
}
