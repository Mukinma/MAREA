import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/l10n/app_localizations.dart' as gen;
import 'package:marea/l10n/app_localizations_es.dart' as gen;

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
class CreateScreen extends StatelessWidget {
  const CreateScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    return ColoredBox(
      color: AppColors.canvas,
      child: CommunityPage(
        title: core_l10n.AppLocalizations.tr(l10n.crear),
        children: [
          CreationChoices(
            controller: controller,
            onSelect: (path) => context.push(path),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    final choices =
        <
          ({
            String title,
            String description,
            String path,
            IconData icon,
            Color color,
          })
        >[
          (
            title: core_l10n.AppLocalizations.tr(l10n.crearHistoria),
            description: core_l10n.AppLocalizations.tr(l10n.descripcionCrearHistoria),
            path: '/stories/new',
            icon: Icons.add_circle_outline,
            color: AppColors.mint,
          ),
          (
            title: core_l10n.AppLocalizations.tr(l10n.crearMisionHerramientas),
            description: core_l10n.AppLocalizations.tr(l10n.descripcionCrearMisionInicio),
            path: '/missions/new',
            icon: Icons.flag_outlined,
            color: AppColors.mint,
          ),
          (
            title: core_l10n.AppLocalizations.tr(l10n.publicarEnInicio),
            description: core_l10n.AppLocalizations.tr(l10n.descripcionPublicarEnInicio),
            path: '/posts/new',
            icon: Icons.dynamic_feed_outlined,
            color: AppColors.peach,
          ),
          if (controller.tourRepository != null &&
              controller.profile?.userType != null &&
              controller.profile!.userType != UserType.general)
            (
              title: core_l10n.AppLocalizations.tr(l10n.crearRecorrido360),
              description: core_l10n.AppLocalizations.tr(l10n.descripcionCrearRecorrido360),
              path: '/tours/new',
              icon: Icons.panorama_photosphere_outlined,
              color: AppColors.mint,
            ),
          for (final kind
              in controller.profile?.userType.showcaseKinds ?? <ShowcaseKind>[])
            (
              title: localizedShowcaseKindAction(context, kind),
              description: core_l10n.AppLocalizations.tr(l10n.descripcionCrearFichaPerfil),
              path: '/showcase/new?kind=${kind.name}',
              icon: kind == ShowcaseKind.project
                  ? Icons.palette_outlined
                  : kind == ShowcaseKind.product
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: AppColors.lavender,
            ),
        ];
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
  }
}

Future<void> showCreateMenu(
  BuildContext context,
  AppSessionController controller,
) async {
  final router = GoRouter.of(context);
  final width = MediaQuery.sizeOf(context).width;
  final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
  Widget panel(BuildContext c) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  core_l10n.AppLocalizations.tr(l10n.ponTuIdeaMovimiento),
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
          const SizedBox(height: 20),
          CreationChoices(
            controller: controller,
            onSelect: (path) => Navigator.pop(c, path),
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
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
  if (path != null && context.mounted) {
    await router.push(path);
    controller.refreshHomeFeed();
  }
}
