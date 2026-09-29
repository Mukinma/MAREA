import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

/// A shared light direction keeps relief consistent across MAREA surfaces.
abstract final class AppDepth {
  static const raised = [
    BoxShadow(color: Color(0xFFE1E5EA), offset: Offset(6, 6), blurRadius: 18),
    BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 14),
  ];
  static const floating = [
    BoxShadow(color: Color(0xFFD7DFE8), offset: Offset(6, 8), blurRadius: 24),
    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 12),
  ];
  static const action = [
    BoxShadow(color: Color(0x260D4397), offset: Offset(0, 5), blurRadius: 12),
  ];
  static BoxDecoration surface({
    double radius = 24,
    Color color = AppColors.surface,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: raised,
  );
}
