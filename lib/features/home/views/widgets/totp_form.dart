import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/base32.dart';
import '../../data/totp_draft.dart';
import '../../data/totp_generator.dart';

/// Formulaire partagé d'un TOTP (ajout & édition). Possède ses propres
/// contrôleurs ; l'état est lisible via [TotpFormState.buildDraft]
/// (exposé par une [GlobalKey]).
class TotpForm extends StatefulWidget {
  const TotpForm({
    required this.formKey,
    required this.profiles,
    this.initial,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final List<Profile> profiles;
  final TotpDraft? initial;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  State<TotpForm> createState() => TotpFormState();
}

class TotpFormState extends State<TotpForm> {
  late final TextEditingController _label;
  late final TextEditingController _account;
  late final TextEditingController _secret;
  late int _digits;
  late int _period;
  late TotpAlgorithm _algorithm;
  int? _profileId;
  bool _showAdvanced = false;

  static const _digitChoices = [6, 8];
  static const _periodChoices = [30, 60];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _label = TextEditingController(text: initial?.label ?? '')
      ..addListener(_notify);
    _account = TextEditingController(text: initial?.account ?? '')
      ..addListener(_notify);
    _secret = TextEditingController(text: initial?.secret ?? '')
      ..addListener(_notify);
    _digits = initial?.digits ?? 6;
    _period = initial?.period ?? 30;
    _algorithm = totpAlgorithmFromName(initial?.algorithm ?? 'SHA1');
    _profileId = initial?.profileId;
    // Déplie d'emblée si des valeurs non standard sont déjà définies.
    _showAdvanced =
        _digits != 6 || _period != 30 || _algorithm != TotpAlgorithm.sha1;
  }

  @override
  void dispose() {
    _label.dispose();
    _account.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call();

  TotpDraft buildDraft() => TotpDraft(
    label: _label.text.trim(),
    account: _account.text.trim().isEmpty ? null : _account.text.trim(),
    secret: _secret.text.replaceAll(' ', '').trim(),
    digits: _digits,
    period: _period,
    algorithm: totpAlgorithmName(_algorithm),
    profileId: _profileId,
    favorite: widget.initial?.favorite ?? false,
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _label,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Libellé',
              hintText: 'GitHub',
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Veuillez saisir un libellé.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _account,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Compte (optionnel)',
              hintText: 'me@example.com',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _secret,
            enabled: widget.enabled,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Secret (Base32)',
              hintText: 'JBSWY3DPEHPK3PXP',
            ),
            validator: (value) => Base32.isValid(value ?? '')
                ? null
                : 'Secret Base32 invalide.',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.profiles.isNotEmpty) ...[
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
                      _notify();
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
            label: const Text('Options avancées'),
          ),
        ),
        if (_showAdvanced) ...[
          _buildChoice<int>(
            label: 'Chiffres',
            value: _digits,
            choices: _digitChoices,
            labelOf: (v) => '$v',
            onChanged: (v) => setState(() => _digits = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildChoice<int>(
            label: 'Période (s)',
            value: _period,
            choices: _periodChoices,
            labelOf: (v) => '$v',
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildChoice<TotpAlgorithm>(
            label: 'Algorithme',
            value: _algorithm,
            choices: TotpAlgorithm.values,
            labelOf: totpAlgorithmName,
            onChanged: (v) => setState(() => _algorithm = v),
          ),
        ],
      ],
    );
  }

  Widget _buildChoice<T>({
    required String label,
    required T value,
    required List<T> choices,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        SegmentedButton<T>(
          segments: [
            for (final c in choices)
              ButtonSegment<T>(value: c, label: Text(labelOf(c))),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: widget.enabled
              ? (set) {
                  onChanged(set.first);
                  _notify();
                }
              : null,
        ),
      ],
    );
  }
}
