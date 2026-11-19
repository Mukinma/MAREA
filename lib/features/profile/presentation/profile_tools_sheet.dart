import 'package:flutter/material.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/community/data/community_reports_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

Future<String?> showProfileTools(
  BuildContext context, {
  required CommunityProfile profile,
  required AppSessionController controller,
  required bool admin,
  String? messageLabel,
  bool messageEnabled = true,
}) => showMareaBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => _ProfileTools(
    profile: profile,
    controller: controller,
    admin: admin,
    messageLabel: messageLabel,
    messageEnabled: messageEnabled,
  ),
);

class _ProfileTools extends StatelessWidget {
  const _ProfileTools({
    required this.profile,
    required this.controller,
    required this.admin,
    required this.messageLabel,
    required this.messageEnabled,
  });
  final CommunityProfile profile;
  final AppSessionController controller;
  final bool admin, messageEnabled;
  final String? messageLabel;

  @override
  Widget build(BuildContext context) {
    final type = profile.userType;
    final owner = controller.profile?.id == profile.id;
    final signedIn = controller.profile != null;
    String tr(String text) => AppLocalizations.tr(text);
    Widget item(
      IconData icon,
      String label,
      String route, {
      bool enabled = true,
    }) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      minTileHeight: 48,
      minLeadingWidth: 20,
      horizontalTitleGap: 12,
      leading: Icon(
        icon,
        size: 20,
        color: enabled ? AppColors.brandNavy : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      trailing: enabled
          ? const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            )
          : null,
      enabled: enabled,
      onTap: enabled ? () => Navigator.pop(context, route) : null,
    );
    final groups = owner
        ? <(String, List<Widget>)>[
            (
              'Tu perfil',
              [
                if (type.showcaseKinds.isNotEmpty)
                  item(
                    Icons.contact_page_outlined,
                    tr('Datos profesionales'),
                    '/profile/edit?section=professional',
                  ),
                if (controller.tourRepository != null &&
                    type != UserType.general)
                  item(
                    Icons.panorama_photosphere_outlined,
                    tr('Tus recorridos 360°'),
                    '/tours',
                  ),
                if (controller.markerRepository != null)
                  item(
                    Icons.image_search_outlined,
                    tr('Tus marcadores RA'),
                    '/ar-markers',
                  ),
                if (controller.tourRepository != null)
                  item(
                    Icons.approval_outlined,
                    tr('Solicitudes de recorridos'),
                    '/tours/requests',
                  ),
                item(
                  Icons.auto_awesome_outlined,
                  tr(
                    (controller.profile?.setupStep ?? 0) >= type.setupSteps
                        ? 'Guía de perfil'
                        : 'Completar perfil',
                  ),
                  '/profile/setup',
                ),
              ],
            ),
            (
              'Tu actividad',
              [
                item(
                  Icons.bookmark_border,
                  tr('Guardados'),
                  '/explore?section=saved',
                ),
                item(
                  Icons.flag_outlined,
                  tr('Mis misiones'),
                  '/missions?section=own',
                ),
                item(
                  Icons.assignment_outlined,
                  tr('Mis postulaciones'),
                  '/missions?section=applications',
                ),
                if (controller.socialRepository != null)
                  item(
                    Icons.notifications_none_rounded,
                    tr('Notificaciones'),
                    '#notifications',
                  ),
                if (controller.markerRepository != null)
                  item(
                    Icons.notifications_active_outlined,
                    tr('Avisos a 20 metros'),
                    '/nearby-alerts',
                  ),
              ],
            ),
            (
              'Crear',
              [
                if (controller.communityRepository != null) ...[
                  item(
                    Icons.edit_note_rounded,
                    tr('Crear publicación'),
                    '/posts/new',
                  ),
                  item(
                    Icons.flag_outlined,
                    tr('Crear misión'),
                    '/missions/new',
                  ),
                ],
                if (controller.showcaseRepository != null)
                  for (final kind in type.showcaseKinds)
                    item(
                      switch (kind) {
                        ShowcaseKind.project => Icons.palette_outlined,
                        ShowcaseKind.product => Icons.inventory_2_outlined,
                        ShowcaseKind.service => Icons.work_outline,
                      },
                      localizedShowcaseKindAction(context, kind),
                      '/showcase/new?kind=${kind.name}',
                    ),
              ],
            ),
            (
              'Explorar',
              [
                item(Icons.map_outlined, tr('Mapa'), '/map'),
                if (controller.communityRepository != null)
                  item(
                    Icons.handshake_outlined,
                    tr('Encontrar colaboraciones'),
                    '/missions?section=compatible',
                  ),
                if (admin && controller.profile?.role == ProfileRole.admin)
                  item(Icons.shield_outlined, tr('Moderación'), '/moderation'),
              ],
            ),
          ]
        : <(String, List<Widget>)>[
            (
              'En este perfil',
              [
                if (profile.userType.showcaseKinds.isNotEmpty)
                  item(
                    Icons.grid_view_outlined,
                    AppLocalizations.trTemplate('Ver {section}', {
                      'section': localizedProfileShowcaseLabel(
                        context,
                        type,
                      ).toLowerCase(),
                    }),
                    '#showcase',
                  ),
                if (controller.communityRepository != null) ...[
                  item(
                    Icons.flag_outlined,
                    tr('Ver misiones del perfil'),
                    '#missions',
                  ),
                  item(
                    Icons.article_outlined,
                    tr('Ver publicaciones'),
                    '#posts',
                  ),
                ],
                if (messageLabel != null && signedIn)
                  item(
                    Icons.chat_bubble_outline_rounded,
                    tr(messageLabel!),
                    '#message',
                    enabled: messageEnabled,
                  ),
                if (signedIn &&
                    controller.communityRepository
                        is CommunityReportsRepository)
                  item(Icons.flag_outlined, tr('Reportar cuenta'), '#report'),
              ],
            ),
            if (signedIn)
              (
                'Tu cuenta',
                [
                  item(
                    Icons.settings_outlined,
                    tr('Configuración de tu cuenta'),
                    '#settings',
                  ),
                ],
              ),
          ];
    final visible = groups.where((group) => group.$2.isNotEmpty);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(owner ? 'Tus herramientas' : 'Opciones del perfil'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: tr(
                        owner ? 'Cerrar herramientas' : 'Cerrar menú',
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              for (final (index, group) in visible.indexed) ...[
                if (index > 0) const Divider(height: 17),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                  child: Semantics(
                    header: true,
                    child: Text(
                      tr(group.$1),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                ...group.$2,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
