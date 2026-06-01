import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Dialog de confirmation forte pour la suppression de toutes les données :
/// l'utilisateur doit saisir explicitement un mot-clé pour activer le bouton.
///
/// Retourne `true` si l'utilisateur confirme, `null`/`false` sinon.
class DeleteDataDialog extends StatefulWidget {
  const DeleteDataDialog({super.key});

  /// Mot-clé à saisir pour confirmer.
  static const String confirmationKeyword = 'SUPPRIMER';

  @override
  State<DeleteDataDialog> createState() => _DeleteDataDialogState();
}

class _DeleteDataDialogState extends State<DeleteDataDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches =
          _controller.text.trim() == DeleteDataDialog.confirmationKeyword;
      if (matches != _canConfirm) {
        setState(() => _canConfirm = matches);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer toutes les données'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cette action est irréversible. Le coffre, le mot de passe maître '
            'et tous les réglages seront définitivement supprimés.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Saisissez « ${DeleteDataDialog.confirmationKeyword} » pour confirmer.',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: DeleteDataDialog.confirmationKeyword,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop(true)
              : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
