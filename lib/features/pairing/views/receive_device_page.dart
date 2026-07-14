import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../service/pairing_service.dart';
import '../viewmodels/pairing_receive_view_model.dart';
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
          builder: (context, _) =>
              Padding(padding: const EdgeInsets.all(24), child: _body(context)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Faites scanner ce code depuis un appareil déjà connecté à votre compte.',
        ),
        const SizedBox(height: 24),
        if (_viewModel.qrPayload != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(data: _viewModel.qrPayload!, size: 240),
            ),
          ),
        const SizedBox(height: 28),
        if (_viewModel.waiting)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("En attente de l'autre appareil…"),
            ],
          ),
      ],
    );
  }
}
