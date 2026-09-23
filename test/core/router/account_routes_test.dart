import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

void main() {
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
          '/profile',
          onboarding: false,
        ),
        isNull,
      );
    },
  );
  test('pending legal acceptance still allows account management', () {
    expect(
      AppRouter.redirectFor(
        AuthStatus.authenticated,
        '/settings',
        onboarding: true,
        legal: true,
      ),
      isNull,
    );
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
}
