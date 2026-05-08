import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GradientFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? _icon;
  final BorderRadius _borderRadius;

  const GradientFilledButton({
    required this.onPressed,
    required this.child,
    super.key,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  })  : _icon = null,
        _borderRadius = borderRadius;

  const GradientFilledButton.icon({
    required this.onPressed,
    required Widget icon,
    required Widget label,
    super.key,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  })  : child = label,
        _icon = icon,
        _borderRadius = borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    final foregroundColor =
        isEnabled ? AppColors.buttonText : AppColors.buttonText.withValues(alpha: 0.55);

    final gradient = isEnabled
        ? LinearGradient(colors: [colorScheme.primary, colorScheme.secondary])
        : LinearGradient(
            colors: [
              colorScheme.onSurface.withValues(alpha: 0.16),
              colorScheme.onSurface.withValues(alpha: 0.10),
            ],
          );

    final content = _icon == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _icon,
              const SizedBox(width: 8),
              child,
            ],
          );

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: foregroundColor,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        padding: EdgeInsets.zero,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: _borderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: IconTheme(
            data: IconThemeData(color: foregroundColor),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}



