import 'package:flutter/material.dart';

import '../service/pairing_service.dart';
import '../viewmodels/pairing_receive_view_model.dart';
import 'pairing_qr_view.dart';
import 'pairing_result_views.dart';

/// Écran **nouvel appareil** : affiche un QR à faire scanner par un appareil déjà
/// connecté, attend le transfert, puis montre le SAS à comparer.
class ReceiveDevicePage extends StatefulWidget {
  const ReceiveDevicePage({required this.pairingService, super.key});

  final PairingService pairingService;

  @override
  State<ReceiveDevicePage> createState() => _ReceiveDevicePageState();
}

class _ReceiveDevicePageState extends State<ReceiveDevicePage> {
  late final PairingReceiveViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PairingReceiveViewModel(service: widget.pairingService);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lier cet appareil')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final error = _viewModel.error;
    if (error != null) {
      return PairingStatusView(
        icon: Icons.error_outline,
        title: 'Pairing échoué',
        message: error,
      );
    }

    final sas = _viewModel.sas;
    if (sas != null) {
      return PairingSasView(
        sas: sas,
        footer: 'Coffre reçu. (Installation sur cet appareil : à venir.)',
      );
    }

    return PairingQrView(
      qrPayload: _viewModel.qrPayload,
      waiting: _viewModel.waiting,
    );
  }
}
