import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/security/vault_service.dart';
import '../service/pairing_service.dart';
import '../viewmodels/pairing_source_view_model.dart';
import 'pairing_result_views.dart';

/// Écran **appareil source** : scanne le QR du nouvel appareil, demande une
/// confirmation biométrique, scelle la VaultKey et la dépose, puis montre le SAS.
class AddDevicePage extends StatefulWidget {
  const AddDevicePage({
    required this.pairingService,
    required this.vaultService,
    super.key,
  });

  final PairingService pairingService;
  final VaultService vaultService;

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  late final PairingSourceViewModel _viewModel;
  final MobileScannerController _scanner = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _viewModel = PairingSourceViewModel(
      service: widget.pairingService,
      vaultKeyProvider: () {
        final vaultKey = widget.vaultService.vaultKey;
        return vaultKey == null ? null : Uint8List.fromList(vaultKey);
      },
      authorize: () => LocalAuthentication().authenticate(
        localizedReason: 'Autoriser le partage du coffre avec cet appareil',
        biometricOnly: true,
        sensitiveTransaction: true,
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value != null) _viewModel.onQrScanned(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un appareil')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final sas = _viewModel.sas;
            if (sas != null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: PairingSasView(sas: sas),
              );
            }
            return _scannerView(context);
          },
        ),
      ),
    );
  }

  Widget _scannerView(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(controller: _scanner, onDetect: _onDetect),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Scannez le QR affiché sur le nouvel appareil.',
                textAlign: TextAlign.center,
              ),
              if (_viewModel.busy) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (_viewModel.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _viewModel.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
