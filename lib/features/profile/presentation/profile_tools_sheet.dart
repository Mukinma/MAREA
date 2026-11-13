import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/core/localization/app_localizations.dart';

Future<String?> showProfileTools(
  BuildContext context, {
  required CommunityProfile profile,
  required AppSessionController controller,
  required bool admin,
}) => showMareaBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) =>
      _ProfileTools(profile: profile, controller: controller, admin: admin),
);

class _ProfileTools extends StatelessWidget {
  const _ProfileTools({
    required this.profile,
    required this.controller,
    required this.admin,
  });
  final CommunityProfile profile;
  final AppSessionController controller;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    if (controller.profile?.id != profile.id) {
      return _VisitorProfileTools(profile: profile);
    }
    final type = profile.userType;
    Widget action(IconData icon, String title, String subtitle, String route) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.brandNavy),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => Navigator.pop(context, route),
        );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.tr('Tus herramientas'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.tr('Cerrar herramientas'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: type.tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedProfileUserTypeLabel(context, type),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(localizedProfileUserTypeDescription(context, type)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (controller.communityRepository != null) ...[
              action(
                Icons.edit_note_rounded,
                AppLocalizations.tr('Crear publicación'),
                AppLocalizations.tr(
                  'Comparte con la comunidad. Elige entre los formatos de tu perfil.',
                ),
                '/posts/new',
              ),
              action(
                Icons.flag_outlined,
                AppLocalizations.tr('Crear misión'),
                AppLocalizations.tr(
                  'Todos los perfiles pueden organizar una colaboración.',
                ),
                '/missions/new',
              ),
              action(
                Icons.handshake_outlined,
                AppLocalizations.tr('Encontrar colaboraciones'),
                AppLocalizations.tr(
                  'Misiones para tu tipo de perfil y convocatorias abiertas a todos.',
                ),
                '/missions?section=compatible',
              ),
            ],
            if (controller.showcaseRepository != null)
              for (final kind in type.showcaseKinds)
                action(
                  switch (kind) {
                    ShowcaseKind.project => Icons.palette_outlined,
                    ShowcaseKind.product => Icons.inventory_2_outlined,
                    ShowcaseKind.service => Icons.work_outline,
                  },
                  localizedShowcaseKindAction(context, kind),
                  AppLocalizations.tr(
                    'Gestiona borradores, fotografías y fichas de tu perfil.',
                  ),
                  '/showcase/new?kind=${kind.name}',
                ),
            if (controller.tourRepository != null && type != UserType.general)
              action(
                Icons.panorama_photosphere_outlined,
                AppLocalizations.tr('Tus recorridos 360°'),
                AppLocalizations.tr(
                  'Captura posiciones del local, conecta panoramas y prepara AR.',
                ),
                '/tours',
              ),
            if (controller.tourRepository != null)
              action(
                Icons.approval_outlined,
                AppLocalizations.tr('Solicitudes de recorridos'),
                AppLocalizations.tr(
                  'Autoriza contenido y revisa propuestas.',
                ),
                '/tours/requests',
              ),
            const Divider(height: 28),
            action(
              Icons.map_outlined,
              AppLocalizations.tr('Mapa'),
              AppLocalizations.tr('Explora las misiones en el mapa.'),
              '/map',
            ),
            if (controller.socialRepository != null)
              action(
                Icons.notifications_none_rounded,
                AppLocalizations.tr('Notificaciones'),
                AppLocalizations.tr('Revisa tus avisos.'),
                '#notifications',
              ),
            action(
              Icons.bookmark_border,
              AppLocalizations.tr('Guardados'),
              AppLocalizations.tr('Contenido que guardaste.'),
              '/explore?section=saved',
            ),
            action(
              Icons.flag_outlined,
              AppLocalizations.tr('Mis misiones'),
              AppLocalizations.tr('Misiones de tu cuenta.'),
              '/missions?section=own',
            ),
            action(
              Icons.assignment_outlined,
              AppLocalizations.tr('Mis postulaciones'),
              AppLocalizations.tr('Revisa tus candidaturas.'),
              '/missions?section=applications',
            ),
            action(
              Icons.auto_awesome_outlined,
              (controller.profile?.setupStep ?? 0) >= type.setupSteps
                  ? AppLocalizations.tr('Guía de perfil')
                  : AppLocalizations.tr('Completar perfil'),
              AppLocalizations.tr(
                'Presentación, intereses y opciones de tu cuenta.',
              ),
              '/profile/setup',
            ),
            if (type.showcaseKinds.isNotEmpty)
              action(
                Icons.contact_page_outlined,
                AppLocalizations.tr('Datos profesionales'),
                switch (type) {
                  UserType.business => AppLocalizations.tr(
                    'Edita contacto, ubicación y horarios.',
                  ),
                  UserType.creator => AppLocalizations.tr(
                    'Edita contacto y disponibilidad para colaborar.',
                  ),
                  _ => AppLocalizations.tr(
                    'Edita la información profesional de tu perfil.',
                  ),
                },
                '/profile/edit?section=professional',
              ),
            if (admin && controller.profile?.role == ProfileRole.admin)
              action(
                Icons.shield_outlined,
                AppLocalizations.tr('Moderación'),
                AppLocalizations.tr(
                  'Revisa reportes y visibilidad de contenido.',
                ),
                '/moderation',
              ),
            const Divider(height: 28),
            Text(
              AppLocalizations.tr('Cómo funcionan las misiones'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tr(
                'Puedes organizar misiones con cualquier tipo de perfil. Para postularte, el perfil solicitado debe coincidir con el tuyo o aceptar a todos.',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tr(
                'El organizador revisa y selecciona participantes. Solo él puede editar, cerrar, cancelar o finalizar su misión. La moderación de contenido requiere una cuenta administradora.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorProfileTools extends StatelessWidget {
  const _VisitorProfileTools({required this.profile});
  final CommunityProfile profile;
  @override
  Widget build(BuildContext context) {
    final showcaseLabel = localizedProfileShowcaseLabel(
      context,
      profile.userType,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.tr('Opciones del perfil'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.tr('Cerrar menú'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (profile.userType.showcaseKinds.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: Text(
                  AppLocalizations.trTemplate('Ver {section}', {
                    'section': showcaseLabel.toLowerCase(),
                  }),
                ),
                onTap: () => Navigator.pop(context, '#showcase'),
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(
                AppLocalizations.tr('Ver misiones del perfil'),
              ),
              onTap: () => Navigator.pop(context, '#missions'),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(AppLocalizations.tr('Ver publicaciones')),
              onTap: () => Navigator.pop(context, '#posts'),
            ),
          ],
        ),
      ),
    );
  }
}
