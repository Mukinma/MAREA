import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/mobile_intro_screen.dart';
import 'package:marea/features/auth/presentation/splash_screen.dart';

void main() {
  final screens = <String, Widget>{
    'access forms': AccessLayout(
      title: 'Tu acceso',
      onBack: () {},
      step: 3,
      totalSteps: 3,
      child: const SizedBox.shrink(),
    ),
    'mobile introduction': MobileIntroScreen(onComplete: () {}),
    'loading': const SplashScreen(),
  };
  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name centers the wordmark above the content', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              padding: EdgeInsets.only(top: 24),
              disableAnimations: true,
            ),
            child: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(AccessBrand));
      expect(rect.center.dx, closeTo(160, .01));
      expect(rect.bottom, lessThan(100));
      expect(tester.takeException(), isNull);
    });
  }
}
