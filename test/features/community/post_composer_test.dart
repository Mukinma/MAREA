import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _LocationRepository implements CommunityRepository {
  PostInput? saved;

  @override
  Future<CommunityPost?> post(String id) async => CommunityPost(
    id: id,
    authorId: sampleProfile.id,
    kind: PostKind.community,
    title: 'Encuentro local',
    body: 'Nos vemos en el centro.',
    category: 'otros',
    location: 'Punto original',
    coordinates: const PostCoordinates(
      latitude: 19.43,
      longitude: -99.13,
      precision: PostLocationPrecision.exact,
    ),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<void> savePost(PostInput input, {String? id}) async => saved = input;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final replacement in ['Nueva dirección escrita a mano', '']) {
    testWidgets('manual location edit clears previous coordinates: "$replacement"',
        (tester) async {
      final repo = _LocationRepository();
      final session = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        communityRepository: repo,
      );
      await session.initialize();
      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/edit',
            builder: (_, _) => Scaffold(
              body: PostComposerScreen(controller: session, postId: 'post-1'),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Inicio')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final location = find.widgetWithText(TextFormField, 'Ubicación (opcional)');
      await tester.ensureVisible(location);
      await tester.enterText(location, replacement);
      final save = find.text('Guardar cambios');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.saved, isNotNull);
      expect(repo.saved!.location, replacement.isEmpty ? null : replacement);
      expect(repo.saved!.coordinates, isNull);
      expect(find.text('Inicio'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      session.dispose();
    });
  }

  for (final type in UserType.values) {
    testWidgets('composer exposes the content types for ${type.name}', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(userType: type);
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: profiles,
      );
      await controller.initialize();
      await tester.pumpWidget(
        testApp(Scaffold(body: PostComposerScreen(controller: controller))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Comunidad'), findsWidgets);
      expect(
        find.text('Proyecto'),
        type == UserType.creator ? findsWidgets : findsNothing,
      );
      expect(
        find.text('Producto'),
        type == UserType.entrepreneur ? findsWidgets : findsNothing,
      );
      expect(
        find.text('Espacio'),
        type == UserType.business ? findsWidgets : findsNothing,
      );
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}
