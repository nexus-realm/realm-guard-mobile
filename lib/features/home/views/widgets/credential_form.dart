import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snackbar.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/credential_draft.dart';
import '../../data/custom_field.dart';
import 'password_strength_indicator.dart';

/// Formulaire partagé d'identifiant (ajout & édition).
///
/// Possède ses propres contrôleurs. L'état courant est lisible via
/// [CredentialFormState.buildDraft] (exposé par une [GlobalKey]).
class CredentialForm extends StatefulWidget {
  const CredentialForm({
    required this.formKey,
    required this.profiles,
    this.initial,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final List<Profile> profiles;

  /// Valeurs initiales (édition). `null` pour une création.
  final CredentialDraft? initial;
  final bool enabled;

  /// Notifie le parent à chaque modification (pour activer/détecter les
  /// changements).
  final VoidCallback? onChanged;

  @override
  State<CredentialForm> createState() => CredentialFormState();
}

class CredentialFormState extends State<CredentialForm> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _uri;
  late final TextEditingController _notes;
  late int? _profileId;
  late bool _favorite;
  late List<_CustomFieldControllers> _customFields;
  bool _passwordObscured = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _username = TextEditingController(text: initial?.username ?? '');
    _password = TextEditingController(text: initial?.password ?? '');
    _uri = TextEditingController(text: initial?.uri ?? '');
    _notes = TextEditingController(text: initial?.notes ?? '');
    _profileId = initial?.profileId;
    _favorite = initial?.favorite ?? false;
    _customFields = [
      for (final field in initial?.customFields ?? const <CustomField>[])
        _CustomFieldControllers.fromField(field),
    ];
    for (final controller in [_title, _username, _password, _uri, _notes]) {
      controller.addListener(_notifyChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [_title, _username, _password, _uri, _notes]) {
      controller.dispose();
    }
    for (final field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _notifyChanged() => widget.onChanged?.call();

  /// Construit le brouillon à partir des champs actuels.
  CredentialDraft buildDraft() {
    return CredentialDraft(
      title: _title.text.trim(),
      username: _nullIfEmpty(_username.text),
      password: _nullIfEmpty(_password.text),
      uri: _nullIfEmpty(_uri.text),
      notes: _nullIfEmpty(_notes.text),
      favorite: _favorite,
      profileId: _profileId,
      customFields: _customFields
          .map((c) => c.toField())
          .where((f) => f.label.trim().isNotEmpty || f.value.trim().isNotEmpty)
          .toList(),
    );
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _addCustomField() {
    setState(() => _customFields.add(_CustomFieldControllers.empty()));
    _notifyChanged();
  }

  void _removeCustomField(int index) {
    setState(() => _customFields.removeAt(index).dispose());
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Titre'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Veuillez saisir un titre.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _username,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nom d\'utilisateur',
              suffixIcon: _CopyButton(
                value: _username.text,
                enabled: _username.text.isNotEmpty,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            enabled: widget.enabled,
            obscureText: _passwordObscured,
            // Reconstruit le champ à chaque frappe pour rafraîchir l'indicateur
            // de force et l'état du bouton copier.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _passwordObscured ? 'Afficher' : 'Masquer',
                    icon: Icon(
                      _passwordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _passwordObscured = !_passwordObscured),
                  ),
                  _CopyButton(
                    value: _password.text,
                    enabled: _password.text.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
          PasswordStrengthIndicator(password: _password.text),
          const SizedBox(height: 16),
          TextFormField(
            controller: _uri,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Site / URL',
              hintText: 'https://exemple.com',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.star_outline),
            title: const Text('Favori'),
            value: _favorite,
            onChanged: widget.enabled
                ? (value) {
                    setState(() => _favorite = value);
                    _notifyChanged();
                  }
                : null,
          ),
          if (widget.profiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _profileId,
              decoration: const InputDecoration(
                labelText: 'Profil associé (optionnel)',
              ),
              items: [
                const DropdownMenuItem<int?>(child: Text('Aucun profil')),
                ...widget.profiles.map(
                  (p) =>
                      DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
                ),
              ],
              onChanged: widget.enabled
                  ? (value) {
                      setState(() => _profileId = value);
                      _notifyChanged();
                    }
                  : null,
            ),
          ],
          const SizedBox(height: 24),
          _buildCustomFieldsSection(context),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Champs personnalisés',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _customFields.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CustomFieldRow(
              controllers: _customFields[index],
              enabled: widget.enabled,
              onChanged: _notifyChanged,
              onRemove: widget.enabled ? () => _removeCustomField(index) : null,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.enabled ? _addCustomField : null,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un champ'),
          ),
        ),
      ],
    );
  }
}

/// Bouton de copie d'une valeur vers le presse-papiers.
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value, required this.enabled});

  final String value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copier',
      icon: const Icon(Icons.copy, size: 20),
      onPressed: enabled
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              AppSnackbar.info(context, 'Copié dans le presse-papiers.');
            }
          : null,
    );
  }
}

class _CustomFieldRow extends StatelessWidget {
  const _CustomFieldRow({
    required this.controllers,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final _CustomFieldControllers controllers;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              TextFormField(
                controller: controllers.label,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Libellé'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controllers.value,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Valeur'),
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        Column(
          children: [
            IconButton(
              tooltip: 'Supprimer ce champ',
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.destructive,
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}

/// Contrôleurs d'un champ personnalisé (libellé + valeur).
class _CustomFieldControllers {
  _CustomFieldControllers({
    required this.label,
    required this.value,
    required this.secret,
  });

  factory _CustomFieldControllers.empty() => _CustomFieldControllers(
    label: TextEditingController(),
    value: TextEditingController(),
    secret: false,
  );

  factory _CustomFieldControllers.fromField(CustomField field) =>
      _CustomFieldControllers(
        label: TextEditingController(text: field.label),
        value: TextEditingController(text: field.value),
        secret: field.secret,
      );

  final TextEditingController label;
  final TextEditingController value;
  final bool secret;

  CustomField toField() =>
      CustomField(label: label.text, value: value.text, secret: secret);

  void dispose() {
    label.dispose();
    value.dispose();
  }
}
