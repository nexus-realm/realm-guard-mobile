import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/otpauth_parser.dart';
import '../data/totp_draft.dart';

/// Écran de scan d'un QR code de configuration TOTP (`otpauth://`).
///
/// Retourne le [TotpDraft] extrait via `Navigator.pop` ; l'appelant pré-remplit
/// le formulaire d'ajout. Les QR non reconnus n'interrompent pas le scan.
class ScanTotpPage extends StatefulWidget {
  const ScanTotpPage({super.key});

  @override
  State<ScanTotpPage> createState() => _ScanTotpPageState();
}

class _ScanTotpPageState extends State<ScanTotpPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      try {
        final draft = OtpauthParser.parse(raw);
        _handled = true;
        Navigator.of(context).pop<TotpDraft>(draft);
        return;
      } on FormatException {
        // QR non-TOTP : on signale et on continue de scanner.
        _showInvalid();
        return;
      }
    }
  }

  void _showInvalid() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('QR code non reconnu (TOTP attendu).')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un QR code'),
        actions: [
          IconButton(
            tooltip: 'Lampe',
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Changer de caméra',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Repère visuel de cadrage.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mainColor, width: 3),
                borderRadius: AppRadius.lgAll,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Text(
              'Placez le QR code de configuration dans le cadre.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
