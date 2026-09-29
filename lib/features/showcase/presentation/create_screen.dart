import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/showcase/models/showcase.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  Widget build(BuildContext context) {
    final kinds = controller.profile?.userType.showcaseKinds ?? [];
    if (kinds.isEmpty) return PostComposerScreen(controller: controller);
    return CommunityPage(
      title: 'Crear',
      children: [
        MareaCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(24),
            leading: const Icon(Icons.dynamic_feed_outlined),
            title: const Text('Publicar en Inicio'),
            subtitle: const Text('Una novedad para tu comunidad.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/posts/new'),
          ),
        ),
        for (final kind in kinds)
          MareaCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(24),
              leading: Icon(
                kind == ShowcaseKind.project
                    ? Icons.palette_outlined
                    : kind == ShowcaseKind.product
                    ? Icons.inventory_2_outlined
                    : Icons.design_services_outlined,
              ),
              title: Text(kind.action),
              subtitle: const Text(
                'Para tu perfil. Publica o guarda un borrador.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/showcase/new?kind=${kind.name}'),
            ),
          ),
      ],
    );
  }
}
