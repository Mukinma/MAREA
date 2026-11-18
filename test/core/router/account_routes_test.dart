import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

void main() {
  test('MFA precedes recovery and resumes the saved destination', () {
    final guard = AppRouteGuard();
    final destination = Uri.parse('/settings/security');
    expect(
      Uri.parse(guard.redirectFor(
        AuthStatus.authenticated, destination, needsMfa: true, recovery: true,
      )!).path,
      '/auth/verify-2fa',
    );
    expect(
      AppRouter.redirectFor(
        AuthStatus.authenticated, '/auth/verify-2fa', recovery: true,
      ),
      '/reset-password',
    );
    expect(
      guard.redirectFor(
        AuthStatus.authenticated, Uri.parse('/auth/verify-2fa'),
      ),
      destination.path,
    );
  });

  test('visitors enter through welcome and can read legal documents', () {
    expect(AppRouter.redirectFor(AuthStatus.unauthenticated, '/'), '/welcome');
    expect(AppRouter.redirectFor(AuthStatus.unauthenticated, '/terms'), isNull);
    expect(
      AppRouter.redirectFor(AuthStatus.unauthenticated, '/privacy'),
      isNull,
    );
  });
  test('password recovery takes precedence over onboarding', () {
    expect(
      AppRouter.redirectFor(
        AuthStatus.authenticated,
        '/profile',
        recovery: true,
        onboarding: true,
      ),
      '/reset-password',
    );
    expect(
      AppRouter.redirectFor(
        AuthStatus.authenticated,
        '/reset-password',
        recovery: true,
      ),
      isNull,
    );
  });
  test(
    'recovery confirmation holds the protected destination until continued',
    () {
      final guard = AppRouteGuard();
      final destination = Uri.parse('/posts/p?panel=comments');
      guard.redirectFor(AuthStatus.unauthenticated, destination);

      final success = Uri.parse(
        guard.redirectFor(
          AuthStatus.authenticated,
          Uri.parse('/reset-password'),
          recoveryComplete: true,
        )!,
      );
      expect(success.path, '/password-updated');
      expect(success.queryParameters['returnTo'], destination.toString());
      expect(
        guard.redirectFor(
          AuthStatus.authenticated,
          success,
          recoveryComplete: true,
        ),
        isNull,
      );
      expect(
        guard.redirectFor(AuthStatus.authenticated, success),
        destination.toString(),
      );
    },
  );
  test(
    'pending onboarding is routed once and skipped users are not forced back',
    () {
      expect(
        AppRouter.redirectFor(
          AuthStatus.authenticated,
          '/login',
          onboarding: true,
        ),
        '/onboarding',
      );
      expect(
        AppRouter.redirectFor(
          AuthStatus.authenticated,
          '/onboarding',
          onboarding: true,
        ),
        isNull,
      );
      expect(
        AppRouter.redirectFor(
          AuthStatus.authenticated,
          '/profile',
          onboarding: false,
        ),
        isNull,
      );
    },
  );
  test('pending legal acceptance still allows account management', () {
    for (final path in ['/settings', '/settings/personal']) {
      expect(
        AppRouter.redirectFor(
          AuthStatus.authenticated,
          path,
          onboarding: true,
          legal: true,
        ),
        isNull,
      );
    }
    expect(
      AppRouter.redirectFor(
        AuthStatus.authenticated,
        '/onboarding',
        onboarding: true,
        legal: true,
      ),
      '/legal/accept',
    );
  });
  test(
    'finishing initial profile goes Home and subsequent visits go to Profile',
    () {
      final guard = AppRouteGuard();
      final path = Uri.parse('/onboarding');
      expect(
        guard.redirectFor(AuthStatus.authenticated, path, onboarding: true),
        isNull,
      );
      expect(guard.redirectFor(AuthStatus.authenticated, path), '/home');
      expect(guard.redirectFor(AuthStatus.authenticated, path), '/profile');
    },
  );
}
