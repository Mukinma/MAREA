import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/data/community_repository.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/showcase_repository_fake.dart';

Future<GoRouter> open(
  WidgetTester tester,
  ShowcaseRepositoryFake repo,
  String path, {
  UserType type = UserType.entrepreneur,
  bool initial = false,
  CommunityRepository? community,
}) async {
  final profiles = FakeProfileRepository()
    ..value = sampleProfile.copyWith(
      userType: type,
      onboardingStatus: initial
          ? OnboardingStatus.pending
          : OnboardingStatus.completed,
      initialProfileCompletedAt: initial ? null : DateTime.utc(2026, 9, 27),
    );
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: profiles,
    communityRepository: community ?? MissionRepositoryFake(),
    showcaseRepository: repo,
    mediaRepository: VisitorMedia(),
  );
  await controller.initialize();
  final router = AppRouter.create(controller)..go(path);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    router.dispose();
    controller.dispose();
  });
  return router;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class VisitorMedia implements ProfileMediaRepository {
  @override
  Future<String> signedUrl(String path) async =>
      throw StateError('Image offline');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisitorRepository extends MissionRepositoryFake {
  VisitorRepository(this.type);
  final UserType type;
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: 'visitor-owner',
      fullName: 'Perfil público',
      username: 'publico',
      userType: type,
      avatarPath: 'visitor-owner/avatar.png',
      coverPath: 'visitor-owner/cover.png',
    ),
  ];
}

