import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NeonBoxDecoration {
  static BoxDecoration get neonBoxDecoration => BoxDecoration(
    color: AppColors.mainColor,
    borderRadius: const BorderRadius.all(Radius.circular(2)),
    boxShadow: [
      BoxShadow(color: AppColors.mainColor.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
      BoxShadow(color: AppColors.mainColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 0),
      BoxShadow(color: AppColors.mainColor.withValues(alpha: 0.8), blurRadius: 4, spreadRadius: 0),
    ],
  );
}