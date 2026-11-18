import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/localization/app_localizations.dart';
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
    UserType.general => 'Explora y conecta con tu comunidad.',
    UserType.creator => 'Comparte tu trabajo y colabora.',
    UserType.entrepreneur => 'Da a conocer tu marca y lo que ofreces.',
    UserType.business => 'Muestra tus servicios y dónde encontrarte.',
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
    child: Column(
      spacing: 8,
      children: [
        for (final type in UserType.values)
          _ProfileTypeOption(
            key: Key('register-type-${type.name}'),
            type: type,
            enabled: enabled,
          ),
      ],
    ),
  );
}

class _ProfileTypeOption extends StatefulWidget {
  const _ProfileTypeOption({
    required this.type,
    required this.enabled,
    super.key,
  });

  final UserType type;
  final bool enabled;

  @override
  State<_ProfileTypeOption> createState() => _ProfileTypeOptionState();
}

class _ProfileTypeOptionState extends State<_ProfileTypeOption> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: RawRadio<UserType>(
      value: widget.type,
      focusNode: _focus,
      autofocus: false,
      toggleable: false,
      enabled: widget.enabled,
      mouseCursor: WidgetStateMouseCursor.clickable,
      groupRegistry: RadioGroup.maybeOf<UserType>(context),
      builder: (context, state) {
        final focused = state.states.contains(WidgetState.focused);
        final hovered = state.states.contains(WidgetState.hovered);
        final selected = state.value == true;
        return Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.mint
                : hovered || focused
                ? AppColors.mist
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused
                  ? AppColors.actionBlue
                  : selected
                  ? AppColors.aquaDark
                  : AppColors.border,
              width: focused ? 2 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            children: [
              AccessProfileIcon(type: widget.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      AppLocalizations.tr(widget.type.label),
                      style: const TextStyle(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppLocalizations.tr(widget.type.shortDescription),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? AppColors.aquaDark
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class AccessProfileIcon extends StatelessWidget {
  const AccessProfileIcon({required this.type, super.key});

  final UserType type;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: type.tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(type.icon, color: AppColors.brandNavy, size: 20),
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
