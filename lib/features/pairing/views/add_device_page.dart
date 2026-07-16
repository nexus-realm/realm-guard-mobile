import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/security/vault_service.dart';
import '../../auth/service/auth_service.dart';
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
    required this.authService,
    super.key,
  });

  final PairingService pairingService;
  final VaultService vaultService;
  final AuthService authService;

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
      // Le compte à sceller dans le blob : le nouvel appareil apprend ainsi lequel
      // il rejoint (il n'a pas de session pour le demander lui-même).
      accountIdProvider: () => widget.authService.currentAccountId(),
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
            if (_viewModel.registered) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: PairingStatusView(
                  icon: Icons.check_circle_outline,
                  title: 'Appareil autorisé',
                  message:
                      'Il est inscrit sur votre compte et peut se synchroniser.',
                ),
              );
            }
            final sas = _viewModel.sas;
            if (sas != null) return _sasConfirmationView(context, sas);
            return _scannerView(context);
          },
        ),
      ),
    );
  }

  /// Confirmation **explicite** du SAS. Rien n'est inscrit au compte tant que
  /// l'utilisateur n'a pas confirmé que les deux codes correspondent : la clé vient
  /// du QR scanné, donc un QR substitué inscrirait l'appareil d'un attaquant.
  Widget _sasConfirmationView(BuildContext context, String sas) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(child: PairingSasView(sas: sas)),
          ),
          if (_viewModel.error != null) ...[
            Text(
              _viewModel.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Ce code est-il identique à celui affiché sur le nouvel appareil ?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _viewModel.busy ? null : _viewModel.confirmSas,
            icon: const Icon(Icons.check),
            label: const Text('Oui, autoriser cet appareil'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _viewModel.busy ? null : _viewModel.rejectSas,
            child: const Text('Non, les codes diffèrent'),
          ),
        ],
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
