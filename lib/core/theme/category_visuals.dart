import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class CategoryVisual {
  const CategoryVisual(this.color, this.icon);
  final Color color;
  final IconData icon;
}

abstract final class CategoryVisuals {
  static const values = {
    'arte': CategoryVisual(Color(0xFFB8A1E3), Icons.palette_outlined),
    'gastronomia': CategoryVisual(Color(0xFFF6B17A), Icons.restaurant_rounded),
    'moda': CategoryVisual(Color(0xFFE9A6C4), Icons.checkroom_rounded),
    'digital': CategoryVisual(Color(0xFF79D7E5), Icons.devices_rounded),
    'musica': CategoryVisual(Color(0xFF9A8AE8), Icons.music_note_rounded),
    'escritura': CategoryVisual(Color(0xFFF4CE78), Icons.edit_note_rounded),
    'fotografia': CategoryVisual(AppColors.mint, Icons.camera_alt_outlined),
    'diseno': CategoryVisual(AppColors.mist, Icons.design_services_outlined),
    'otros': CategoryVisual(AppColors.paper, Icons.auto_awesome_outlined),
  };
  static CategoryVisual forCategory(String value) =>
      values[value] ?? values['otros']!;
}
