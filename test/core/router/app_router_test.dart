import 'package:flutter/material.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marea/app.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'tour and point destinations survive authentication with their query',
    () {
      for (final route in [
        '/tours/cafe?point=mural',
        '/tours/cafe/ar?point=mural',
        '/tours/cafe/edit',
        '/tours/cafe/capture?scene=bar',
      ]) {
        expect(AppRouteGuard.internalDestination(route), route);
      }
      expect(
        AppRouteGuard.internalDestination('https://other.test/tours/cafe'),
        isNull,
      );
    },
  );

  for (final path in [
    '/missions',
    '/missions/new',
    '/missions/m/apply',
    '/missions/m/manage',
    '/missions/m/sent?application=a',
    '/missions/drafts/d/edit',
  ]) {
    test('mission destination $path survives expired session', () {
      final guard = AppRouteGuard();
      expect(
        Uri.parse(
          guard.redirectFor(AuthStatus.unauthenticated, Uri.parse(path))!,
        ).path,
        '/login',
      );
      expect(
        guard.redirectFor(AuthStatus.authenticated, Uri.parse('/login')),
        path,
      );
    });
  }

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
    SharedPreferences.setMockInitialValues({'marea.mobile_intro.seen': true});
    final auth = FakeAuthRepository()..user = null;
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );

    await tester.pumpWidget(MareaApp(controller: controller));
    expect(find.byType(MareaSkeleton), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome-register')), findsOneWidget);
  });
}
