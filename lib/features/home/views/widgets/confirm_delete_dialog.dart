import 'package:flutter/material.dart';

import '../../../../shared/widgets/destructive_button.dart';

/// Dialog de confirmation de suppression simple (un seul élément, sans liaison).
/// Retourne `true` si l'utilisateur confirme.
class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({required this.itemLabel, super.key});

  /// Libellé de l'élément supprimé (ex. « cet identifiant »).
  final String itemLabel;

  static Future<bool> show(BuildContext context, {required String itemLabel}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(itemLabel: itemLabel),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: Text(
        'Voulez-vous vraiment supprimer $itemLabel ? Cette action est '
        'irréversible.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        DestructiveButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
