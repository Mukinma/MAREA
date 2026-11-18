import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/app.dart';
import 'package:marea/core/localization/app_locale_controller.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets(
    'language selection stays on settings and preserves an open profile draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = FakeAuthRepository();
      final session = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      final locale = AppLocaleController();
      addTearDown(auth.close);
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        MareaApp(controller: session, localeController: locale),
      );
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.byType(AppShell)));
      router.go('/settings');
      await tester.pumpAndSettle();
      final settings = tester.state(find.byType(SettingsScreen));
      final language = find.text('Idioma');
      await tester.ensureVisible(language);
      await tester.tap(language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English (US)'));
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(SettingsScreen)), same(settings));
      expect(router.state.uri.path, '/settings');
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy and blocks'), findsOneWidget);

      final restored = AppLocaleController();
      await restored.load();
      expect(restored.locale, const Locale('en', 'US'));
      restored.dispose();

      router.push('/profile/edit');
      await tester.pumpAndSettle();
      final editor = tester.state(find.byType(EditProfileScreen));
      final name = find.descendant(
        of: find.byKey(const ValueKey('edit-field-Nombre completo')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Borrador MAREA');
      await locale.setLocale(const Locale('es', 'MX'));
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(EditProfileScreen)), same(editor));
      expect(router.state.uri.path, '/profile/edit');
      expect(tester.widget<TextField>(name).controller?.text, 'Borrador MAREA');
      expect(find.text('Guardar cambios'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
