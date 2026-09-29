import 'dart:ui' show SemanticsAction;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:marea/shared/widgets/marea_tabs.dart';

void main() {
  testWidgets('saved deep link keeps its selected tab visible on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: MareaTabs(
              options: const {
                'posts': 'Publicaciones',
                'people': 'Personas',
                'showcases': 'Fichas',
                'saved': 'Guardados',
              },
              value: 'saved',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextButton, 'Guardados').hitTestable(),
      findsOneWidget,
    );
  });
  const destinations = {
    'Inicio': '/home',
    'Explorar': '/explore',
    'Crear': '/create',
    'Misiones': '/missions',
    'Perfil': '/profile',
  };

  for (final (width, scale) in const [
    (360.0, 1.0),
    (600.0, 1.0),
    (900.0, 1.0),
    (900.0, 1.35),
    (1024.0, 1.0),
    (1024.0, 1.35),
    (1440.0, 1.0),
  ]) {
    testWidgets(
      'all destinations remain accessible at width $width, scale $scale',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            for (final path in destinations.values)
              GoRoute(
                path: path,
                builder: (_, _) => AppShell(
                  location: path,
                  child: Center(child: Text('Contenido $path')),
                ),
              ),
          ],
        );
        addTearDown(router.dispose);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final destination in destinations.entries) {
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel(destination.key))
                  .getSemanticsData()
                  .hasAction(SemanticsAction.tap),
              isTrue,
              reason:
                  'Screen readers must be able to activate ${destination.key}',
            );
            final target = find.byTooltip(destination.key);
            expect(target.hitTestable(), findsOneWidget);
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(
              router.routeInformationProvider.value.uri.path,
              destination.value,
            );
            expect(find.text('Contenido ${destination.value}'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          // Large accessibility text must not make any destination unreachable.
          await tester.pumpWidget(
            MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final label in destinations.keys) {
            expect(find.byTooltip(label).hitTestable(), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
