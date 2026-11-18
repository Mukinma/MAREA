import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/presentation/welcome_screen.dart';

void main() {
  for (final width in [360.0, 390.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'welcome keeps account actions reachable at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
              GoRoute(
                path: '/register',
                builder: (_, _) => const Scaffold(body: Text('Registro')),
              ),
              GoRoute(
                path: '/login',
                builder: (_, _) => const Scaffold(body: Text('Acceso')),
              ),
            ],
          );
          addTearDown(router.dispose);
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
          expect(find.text('Conecta. Crea. Explora.'), findsNothing);
          expect(
            find.text('Tu ciudad\ntambién crea.', findRichText: true),
            findsOneWidget,
          );
          expect(find.textContaining('Conecta con artistas'), findsOneWidget);
          final artwork = find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/onboarding/bienvenida.webp',
          );
          expect(artwork, findsOneWidget);
          final logo = find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/brand/MAREA_LOGOTIPO.png',
          );
          expect(tester.getCenter(logo).dx, closeTo(width / 2, .01));
          expect(find.textContaining('Google'), findsNothing);
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            expect(
              find.byKey(const Key('welcome-register')).hitTestable(),
              findsOneWidget,
            );
          }
          await tester.ensureVisible(find.byKey(const Key('welcome-register')));
          await tester.tap(find.byKey(const Key('welcome-register')));
          await tester.pumpAndSettle();
          expect(find.text('Registro'), findsOneWidget);
          router.go('/');
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('welcome-login')));
          await tester.tap(find.byKey(const Key('welcome-login')));
          await tester.pumpAndSettle();
          expect(find.text('Acceso'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
