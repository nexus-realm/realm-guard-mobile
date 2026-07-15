import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Affiche le **QR de pairing** du nouvel appareil + l'état d'attente.
///
/// En **debug uniquement**, expose aussi le **payload en texte sélectionnable** (+ un
/// bouton copier) : deux **émulateurs** n'ont pas de caméra réelle, on fait donc
/// transiter le payload à la main. Le QR n'est qu'un transport de cette chaîne — le
/// reste du protocole est strictement identique à un vrai scan.
class PairingQrView extends StatelessWidget {
  const PairingQrView({
    required this.qrPayload,
    required this.waiting,
    super.key,
  });

  final String? qrPayload;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final payload = qrPayload;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Faites scanner ce code depuis un appareil déjà connecté à votre compte.',
        ),
        const SizedBox(height: 24),
        if (payload != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(data: payload, size: 220),
            ),
          ),
        const SizedBox(height: 24),
        if (waiting)
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
        if (kDebugMode && payload != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Payload (debug) — sélectionner puis copier, ou le récupérer dans la '
            'console (« [pairing] QR payload: … »).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              payload,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Payload copié')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier le payload'),
          ),
        ],
      ],
    );
  }
}
