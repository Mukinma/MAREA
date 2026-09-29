import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import '../../support/showcase_repository_fake.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/test_app.dart';
import '../showcase/showcase_flow_test.dart' as flow;

void main() {
  testWidgets('derived deep links provide a usable return action', (
    tester,
  ) async {
    final repo = ShowcaseRepositoryFake();
    final id = await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.service,
        title: 'Taller creativo',
        body: 'Un taller',
        category: 'arte',
      ),
    );
    final router = await flow.open(
      tester,
      repo,
      '/settings',
      community: _PublicIdentities(),
    );
    for (final route in [
      '/settings',
      '/settings/email',
      '/settings/password',
      '/showcase/$id',
      '/people/one',
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(
        find.byType(BackButton).hitTestable(),
        findsOneWidget,
        reason: route,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        route.startsWith('/people/') ? '/explore' : '/profile',
      );
    }
  });

  testWidgets('switching editor sections releases and excludes hidden focus', (
    tester,
  ) async {
    final c = await authenticatedController();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(EditProfileScreen(controller: c)));
    final name = find.widgetWithText(TextField, 'Nombre completo');
    await tester.ensureVisible(name);
    await tester.showKeyboard(name);
    final editable = tester.widget<EditableText>(
      find.descendant(of: name, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.ensureVisible(find.text('Profesional'));
    await tester.tap(find.text('Profesional'));
    await tester.pumpAndSettle();
    expect(editable.focusNode.hasFocus, isFalse);
    expect(editable.focusNode.canRequestFocus, isFalse);
    await tester.tap(find.text('Identidad'));
    await tester.pumpAndSettle();
    expect(editable.focusNode.canRequestFocus, isTrue);
  });

  for (final type in UserType.values) {
    testWidgets('${type.name} profile flows fit enlarged text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = await flow.open(
        tester,
        ShowcaseRepositoryFake(),
        '/profile',
        type: type,
      );
      expect(find.byTooltip('Configuración').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final route in [
        '/profile/edit',
        '/settings',
        '/settings/email',
        '/settings/password',
        if (type != UserType.general) '/showcase/new',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('edit-save-button')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getBottomLeft(find.byKey(const Key('edit-save-button'))).dy,
        lessThanOrEqualTo(520),
      );
      if (type != UserType.general) {
        await tester.ensureVisible(find.text('Profesional'));
        await tester.tap(find.text('Profesional'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('save actions remain above the mobile keyboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      testApp(
        const Scaffold(
          body: SizedBox(),
          bottomNavigationBar: ProfileActionBar(
            child: FilledButton(onPressed: null, child: Text('Guardar')),
          ),
        ),
      ),
    );
    expect(tester.getBottomLeft(find.text('Guardar')).dy, lessThan(544));
  });

  testWidgets('changing public profile links loads the new identity', (
    tester,
  ) async {
    final router = await flow.open(
      tester,
      ShowcaseRepositoryFake(),
      '/people/one',
      community: _PublicIdentities(),
    );
    expect(find.text('Perfil one'), findsOneWidget);
    router.go('/people/two');
    await tester.pumpAndSettle();
    expect(find.text('Perfil two'), findsOneWidget);
    expect(find.text('Perfil one'), findsNothing);
  });

  testWidgets('gallery can be operated with buttons on desktop', (
    tester,
  ) async {
    final repo = ShowcaseRepositoryFake();
    final id = await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.project,
        title: 'Entre mareas',
        body: 'Una obra',
        category: 'arte',
        imagePaths: ['owner/one.png', 'owner/two.png'],
      ),
    );
    await flow.open(tester, repo, '/showcase/$id', type: UserType.creator);
    expect(find.text('Entre mareas'), findsOneWidget);
    await tester.tap(find.byTooltip('Fotografía siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Fotografía anterior'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor retains fields and reveals errors in another section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await authenticatedController();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(EditProfileScreen(controller: c)));
    await tester.ensureVisible(find.text('Nombre completo'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo'),
      '',
    );
    await tester.ensureVisible(find.text('Profesional'));
    await tester.tap(find.text('Profesional'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre completo'), findsNothing);
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('own profile starts with identity and visible content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = ShowcaseRepositoryFake();
    await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.project,
        title: 'Entre mareas',
        body: 'Una obra',
        category: 'arte',
      ),
    );
    await flow.open(tester, repo, '/profile', type: UserType.creator);
    expect(
      find.text('Perfil').evaluate().length,
      lessThanOrEqualTo(1),
    ); // Only the selected dock item.
    expect(find.byType(BackButton), findsNothing);
    expect(find.byTooltip('Configuración').hitTestable(), findsOneWidget);
    expect(find.text('Entre mareas').hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Entre mareas')).dy, lessThan(760));
  });

  testWidgets('content tabs retain loaded work and scroll position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = ShowcaseRepositoryFake();
    for (var i = 0; i < 8; i++) {
      await repo.save(
        ShowcaseInput(
          kind: ShowcaseKind.project,
          title: 'Obra $i',
          body: 'Una obra',
          category: 'arte',
        ),
      );
    }
    await flow.open(tester, repo, '/profile', type: UserType.creator);
    final before = repo.listings;
    final scroll = find.byKey(const Key('profile-scroll'));
    await tester.drag(scroll, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicaciones'));
    await tester.pumpAndSettle();
    final y = tester.getTopLeft(find.text('Obra 0')).dy;
    await tester.tap(find.text('Publicaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Obra 0'), findsNothing);
    await tester.tap(find.text('Portafolio'));
    await tester.pumpAndSettle();
    expect(find.text('Obra 0'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Obra 0')).dy, closeTo(y, 1));
    expect(repo.listings, before);
  });

  testWidgets('a link to my public profile opens the main profile', (
    tester,
  ) async {
    final router = await flow.open(
      tester,
      ShowcaseRepositoryFake(),
      '/people/${sampleProfile.id}',
      type: UserType.creator,
    );
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    expect(find.byType(BackButton), findsNothing);
    expect(find.byTooltip('Configuración').hitTestable(), findsOneWidget);
  });
}

class _PublicIdentities extends MissionRepositoryFake {
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: ids!.first,
      fullName: 'Perfil ${ids.first}',
      username: ids.first,
      userType: UserType.creator,
    ),
  ];
}
