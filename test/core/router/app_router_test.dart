import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/app.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'return destination survives a refreshed auth page and rejects external URLs',
    () {
      final guard = AppRouteGuard();
      final auth = Uri(
        path: '/register',
        queryParameters: {'returnTo': '/posts/p?panel=comments'},
      );
      expect(
        guard.redirectFor(AuthStatus.authenticated, auth),
        '/posts/p?panel=comments',
      );
      for (final unsafe in [
        'https://other.test/posts/p',
        '//other.test/posts/p',
        '/posts/a/b',
        '/home',
        '/posts/%2fhidden',
      ]) {
        expect(AppRouteGuard.internalDestination(unsafe), isNull);
      }
    },
  );
  test('shared post survives login and required account steps', () {
    final guard = AppRouteGuard();
    final post = Uri.parse('/posts/post-1?panel=comments');
    expect(
      Uri.parse(guard.redirectFor(AuthStatus.unauthenticated, post)!).path,
      '/login',
    );
    expect(
      Uri.parse(
        guard.redirectFor(
          AuthStatus.authenticated,
          Uri.parse('/login'),
          legal: true,
        )!,
      ).path,
      '/legal/accept',
    );
    expect(
      Uri.parse(
        guard.redirectFor(
          AuthStatus.authenticated,
          Uri.parse('/legal/accept'),
          onboarding: true,
        )!,
      ).path,
      '/onboarding',
    );
    expect(
      guard.redirectFor(AuthStatus.authenticated, Uri.parse('/onboarding')),
      post.toString(),
    );
  });

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
