import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/profile_colors.dart';
import '../../data/profile_draft.dart';

/// Formulaire partagé de profil (ajout & édition).
///
/// Possède ses propres contrôleurs. L'état courant est lisible via
/// [ProfileFormState.buildDraft] (exposé par une [GlobalKey]).
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    required this.formKey,
    this.initial,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final ProfileDraft? initial;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  State<ProfileForm> createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late List<TextEditingController> _emails;
  late List<TextEditingController> _usernames;
  late List<TextEditingController> _phones;
  int? _color;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '')
      ..addListener(_notify);
    _note = TextEditingController(text: initial?.note ?? '')
      ..addListener(_notify);
    _emails = _seed(initial?.emails);
    _usernames = _seed(initial?.usernames);
    _phones = _seed(initial?.phoneNumbers);
    _color = initial?.color;
  }

  List<TextEditingController> _seed(List<String>? values) {
    final list = [
      for (final v in values ?? const <String>[])
        TextEditingController(text: v),
    ];
    if (list.isEmpty) list.add(TextEditingController());
    return list;
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    for (final list in [_emails, _usernames, _phones]) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notify() => widget.onChanged?.call();

  ProfileDraft buildDraft() {
    return ProfileDraft(
      name: _name.text.trim(),
      emails: _values(_emails),
      usernames: _values(_usernames),
      phoneNumbers: _values(_phones),
      color: _color,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
  }

  List<String> _values(List<TextEditingController> list) =>
      list.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Veuillez saisir un nom de profil.'
                : null,
          ),
          const SizedBox(height: 24),
          _ColorPicker(
            selected: _color,
            enabled: widget.enabled,
            onSelected: (value) {
              setState(() => _color = value);
              _notify();
            },
          ),
          const SizedBox(height: 24),
          _DynamicList(
            title: 'Emails',
            addLabel: 'Ajouter un email',
            singular: 'Email',
            controllers: _emails,
            enabled: widget.enabled,
            keyboardType: TextInputType.emailAddress,
            onChanged: _notify,
            onMutate: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          _DynamicList(
            title: 'Noms d\'utilisateur',
            addLabel: 'Ajouter un nom d\'utilisateur',
            singular: 'Nom d\'utilisateur',
            controllers: _usernames,
            enabled: widget.enabled,
            onChanged: _notify,
            onMutate: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          _DynamicList(
            title: 'Téléphones',
            addLabel: 'Ajouter un téléphone',
            singular: 'Téléphone',
            controllers: _phones,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            onChanged: _notify,
            onMutate: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _note,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Note',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de couleur par pastilles (palette fixe). `null` = aucune couleur.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final int? selected;
  final bool enabled;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Couleur', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Dot(
              color: null,
              isSelected: selected == null,
              enabled: enabled,
              onTap: () => onSelected(null),
            ),
            for (final color in ProfileColors.palette)
              _Dot(
                color: color,
                isSelected: selected == color.toARGB32(),
                enabled: enabled,
                onTap: () => onSelected(color.toARGB32()),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final Color? color;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? AppColors.secondaryBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.mainColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: color == null
            ? const Icon(Icons.not_interested, size: 20)
            : (isSelected ? const Icon(Icons.check, size: 20) : null),
      ),
    );
  }
}

/// Liste dynamique de champs texte (ajout/suppression), avec un titre.
class _DynamicList extends StatelessWidget {
  const _DynamicList({
    required this.title,
    required this.addLabel,
    required this.singular,
    required this.controllers,
    required this.enabled,
    required this.onChanged,
    required this.onMutate,
    this.keyboardType,
  });

  final String title;
  final String addLabel;
  final String singular;
  final List<TextEditingController> controllers;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onMutate;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < controllers.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    enabled: enabled,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: '$singular ${index + 1}',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    tooltip: 'Supprimer',
                    color: AppColors.destructive,
                    onPressed: enabled
                        ? () {
                            controllers.removeAt(index).dispose();
                            onMutate();
                            onChanged();
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: enabled
                ? () {
                    controllers.add(TextEditingController());
                    onMutate();
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}
