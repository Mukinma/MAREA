import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';

Future<String?> showProfileTools(
  BuildContext context, {
  required CommunityProfile profile,
  required AppSessionController controller,
  required bool admin,
}) => showModalBottomSheet<String>(
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
                    'Tus herramientas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar herramientas',
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
                    type.databaseValue,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(type.description),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (controller.communityRepository != null) ...[
              action(
                Icons.edit_note_rounded,
                'Crear publicación',
                'Comparte con la comunidad. Elige entre los formatos de tu perfil.',
                '/posts/new',
              ),
              action(
                Icons.flag_outlined,
                'Crear misión',
                'Todos los perfiles pueden organizar una colaboración.',
                '/missions/new',
              ),
              action(
                Icons.handshake_outlined,
                'Encontrar colaboraciones',
                'Misiones para tu tipo de perfil y convocatorias abiertas a todos.',
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
                  kind.action,
                  'Gestiona borradores, fotografías y fichas de tu ${type.showcaseLabel.toLowerCase()}.',
                  '/showcase/new?kind=${kind.name}',
                ),
            const Divider(height: 28),
            action(
              Icons.auto_awesome_outlined,
              (controller.profile?.setupStep ?? 0) >= type.setupSteps
                  ? 'Guía de perfil'
                  : 'Completar perfil',
              'Presentación, intereses y opciones de tu cuenta.',
              '/profile/setup',
            ),
            if (type.showcaseKinds.isNotEmpty)
              action(
                Icons.contact_page_outlined,
                'Datos profesionales',
                'Edita contacto${type == UserType.business
                    ? ', ubicación y horarios'
                    : type == UserType.creator
                    ? ' y disponibilidad para colaborar'
                    : ''}.',
                '/profile/edit?section=professional',
              ),
            if (admin)
              action(
                Icons.shield_outlined,
                'Moderación',
                'Revisa reportes y visibilidad de contenido.',
                '/moderation',
              ),
            const Divider(height: 28),
            const Text(
              'Cómo funcionan las misiones',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes organizar misiones con cualquier tipo de perfil. Para postularte, el perfil solicitado debe coincidir con el tuyo o aceptar a todos.',
            ),
            const SizedBox(height: 8),
            const Text(
              'El organizador revisa y selecciona participantes. Solo él puede editar, cerrar, cancelar o finalizar su misión. La moderación de contenido requiere una cuenta administradora.',
            ),
          ],
        ),
      ),
    );
  }
}
