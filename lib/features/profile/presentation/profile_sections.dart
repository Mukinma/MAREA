import 'package:flutter/material.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/professional_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/core/localization/app_localizations.dart';

String localizedProfileUserTypeLabel(BuildContext context, UserType type) {
  return AppLocalizations.tr(
    switch (type) {
      UserType.general => 'Usuario general',
      UserType.creator => 'Artista / creador',
      UserType.entrepreneur => 'Emprendedor',
      UserType.business => 'Negocio',
    },
  );
}

String localizedProfileUserTypeDescription(
  BuildContext context,
  UserType type,
) {
  return AppLocalizations.tr(
    switch (type) {
      UserType.general =>
        'Descubre personas, guarda lo que te inspira y participa en misiones.',
      UserType.creator =>
        'Comparte tu portafolio y encuentra personas para crear contigo.',
      UserType.entrepreneur =>
        'Presenta tus productos y servicios y encuentra nuevas colaboraciones.',
      UserType.business =>
        'Presenta tus servicios, comparte tu espacio y organiza eventos.',
    },
  );
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
    super.key,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool wave;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF07345C),
            ),
          ),
        ),
        if (wave)
          const SizedBox(
            width: 42,
            height: 16,
            child: CustomPaint(painter: _SectionWave()),
          ),
        if (action != null && onAction != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * .45),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 11,
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

class ProfileStatisticsCard extends StatelessWidget {
  const ProfileStatisticsCard({super.key});
  // There is no backend profile aggregate. Absence is never a numeric zero.
  static const _stats = [
    (Icons.assignment_turned_in_outlined, Color(0xFFDDF7FA), Color(0xFF00A6BF)),
    (Icons.star_border_rounded, Color(0xFFFFF3DA), Color(0xFFF5A400)),
    (Icons.bolt_rounded, Color(0xFFECE3FF), Color(0xFF7952DE)),
    (Icons.people_outline, Color(0xFFDDF7FA), Color(0xFF00A6BF)),
  ];
  @override
  Widget build(BuildContext context) {
    final labels = [
      AppLocalizations.tr('Misiones completadas'),
      AppLocalizations.tr('Valoración'),
      AppLocalizations.tr('Porcentaje de respuesta'),
      AppLocalizations.tr('Colaboraciones locales'),
    ];
    final noData = AppLocalizations.tr('Sin datos');
    return Material(
      key: const Key('profile-statistics'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(12) > 16
                ? 2
                : 4;
            return Wrap(
              runSpacing: 16,
              children: [
                for (var i = 0; i < _stats.length; i++)
                  SizedBox(
                    width: constraints.maxWidth / columns,
                    child: Semantics(
                      label: '${labels[i]}: $noData',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: i % columns == 0
                              ? null
                              : const Border(
                                  left: BorderSide(color: Color(0xFFEDF0F7)),
                                ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: _stats[i].$2,
                              child: Icon(
                                _stats[i].$1,
                                color: _stats[i].$3,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '—',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF07345C),
                              ),
                            ),
                            Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF607C98),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              noData,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF607C98),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProfileAbout extends StatelessWidget {
  const ProfileAbout({required this.profile, required this.owner, super.key});
  final CommunityProfile profile;
  final bool owner;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(
          title:
              profile.userType == UserType.business ||
                  profile.userType == UserType.entrepreneur
              ? AppLocalizations.tr('Sobre nosotros')
              : AppLocalizations.tr('Sobre mí'),
          wave: true,
        ),
        const SizedBox(height: 7),
        Text(
          profile.bio?.trim().isNotEmpty == true
              ? profile.bio!
              : AppLocalizations.tr(
                  'Este perfil aún no ha añadido una descripción.',
                ),
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFF607C98),
          ),
        ),
        ProfessionalDetails(
          profile: profile,
          showContact: !owner,
          showLocation: false,
        ),
        if (profile.website?.trim().isNotEmpty == true &&
            ProfilePreferences.websiteError(profile.website) == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => runCommunityAction(context, () async {
                if (!await launchUrl(
                  Uri.parse(profile.website!),
                  mode: LaunchMode.externalApplication,
                )) {
                  throw StateError('link unavailable');
                }
              }),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(AppLocalizations.tr('Sitio web')),
            ),
          ),
      ],
    );
  }
}

class ProfileInterests extends StatelessWidget {
  const ProfileInterests({required this.profile, this.onEdit, super.key});
  final CommunityProfile profile;
  final VoidCallback? onEdit;
  static const _styles = [
    (Icons.palette_outlined, Color(0xFFFFE5DF), Color(0xFFE46C55)),
    (Icons.music_note_outlined, Color(0xFFECE4FF), Color(0xFF7750C9)),
    (Icons.computer_outlined, Color(0xFFDEECFF), Color(0xFF316CC4)),
    (Icons.restaurant_outlined, Color(0xFFDDF5EF), Color(0xFF178E7B)),
    (Icons.checkroom_outlined, Color(0xFFFFE0EE), Color(0xFFE94E92)),
    (Icons.edit_outlined, Color(0xFFFFF0CC), Color(0xFFB78013)),
    (Icons.photo_camera_outlined, Color(0xFFDFF3F3), Color(0xFF23858A)),
    (Icons.design_services_outlined, Color(0xFFE4F3E9), Color(0xFF398569)),
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(
          title: AppLocalizations.tr('Me mueve'),
          action: onEdit == null ? null : 'Editar intereses',
          onAction: onEdit,
        ),
        const SizedBox(height: 4),
        if (profile.interests.isEmpty)
          Text(
            AppLocalizations.tr('Aún no hay intereses seleccionados.'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF607C98)),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final interest in profile.interests)
              Builder(
                builder: (context) {
                  final index = ProfilePreferences.interests.keys
                      .toList()
                      .indexOf(interest);
                  final style = _styles[index < 0 ? 0 : index % _styles.length];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: style.$2,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.$1, size: 15, color: style.$3),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            localizedProfileInterestLabel(context, interest),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF07345C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (onEdit != null)
              IconButton.outlined(
                tooltip: AppLocalizations.tr('Añadir intereses'),
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.all(6),
                ),
                icon: const Icon(Icons.add, size: 18),
              ),
          ],
        ),
      ],
    );
  }
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
