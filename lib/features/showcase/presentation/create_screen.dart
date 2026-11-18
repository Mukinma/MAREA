import 'dart:async';

import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/l10n/app_localizations.dart' as gen;
import 'package:marea/l10n/app_localizations_es.dart' as gen;

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;

class CreateScreen extends StatelessWidget {
  const CreateScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: CommunityPage(
      title: 'Crear',
      children: [
        CreationChoices(
          controller: controller,
          onSelect: (path) => _openCreation(context, controller, path),
        ),
      ],
    ),
  );
}

bool canOpenCreateMenu(AppSessionController controller) =>
    controller.status == AuthStatus.authenticated &&
    controller.profile != null &&
    !controller.needsOnboarding &&
    !controller.needsLegalAcceptance &&
    !controller.isRecovering &&
    !controller.isRecoveryComplete;

typedef _CreationChoice = ({
  String title,
  String description,
  String path,
  IconData icon,
  Color color,
});

List<_CreationChoice> _choicesFor(AppSessionController controller) {
  if (!canOpenCreateMenu(controller)) return const [];
  final type = controller.profile!.userType;
  return [
    if (controller.communityRepository != null)
      (
        title: 'Publicación',
        description: 'Texto o foto en Inicio.',
        path: '/posts/new',
        icon: Icons.dynamic_feed_outlined,
        color: AppColors.peach,
      ),
    if (controller.storiesRepository != null)
      (
        title: 'Historia',
        description: 'Una foto visible durante 24 h.',
        path: '/stories/new',
        icon: Icons.add_a_photo_outlined,
        color: AppColors.mint,
      ),
    if (controller.communityRepository != null)
      (
        title: 'Crear misión',
        description: 'Convoca a tu comunidad para colaborar.',
        path: '/missions/new',
        icon: Icons.flag_outlined,
        color: AppColors.mint,
      ),
    if (controller.showcaseRepository != null)
      for (final kind in type.showcaseKinds)
        (
          title: kind.label,
          description: 'Publica en tu perfil o guarda un borrador.',
          path: '/showcase/new?kind=${kind.name}',
          icon: switch (kind) {
            ShowcaseKind.project => Icons.palette_outlined,
            ShowcaseKind.product => Icons.inventory_2_outlined,
            ShowcaseKind.service => Icons.design_services_outlined,
          },
          color: AppColors.lavender,
        ),
    if (controller.tourRepository != null && type != UserType.general)
      (
        title: 'Crear recorrido 360°',
        description: 'Muestra tu local y añade puntos con RA.',
        path: '/tours/new',
        icon: Icons.panorama_photosphere_outlined,
        color: AppColors.mint,
      ),
    if (controller.markerRepository != null)
      (
        title: 'Crear marcador RA',
        description: 'Elige una imagen que la cámara pueda reconocer.',
        path: '/ar-markers/new',
        icon: Icons.image_search_outlined,
        color: AppColors.lavender,
      ),
  ];
}

Future<void> _openCreation(
  BuildContext context,
  AppSessionController controller,
  String path,
) async {
  if (!_choicesFor(controller).any((choice) => choice.path == path)) return;
  final router = GoRouter.of(context);
  final owner = controller.profile?.id;
  final result = await router.push<Object?>(path);
  if (!context.mounted || controller.profile?.id != owner) return;
  if (path == '/missions/new' && result is String) {
    await router.push<void>('/missions/${Uri.encodeComponent(result)}');
  } else if (path == '/stories/new' && result == true) {
    controller.refreshHomeFeed();
  }
}

/// Same choices in the navigation palette and direct /create destination.
class CreationChoices extends StatelessWidget {
  const CreationChoices({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final AppSessionController controller;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final choices = _choicesFor(controller);
      if (choices.isEmpty) {
        return const Text('No hay opciones de creación disponibles.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(choice.path),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: choice.color,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            choice.icon,
                            color: AppColors.brandNavy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                choice.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                choice.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 20,
                          color: AppColors.actionBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

Future<void> showCreateMenu(
  BuildContext context,
  AppSessionController controller,
) async {
  if (!canOpenCreateMenu(controller)) return;
  final owner = controller.profile?.id;
  final width = MediaQuery.sizeOf(context).width;
  final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
  Widget panel(BuildContext c) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(20, width < 600 ? 8 : 18, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Crear',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              IconButton(
                tooltip: core_l10n.AppLocalizations.tr(l10n.cerrarMenu),
                onPressed: () => Navigator.pop(c),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: CreationChoices(
                controller: controller,
                onSelect: (path) => Navigator.pop(c, path),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  final path = width < 600
      ? await showMareaBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: AppColors.canvas,
          barrierColor: AppColors.brandNavy.withValues(alpha: .3),
          builder: panel,
        )
      : await showDialog<String>(
          context: context,
          barrierColor: AppColors.brandNavy.withValues(alpha: .3),
          builder: (c) => Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 88, right: 24, bottom: 24),
              child: Material(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: panel(c),
                ),
              ),
            ),
          ),
        );
  if (path != null && context.mounted && controller.profile?.id == owner) {
    unawaited(_openCreation(context, controller, path));
  }
}
