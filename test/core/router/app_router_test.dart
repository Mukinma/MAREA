import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/app.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../../support/fakes.dart';

void main() {
  test('keeps initializing sessions on splash', () {
    expect(AppRouter.redirectFor(AuthStatus.initializing, '/login'), '/');
    expect(AppRouter.redirectFor(AuthStatus.initializing, '/'), isNull);
  });

  test('restores the requested private route after session initialization', () {
    final guard = AppRouteGuard();

    expect(
      guard.redirectFor(
        AuthStatus.initializing,
        Uri.parse('/settings?section=account'),
      ),
      '/',
    );
    expect(
      guard.redirectFor(AuthStatus.authenticated, Uri.parse('/')),
      '/settings?section=account',
    );
  });

  test('guards a restored private route when the session has expired', () {
    final guard = AppRouteGuard();

    expect(
      guard.redirectFor(AuthStatus.initializing, Uri.parse('/settings')),
      '/',
    );
    expect(
      guard.redirectFor(AuthStatus.unauthenticated, Uri.parse('/')),
      '/login',
    );
  });

  test('restored private routes cannot bypass pending onboarding', () {
    final guard = AppRouteGuard();

    expect(
      guard.redirectFor(
        AuthStatus.initializing,
        Uri.parse('/missions?filter=nearby'),
      ),
      '/',
    );
    expect(
      guard.redirectFor(
        AuthStatus.authenticated,
        Uri.parse('/'),
        onboarding: true,
      ),
      '/onboarding',
    );
  });

  test('guards private routes for unauthenticated users', () {
    expect(
      AppRouter.redirectFor(AuthStatus.unauthenticated, '/profile'),
      '/login',
    );
    expect(AppRouter.redirectFor(AuthStatus.unauthenticated, '/login'), isNull);
    expect(
      AppRouter.redirectFor(AuthStatus.unauthenticated, '/register'),
      isNull,
    );
    expect(
      AppRouter.redirectFor(AuthStatus.unauthenticated, '/check-email'),
      isNull,
    );
  });

  test('keeps authenticated users away from public auth routes', () {
    expect(AppRouter.redirectFor(AuthStatus.authenticated, '/login'), '/home');
    expect(
      AppRouter.redirectFor(AuthStatus.authenticated, '/register'),
      '/home',
    );
    expect(AppRouter.redirectFor(AuthStatus.authenticated, '/'), '/home');
    expect(
      AppRouter.redirectFor(AuthStatus.authenticated, '/missions'),
      isNull,
    );
  });

  testWidgets('cold start leaves splash after session initialization', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..user = null;
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );

    await tester.pumpWidget(MareaApp(controller: controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome-register')), findsOneWidget);
  });
}
