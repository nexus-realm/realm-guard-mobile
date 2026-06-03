import 'package:flutter/material.dart';

import '../../../../shared/widgets/destructive_button.dart';
import '../../data/profile_deletion_strategy.dart';

/// Dialog de suppression d'un profil.
///
/// Affiche le nombre d'identifiants liés. S'il y en a, l'utilisateur doit
/// choisir (sélection unique) entre dissocier ces identifiants ou les
/// supprimer en cascade. Retourne la [ProfileDeletionStrategy] choisie, ou
/// `null` si l'utilisateur annule.
class DeleteProfileDialog extends StatefulWidget {
  const DeleteProfileDialog({required this.linkedCount, super.key});

  final int linkedCount;

  static Future<ProfileDeletionStrategy?> show(
    BuildContext context, {
    required int linkedCount,
  }) {
    return showDialog<ProfileDeletionStrategy>(
      context: context,
      builder: (_) => DeleteProfileDialog(linkedCount: linkedCount),
    );
  }

  @override
  State<DeleteProfileDialog> createState() => _DeleteProfileDialogState();
}

class _DeleteProfileDialogState extends State<DeleteProfileDialog> {
  // Par défaut : option non destructive.
  ProfileDeletionStrategy _strategy = ProfileDeletionStrategy.dissociate;

  bool get _hasLinked => widget.linkedCount > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer le profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_hasLinked ? _linkedMessage() : _noLinkedMessage()),
          if (_hasLinked) ...[
            const SizedBox(height: 12),
            RadioGroup<ProfileDeletionStrategy>(
              groupValue: _strategy,
              onChanged: (value) {
                if (value != null) setState(() => _strategy = value);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ProfileDeletionStrategy>(
                    contentPadding: EdgeInsets.zero,
                    value: ProfileDeletionStrategy.dissociate,
                    title: Text('Conserver les identifiants'),
                    subtitle: Text('Ils ne seront plus associés à ce profil'),
                  ),
                  RadioListTile<ProfileDeletionStrategy>(
                    contentPadding: EdgeInsets.zero,
                    value: ProfileDeletionStrategy.cascade,
                    title: Text('Supprimer les identifiants'),
                    subtitle: Text('Les identifiants liés seront aussi effacés'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        DestructiveButton(
          onPressed: () => Navigator.of(context).pop(
            _hasLinked ? _strategy : ProfileDeletionStrategy.dissociate,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }

  String _noLinkedMessage() =>
      'Voulez-vous vraiment supprimer ce profil ? Cette action est '
      'irréversible.';

  String _linkedMessage() {
    final count = widget.linkedCount;
    final plural = count > 1 ? 's' : '';
    return '$count identifiant$plural ${count > 1 ? 'sont' : 'est'} '
        'associé$plural à ce profil. Que souhaitez-vous en faire ?';
  }
}
