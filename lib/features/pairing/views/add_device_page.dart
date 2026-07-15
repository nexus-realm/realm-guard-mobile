import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/security/vault_service.dart';
import '../service/pairing_service.dart';
import '../viewmodels/pairing_source_view_model.dart';
import 'pairing_result_views.dart';

/// Écran **appareil source** : scanne le QR du nouvel appareil, demande une
/// **confirmation d'identité** (biométrie, ou code de l'appareil en repli), scelle la
/// VaultKey et la dépose, puis montre le SAS.
///
/// En **debug**, un champ permet de coller/saisir le payload à la main (deux
/// émulateurs n'ont pas de caméra réelle) — il emprunte exactement le même chemin
/// qu'un vrai scan.
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
  final TextEditingController _debugPayloadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = PairingSourceViewModel(
      service: widget.pairingService,
      vaultKeyProvider: () {
        final vaultKey = widget.vaultService.vaultKey;
        return vaultKey == null ? null : Uint8List.fromList(vaultKey);
      },
      // Gate d'autorisation avant d'exfiltrer la VaultKey. `biometricOnly: false`
      // accepte le **code de l'appareil** en repli : le but du gate est de prouver
      // que c'est bien l'utilisateur (et non quelqu'un qui a saisi un téléphone
      // déverrouillé) — un PIN/schéma remplit ce rôle. Sans ce repli, un appareil
      // sans biométrie ne pourrait **jamais** en appairer un autre.
      authorize: () => LocalAuthentication().authenticate(
        localizedReason: 'Autoriser le partage du coffre avec cet appareil',
        biometricOnly: false,
        sensitiveTransaction: true,
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _debugPayloadController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value != null) _viewModel.onQrScanned(value);
  }

  /// Debug : pré-remplit le champ depuis le presse-papiers (si le partage marche).
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final payload = data?.text?.trim();
    if (payload == null || payload.isEmpty) return;
    _debugPayloadController.text = payload;
  }

  /// Debug : injecte le payload saisi — **même chemin** qu'un vrai scan.
  Future<void> _submitDebugPayload() async {
    final payload = _debugPayloadController.text.trim();
    if (payload.isEmpty) return;
    await _viewModel.onQrScanned(payload);
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
          flex: 3,
          child: MobileScanner(controller: _scanner, onDetect: _onDetect),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Scannez le QR affiché sur le nouvel appareil.',
                  textAlign: TextAlign.center,
                ),
                if (_viewModel.busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _debugPayloadController,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Payload QR (debug)',
                      hintText: 'Coller le payload du nouvel appareil',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewModel.busy
                              ? null
                              : _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Coller'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _viewModel.busy
                              ? null
                              : _submitDebugPayload,
                          icon: const Icon(Icons.check),
                          label: const Text('Valider'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
