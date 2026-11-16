import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class CategoryVisual {
  const CategoryVisual(
    this.color,
    this.icon, {
    this.iconColor = AppColors.brandNavy,
  });
  final Color color;
  final IconData icon;
  final Color iconColor;
}

abstract final class CategoryVisuals {
  static const values = {
    'arte': CategoryVisual(
      Color(0xFFFFE1DC),
      Icons.palette_outlined,
      iconColor: Color(0xFFF26D5B),
    ),
    'gastronomia': CategoryVisual(
      Color(0xFFDDF5ED),
      Icons.restaurant_rounded,
      iconColor: Color(0xFF2D9B80),
    ),
    'moda': CategoryVisual(
      Color(0xFFFFDDED),
      Icons.checkroom_rounded,
      iconColor: Color(0xFFF04F9B),
    ),
    'digital': CategoryVisual(
      Color(0xFFDCE9FF),
      Icons.devices_rounded,
      iconColor: Color(0xFF3B7DD6),
    ),
    'musica': CategoryVisual(
      Color(0xFFECE2FF),
      Icons.music_note_rounded,
      iconColor: Color(0xFF8156CC),
    ),
    'escritura': CategoryVisual(
      Color(0xFFFFF0C9),
      Icons.edit_note_rounded,
      iconColor: Color(0xFFD69A18),
    ),
    'fotografia': CategoryVisual(
      Color(0xFFDDF2F3),
      Icons.camera_alt_outlined,
      iconColor: Color(0xFF2B9294),
    ),
    'diseno': CategoryVisual(
      Color(0xFFDFF2E7),
      Icons.design_services_outlined,
      iconColor: Color(0xFF3A9675),
    ),
    'otros': CategoryVisual(AppColors.paper, Icons.auto_awesome_outlined),
  };
  // The three visual roles used by the profile interest chips.
  static const profileInterests =
      <String, ({IconData icon, Color color, Color accent})>{
        'arte': (
          icon: Icons.palette_outlined,
          color: Color(0xFFFFE5DF),
          accent: Color(0xFFE46C55),
        ),
        'musica': (
          icon: Icons.music_note_outlined,
          color: Color(0xFFECE4FF),
          accent: Color(0xFF7750C9),
        ),
        'digital': (
          icon: Icons.computer_outlined,
          color: Color(0xFFDEECFF),
          accent: Color(0xFF316CC4),
        ),
        'gastronomia': (
          icon: Icons.restaurant_outlined,
          color: Color(0xFFDDF5EF),
          accent: Color(0xFF178E7B),
        ),
        'moda': (
          icon: Icons.checkroom_outlined,
          color: Color(0xFFFFE0EE),
          accent: Color(0xFFE94E92),
        ),
        'escritura': (
          icon: Icons.edit_outlined,
          color: Color(0xFFFFF0CC),
          accent: Color(0xFFB78013),
        ),
        'fotografia': (
          icon: Icons.photo_camera_outlined,
          color: Color(0xFFDFF3F3),
          accent: Color(0xFF23858A),
        ),
        'diseno': (
          icon: Icons.design_services_outlined,
          color: Color(0xFFE4F3E9),
          accent: Color(0xFF398569),
        ),
      };

  static ({IconData icon, Color color, Color accent}) forProfileInterest(
    String value,
  ) =>
      profileInterests[value] ??
      (
        icon: values['otros']!.icon,
        color: AppColors.paper,
        accent: AppColors.brandNavy,
      );

  static CategoryVisual forCategory(String value) =>
      values[value] ?? values['otros']!;
}
