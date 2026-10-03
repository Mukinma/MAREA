import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/showcase/models/showcase.dart';

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
          onSelect: (path) => context.push(path),
        ),
      ],
    ),
  );
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
            title: 'Crear misión',
            description: 'Convoca a tu comunidad para hacer algo juntos.',
            path: '/missions/new',
            icon: Icons.flag_outlined,
            color: AppColors.mint,
          ),
          (
            title: 'Publicar en Inicio',
            description:
                'Comparte una idea, una novedad o lo que estás creando.',
            path: '/posts/new',
            icon: Icons.dynamic_feed_outlined,
            color: AppColors.peach,
          ),
          for (final kind
              in controller.profile?.userType.showcaseKinds ?? <ShowcaseKind>[])
            (
              title: kind.action,
              description: 'Para tu perfil. Publica o guarda un borrador.',
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
  Widget panel(BuildContext c) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pon tu idea en movimiento',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar menú de creación',
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
      ? await showModalBottomSheet<String>(
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
  if (path != null && context.mounted) await router.push(path);
}
