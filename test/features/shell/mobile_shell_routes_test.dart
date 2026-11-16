import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/missions/presentation/mission_catalog_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets(
    'missions uses real router and legacy destinations remain reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final session = await authenticatedController();
      final router = AppRouter.create(session)..go('/home');
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('es', 'MX')],
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Misiones'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/missions');
      expect(find.byType(MissionCatalogScreen), findsOneWidget);
      expect(find.byKey(const Key('mission-catalog-search')), findsOneWidget);
      expect(find.text('Cerca de ti'), findsOneWidget);
      expect(find.byTooltip('Ordenar'), findsOneWidget);
      expect(
        tester.getBottomRight(find.byKey(const Key('mobile-dock'))).dy,
        lessThanOrEqualTo(810),
      );
      final semantics = tester.ensureSemantics();
      for (final path in [
        '/explore?section=saved',
        '/missions?section=own',
        '/create',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.toString(), path);
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(MissionCatalogScreen), findsNothing);
        expect(find.byKey(const Key('create-destination')), findsNothing);
        final selection = tester
            .getSemantics(find.byKey(const Key('mobile-tab-missions')))
            .flagsCollection
            .isSelected;
        expect(
          selection,
          path.startsWith('/missions') ? Tristate.isTrue : Tristate.isFalse,
        );
      }
      // Stories/dialogs use Navigator directly rather than the GoRouter delegate.
      router.go('/missions');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mapa'));
      await tester.pump();
      final rootNavigator = Navigator.of(
        tester.element(find.byType(AppShell)),
        rootNavigator: true,
      );
      rootNavigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Historia')),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/missions');
      rootNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mission-catalog-search')), findsOneWidget);
      // External root navigation must supersede a pending tab selection.
      await tester.tap(find.byTooltip('Mapa'));
      await tester.pump();
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile/edit');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Root pages still cover the shell; Android back restores its route/selection.
      router.go('/missions');
      await tester.pumpAndSettle();
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-dock')).hitTestable(), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MissionCatalogScreen), findsOneWidget);
      expect(find.byTooltip('Misiones').hitTestable(), findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      session.dispose();
    },
  );

  testWidgets('missions scrolls in a short viewport with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = await authenticatedController();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AppShell(
          location: '/missions',
          child: MissionCatalogScreen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final verticalScroll = find.descendant(
      of: find.byKey(const Key('mission-catalog-scroll')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      find.byTooltip('Ordenar'),
      95,
      scrollable: verticalScroll,
    );
    await tester.ensureVisible(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ordenar').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Misiones').hitTestable(), findsOneWidget);

    final search = find.byKey(const Key('mission-catalog-search'));
    await tester.scrollUntilVisible(search, -95, scrollable: verticalScroll);
    await tester.showKeyboard(search);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(search, 'Una búsqueda con texto ampliado');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(search.hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('mobile-dock')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
  });
}
