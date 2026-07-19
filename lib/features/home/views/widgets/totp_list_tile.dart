import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snackbar.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/totp_generator.dart';

/// Tuile de liste d'un TOTP : code courant (rafraîchi automatiquement), compte
/// associé, et anneau de validité décomptant la période. Tap = copier le code.
class TotpListTile extends StatefulWidget {
  const TotpListTile({
    required this.totp,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final Totp totp;

  /// Texte secondaire (compte ou profil associé).
  final String subtitle;

  /// Action d'ouverture (détail). Le tap sur la tuile copie le code ; une icône
  /// dédiée mène au détail.
  final VoidCallback? onTap;

  @override
  State<TotpListTile> createState() => _TotpListTileState();
}

class _TotpListTileState extends State<TotpListTile> {
  Timer? _ticker;
  String _code = '';
  double _progress = 0;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Tick 1 s : suffisant pour l'anneau et la régénération à l'expiration.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didUpdateWidget(TotpListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le secret ou les paramètres ont changé (édition) : régénérer.
    if (oldWidget.totp.secret != widget.totp.secret ||
        oldWidget.totp.period != widget.totp.period ||
        oldWidget.totp.digits != widget.totp.digits ||
        oldWidget.totp.algorithm != widget.totp.algorithm) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final period = widget.totp.period;
    final remaining = TotpGenerator.remainingSeconds(period: period);
    final progress = TotpGenerator.progress(period: period);

    String code;
    try {
      code = await TotpGenerator.generate(
        secretBase32: widget.totp.secret,
        digits: widget.totp.digits,
        period: period,
        algorithm: totpAlgorithmFromName(widget.totp.algorithm),
      );
    } catch (_) {
      code = 'Secret invalide';
    }

    if (!mounted) return;
    setState(() {
      _code = code;
      _remaining = remaining;
      _progress = progress;
    });
  }

  /// Formate « 123456 » → « 123 456 » pour la lisibilité.
  String get _formattedCode {
    if (_code.length < 6) return _code;
    final mid = (_code.length / 2).ceil();
    return '${_code.substring(0, mid)} ${_code.substring(mid)}';
  }

  void _copyCode() {
    if (_code.isEmpty || _code == 'Secret invalide') return;
    Clipboard.setData(ClipboardData(text: _code));
    AppSnackbar.info(context, 'Code copié dans le presse-papiers.');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // L'anneau passe en couleur d'alerte dans les dernières secondes.
    final urgent = _remaining <= 5;
    final ringColor = urgent ? AppColors.error : AppColors.mainColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Material(
        color: AppColors.secondaryBackground,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black54,
        child: InkWell(
          onTap: _copyCode,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.totp.label,
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _formattedCode,
                        style: textTheme.titleMedium?.copyWith(
                          letterSpacing: 2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          widget.subtitle,
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ValidityRing(
                  progress: _progress,
                  remaining: _remaining,
                  color: ringColor,
                ),
                if (widget.onTap != null)
                  IconButton(
                    tooltip: 'Détails',
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.neutralAction,
                    onPressed: widget.onTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Anneau circulaire de progression affichant les secondes restantes au centre.
class _ValidityRing extends StatelessWidget {
  const _ValidityRing({
    required this.progress,
    required this.remaining,
    required this.color,
  });

  final double progress;
  final int remaining;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1 - progress,
            strokeWidth: 3,
            backgroundColor: AppColors.mainBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$remaining',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