void main() {
  for (final type in UserType.values) {
    testWidgets(
      '${type.name} completes initial choices and gets the right tools',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = await open(
          tester,
          ShowcaseRepositoryFake(),
          '/profile',
          type: type,
          initial: true,
        );
        await tap(tester, find.byKey(Key('register-type-${type.name}')));
        await tap(tester, find.text('Confirmar y entrar'));
        expect(router.routeInformationProvider.value.uri.path, '/home');
        router.go('/profile');
        await tester.pumpAndSettle();
        for (final label in [
          'Agregar obra',
          'Agregar producto',
          'Agregar servicio',
        ]) {
          final expected = switch (type) {
            UserType.general => false,
            UserType.creator => label == 'Agregar obra',
            UserType.entrepreneur => label != 'Agregar obra',
            UserType.business => label == 'Agregar servicio',
          };
          expect(find.text(label), expected ? findsOneWidget : findsNothing);
        }
        router.go('/onboarding');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/profile');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 4));
      },
    );
  }
  for (final type in UserType.values) {
    testWidgets(
      '${type.name} visitor sees its public section without owner tools',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await open(
          tester,
          ShowcaseRepositoryFake(),
          '/people/visitor-owner',
          community: VisitorRepository(type),
        );
        expect(find.text(type.showcaseLabel), findsOneWidget);
        expect(find.text('Misiones'), findsOneWidget);
        await tap(tester, find.text('Misiones'));
        expect(find.text('Pintemos el barrio'), findsOneWidget);
        await tap(tester, find.text(type.showcaseLabel));
        expect(find.text('Editar perfil'), findsNothing);
        expect(find.text('Mis postulaciones'), findsNothing);
        for (final label in [
          'Agregar obra',
          'Agregar producto',
          'Agregar servicio',
        ]) {
          expect(find.text(label), findsNothing);
        }
        final images = tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .map((v) => v.path);
        expect(
          images,
          containsAll(['visitor-owner/avatar.png', 'visitor-owner/cover.png']),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('visitor saves a ficha and opens it directly in Guardados', (
    tester,
  ) async {
    final repo = ShowcaseRepositoryFake()..ownerId = 'visitor-owner';
    await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.service,
        title: 'Servicio guardable',
        body: 'Descripción',
        category: 'arte',
        status: ShowcaseStatus.published,
      ),
    );
    final router = await open(
      tester,
      repo,
      '/showcase/fiche-0',
      community: VisitorRepository(UserType.business),
    );
    expect(find.text('Consultar precio'), findsOneWidget);
    expect(find.text('Contactar'), findsNothing);
    expect(find.text('Eliminar ficha'), findsNothing);
    await tap(tester, find.text('Guardar'));
    expect(find.text('Quitar de guardados'), findsOneWidget);
    router.go('/explore?section=saved');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fichas').last);
      await tester.pumpAndSettle();
      expect(find.text('Fichas guardadas'), findsOneWidget);
    expect(find.text('Servicio guardable'), findsOneWidget);
    await tap(tester, find.text('Fichas').first);
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar fichas por título'),
      'Sin coincidencias',
    );
    await tap(tester, find.byTooltip('Buscar'));
    expect(find.text('Servicio guardable'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar fichas por título'),
      'guardable',
    );
    await tap(tester, find.byTooltip('Buscar'));
    expect(find.text('Servicio guardable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'service editor retains failed save and persists corrections at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = ShowcaseRepositoryFake()..failSave = true;
        final router = await open(tester, repo, '/showcase/new?kind=service');
        expect(find.text('Guardar ficha').hitTestable(), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Título'),
          'Diseño de identidad',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Descripción'),
          'Identidad para negocios locales.',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Precio en MXN (opcional)'),
          '750',
        );
        await tap(tester, find.text('Guardar ficha'));
        expect(find.textContaining('Tus cambios siguen aquí'), findsOneWidget);
        expect(find.text('Diseño de identidad'), findsOneWidget);
        repo.failSave = false;
        await tap(tester, find.text('Guardar ficha'));
        expect(router.routeInformationProvider.value.uri.path, '/profile');
        expect(repo.submitted!.price, 750);
        expect(repo.submitted!.status, ShowcaseStatus.draft);
        expect(find.text('Diseño de identidad'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'archive and delete work through ownership actions and confirmation',
    (tester) async {
      final repo = ShowcaseRepositoryFake();
      await repo.save(
        const ShowcaseInput(
          kind: ShowcaseKind.service,
          title: 'Servicio local',
          body: 'Descripción',
          category: 'arte',
          status: ShowcaseStatus.published,
        ),
      );
      await open(tester, repo, '/showcase/fiche-0');
      await tap(tester, find.text('Archivar'));
      expect(
        find.textContaining('Administrar ficha · Archivado'),
        findsOneWidget,
      );
      await tap(tester, find.text('Volver a borrador'));
      expect(
        find.textContaining('Administrar ficha · Borrador'),
        findsOneWidget,
      );
      await tap(tester, find.text('Eliminar ficha'));
      expect(find.text('¿Eliminar esta ficha?'), findsOneWidget);
      await tap(tester, find.text('Cancelar'));
      expect(find.text('Servicio local'), findsOneWidget);
      await tap(tester, find.text('Eliminar ficha'));
      await tap(tester, find.text('Eliminar'));
      expect(find.text('Servicio local'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('profile refresh includes fichas changed in another session', (
    tester,
  ) async {
    final repo = ShowcaseRepositoryFake();
    await open(tester, repo, '/profile');
    final before = repo.listings;
    await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.service,
        title: 'Servicio nuevo',
        body: 'Descripción',
        category: 'arte',
        status: ShowcaseStatus.published,
      ),
    );
    expect(find.text('Servicio nuevo'), findsNothing);
    await tester
        .widget<MareaRefreshIndicator>(find.byType(MareaRefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(repo.listings, greaterThan(before));
    expect(find.text('Servicio nuevo'), findsOneWidget);
  });
  testWidgets('discard protection keeps an unfinished ficha', (tester) async {
    await open(tester, ShowcaseRepositoryFake(), '/showcase/new?kind=service');
    await tester.enterText(
      find.widgetWithText(TextField, 'Título'),
      'Cambios sin guardar',
    );
    await tap(tester, find.byType(BackButton));
    expect(find.text('¿Descartar tus cambios?'), findsOneWidget);
    await tap(tester, find.text('Seguir editando'));
    expect(find.text('Cambios sin guardar'), findsOneWidget);
  });
}
