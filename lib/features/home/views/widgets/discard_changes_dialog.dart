import 'package:flutter/material.dart';

/// Demande confirmation avant d'abandonner des modifications non enregistrées.
/// Retourne `true` si l'utilisateur confirme l'abandon.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Abandonner les modifications ?'),
      content: const Text(
        'Vos modifications non enregistrées seront perdues.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Continuer l\'édition'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Abandonner'),
        ),
      ],
    ),
  );
  return result ?? false;
}
