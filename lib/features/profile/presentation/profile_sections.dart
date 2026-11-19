import 'package:flutter/material.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/professional_details.dart';
import 'package:marea/core/localization/app_localizations.dart';

String localizedProfileUserTypeLabel(BuildContext context, UserType type) {
  return AppLocalizations.tr(switch (type) {
    UserType.general => 'Usuario general',
    UserType.creator => 'Artista / creador',
    UserType.entrepreneur => 'Emprendedor',
    UserType.business => 'Negocio',
  });
}

String localizedProfileUserTypeDescription(
  BuildContext context,
  UserType type,
) {
  return AppLocalizations.tr(switch (type) {
    UserType.general =>
      'Descubre personas, guarda lo que te inspira y participa en misiones.',
    UserType.creator =>
      'Comparte tu portafolio y encuentra personas para crear contigo.',
    UserType.entrepreneur =>
      'Presenta tus productos y servicios y encuentra nuevas colaboraciones.',
    UserType.business =>
      'Presenta tus servicios, comparte tu espacio y organiza eventos.',
  });
}

String localizedProfileInterestLabel(BuildContext context, String interest) {
  final label = switch (interest) {
    'arte' => 'Arte',
    'musica' => 'Música',
    'digital' => 'Digital',
    'gastronomia' => 'Gastronomía',
    'moda' => 'Moda',
    'escritura' => 'Escritura',
    'fotografia' => 'Fotografía',
    'diseno' => 'Diseño',
    _ => interest,
  };
  return AppLocalizations.tr(label);
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading({
    required this.title,
    this.action,
    this.onAction,
    this.wave = false,
    this.trailing,
    super.key,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool wave;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF07345C),
              ),
            ),
          ),
        ),
        if (wave)
          const SizedBox(
            width: 30,
            height: 12,
            child: CustomPaint(painter: _SectionWave()),
          ),
        ?trailing,
        if (action != null && onAction != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * .45),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                ),
              ),
              child: Text(
                '${AppLocalizations.tr(action!)} ›',
                textAlign: TextAlign.end,
              ),
            ),
          ),
      ],
    ),
  );
}

class ProfileAbout extends StatelessWidget {
  const ProfileAbout({required this.profile, this.onEdit, super.key});
  final CommunityProfile profile;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) {
    final bio = profile.bio?.trim() ?? '';
    final details = ProfessionalDetails(profile: profile);
    final hasInterests = profile.interests.isNotEmpty;
    if (bio.isEmpty && !details.hasContent && !hasInterests && onEdit == null) {
      return const SizedBox.shrink();
    }
    final professional =
        profile.userType == UserType.business ||
        profile.userType == UserType.entrepreneur;
    final needsIntroduction = bio.isEmpty && onEdit != null;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionHeading(
            title: AppLocalizations.tr(
              professional ? 'Sobre nosotros' : 'Sobre mí',
            ),
            wave: true,
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.42,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else if (needsIntroduction)
                  ListTile(
                    minTileHeight: 48,
                    leading: const Icon(
                      Icons.edit_note_outlined,
                      color: AppColors.brandNavy,
                    ),
                    title: Text(AppLocalizations.tr('Añadir descripción')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onEdit,
                  ),
                if (details.hasContent) ...[
                  if (bio.isNotEmpty || needsIntroduction)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  details,
                ],
                if (hasInterests) ...[
                  if (bio.isNotEmpty || needsIntroduction || details.hasContent)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ProfileInterests(interests: profile.interests),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInterests extends StatelessWidget {
  const _ProfileInterests({required this.interests});
  final List<String> interests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(
        AppLocalizations.tr('Me mueve'),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final interest in interests)
            Builder(
              builder: (context) {
                final style =
                    CategoryVisuals.profileInterests[interest] ??
                    CategoryVisuals.profileInterests['arte']!;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: style.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Icon(style.icon, size: 15, color: style.accent),
                      Flexible(
                        child: Text(
                          localizedProfileInterestLabel(context, interest),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ],
  );
}

class _SectionWave extends CustomPainter {
  const _SectionWave();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..cubicTo(
        size.width * .35,
        -size.height * .5,
        size.width * .55,
        size.height * 1.6,
        size.width,
        size.height * .5,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00A8C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_SectionWave oldDelegate) => false;
}
