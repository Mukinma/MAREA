import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/discover/presentation/discover_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets(
    'discover uses real router and legacy destinations remain reachable',
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
      await tester.tap(find.byTooltip('Descubrir'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/discover');
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(find.text('Algo nuevo está por llegar'), findsOneWidget);
      expect(find.text('En desarrollo'), findsOneWidget);
      expect(
        tester.getBottomRight(find.byKey(const Key('mobile-dock'))).dy,
        lessThanOrEqualTo(810),
      );
      final semantics = tester.ensureSemantics();
      for (final path in ['/explore?section=saved', '/missions', '/create']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.toString(), path);
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(DiscoverScreen), findsNothing);
        expect(find.byKey(const Key('create-destination')), findsNothing);
        final selection = tester
            .getSemantics(find.byKey(const Key('mobile-tab-discover')))
            .flagsCollection
            .isSelected;
        expect(
          selection,
          path == '/create' ? Tristate.isFalse : Tristate.isTrue,
        );
      }
      // Stories/dialogs use Navigator directly rather than the GoRouter delegate.
      router.go('/discover');
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
      expect(router.state.uri.path, '/discover');
      rootNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      // External root navigation must supersede a pending tab selection.
      await tester.tap(find.byTooltip('Mapa'));
      await tester.pump();
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile/edit');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Root pages still cover the shell; Android back restores its route/selection.
      router.go('/discover');
      await tester.pumpAndSettle();
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-dock')).hitTestable(), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(find.byTooltip('Descubrir').hitTestable(), findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      session.dispose();
    },
  );

  testWidgets(
    'discover placeholder scrolls in a short viewport with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const AppShell(
              location: '/discover',
              child: DiscoverScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('En desarrollo'));
      expect(find.text('En desarrollo').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Descubrir').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
