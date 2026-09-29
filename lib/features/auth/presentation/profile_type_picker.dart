import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

extension AccessProfile on UserType {
  String get label => switch (this) {
    UserType.general => 'Persona',
    UserType.creator => 'Artista / creador',
    UserType.entrepreneur => 'Emprendimiento',
    UserType.business => 'Negocio',
  };
  String get shortDescription => switch (this) {
    UserType.general => 'Descubre y conecta',
    UserType.creator => 'Comparte tu trabajo',
    UserType.entrepreneur => 'Presenta tus productos y servicios',
    UserType.business => 'Ofrece servicios, espacios y eventos',
  };
  String get nameLabel => switch (this) {
    UserType.general => 'Tu nombre',
    UserType.creator => 'Nombre artístico',
    UserType.entrepreneur => 'Nombre del emprendimiento',
    UserType.business => 'Nombre del negocio',
  };
  IconData get icon => switch (this) {
    UserType.general => Icons.person_outline_rounded,
    UserType.creator => Icons.palette_outlined,
    UserType.entrepreneur => Icons.inventory_2_outlined,
    UserType.business => Icons.storefront_outlined,
  };
  Color get tint => switch (this) {
    UserType.general => AppColors.mist,
    UserType.creator => AppColors.mint,
    UserType.entrepreneur => AppColors.lavender,
    UserType.business => AppColors.peach,
  };
  int get setupSteps => switch (this) {
    UserType.general => 2,
    UserType.business => 4,
    _ => 3,
  };
}

class ProfileTypePicker extends StatelessWidget {
  const ProfileTypePicker({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final UserType? value;
  final ValueChanged<UserType?> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => RadioGroup<UserType>(
    groupValue: value,
    onChanged: enabled ? onChanged : (_) {},
    child: LayoutBuilder(
      builder: (context, bounds) {
        final columns =
            bounds.maxWidth >= 480 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3
            ? 2
            : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final type in UserType.values)
              SizedBox(
                width: (bounds.maxWidth - (columns - 1) * 16) / columns,
                child: MareaSurface(
                  color: value == type ? AppColors.mint : AppColors.paper,
                  inset: value == type,
                  radius: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: value == type
                            ? AppColors.actionBlue
                            : AppColors.softBorder,
                        width: value == type ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<UserType>(
                      key: Key('register-type-${type.name}'),
                      value: type,
                      enabled: enabled,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: ProfileTypeIcon(type: type),
                      title: Text(
                        type.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        type.shortDescription,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ProfileTypeIcon extends StatelessWidget {
  const ProfileTypeIcon({required this.type, super.key});
  final UserType type;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: MareaSurface(
      color: type.tint,
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Icon(type.icon, color: AppColors.brandNavy, size: 26),
    ),
  );
}
