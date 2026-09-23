import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/auth/presentation/welcome_screen.dart';
import 'package:marea/features/auth/presentation/security_screen.dart';
import 'package:marea/features/legal/legal_screens.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/splash_screen.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/explore_screen.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/community/presentation/moderation_screen.dart';

abstract final class AppRouter {
  static const _authPaths = {
    '/welcome',
    '/login',
    '/register',
    '/check-email',
    '/recover-password',
  };
  static const _publicDocs = {'/terms', '/privacy', '/delete-account'};

  static String? redirectFor(
    AuthStatus status,
    String location, {
    bool recovery = false,
    bool onboarding = false,
    bool legal = false,
  }) {
    if (_publicDocs.contains(location)) return null;
    if (status == AuthStatus.initializing) return location == '/' ? null : '/';
    if (status == AuthStatus.unauthenticated) {
      if (location == '/') return '/welcome';
      return _authPaths.contains(location) ? null : '/login';
    }
    if (recovery) {
      return location == '/reset-password' ? null : '/reset-password';
    }
    if (location == '/reset-password') return '/profile';
    if (legal) {
      return location == '/legal/accept' || location == '/settings'
          ? null
          : '/legal/accept';
    }
    if (onboarding && location != '/onboarding') return '/onboarding';
    return location == '/' ||
            _authPaths.contains(location) ||
            location == '/legal/accept'
        ? '/profile'
        : null;
  }

  static GoRouter create(AppSessionController controller) {
    final rootKey = GlobalKey<NavigatorState>();
    final guard = AppRouteGuard();
    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      refreshListenable: controller,
      redirect: (_, state) => guard.redirectFor(
        controller.status,
        state.uri,
        recovery: controller.isRecovering,
        onboarding: controller.needsOnboarding,
        legal: controller.needsLegalAcceptance,
      ),
      errorBuilder: (_, _) =>
          const Scaffold(body: Center(child: Text('Esta página no existe.'))),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(
          path: '/terms',
          builder: (_, _) =>
              LegalDocumentScreen(controller: controller, kind: 'terms'),
        ),
        GoRoute(
          path: '/privacy',
          builder: (_, _) =>
              LegalDocumentScreen(controller: controller, kind: 'privacy'),
        ),
        GoRoute(
          path: '/delete-account',
          builder: (_, _) =>
              LegalDocumentScreen(controller: controller, kind: 'deletion'),
        ),
        GoRoute(
          path: '/legal/accept',
          builder: (_, _) => AcceptLegalScreen(controller: controller),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => OnboardingScreen(controller: controller),
        ),
        GoRoute(
          path: '/recover-password',
          builder: (_, _) =>
              EmailCodeScreen(controller: controller, recovery: true),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, _) =>
              SecurityScreen(controller: controller, recovery: true),
        ),
        GoRoute(
          path: '/settings/password',
          builder: (_, _) => SecurityScreen(controller: controller),
        ),
        GoRoute(
          path: '/settings/email',
          builder: (_, _) =>
              SecurityScreen(controller: controller, changeEmail: true),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => LoginScreen(controller: controller),
        ),
        GoRoute(
          path: '/register',
          builder: (_, _) => RegisterScreen(controller: controller),
        ),
        GoRoute(
          path: '/check-email',
          builder: (_, state) => EmailCodeScreen(
            controller: controller,
            recovery: false,
            email: state.extra as String?,
          ),
        ),
        ShellRoute(
          builder: (_, state, child) => AppShell(
            location: state.uri.path,
            onRefresh: state.uri.path == '/profile' ? controller.refresh : null,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => HomeScreen(
                key: ValueKey(controller.profile?.id),
                controller: controller,
              ),
            ),
            GoRoute(
              path: '/explore',
              builder: (_, _) => ExploreScreen(
                key: ValueKey(controller.profile?.id),
                controller: controller,
              ),
            ),
            GoRoute(
              path: '/create',
              builder: (_, _) => PostComposerScreen(
                key: ValueKey(
                  '${controller.profile?.id}:${controller.profile?.userType.name}',
                ),
                controller: controller,
              ),
            ),
            GoRoute(
              path: '/missions',
              builder: (_, _) => MissionsScreen(
                key: ValueKey(controller.profile?.id),
                controller: controller,
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => ProfileScreen(controller: controller),
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/new',
          builder: (_, _) => MissionComposerScreen(
            key: ValueKey('mission-new:${controller.profile?.id}'),
            controller: controller,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id/edit',
          builder: (_, state) => MissionComposerScreen(
            key: ValueKey('mission-edit:${state.pathParameters['id']}'),
            controller: controller,
            missionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id',
          builder: (_, state) => MissionDetailScreen(
            key: ValueKey(state.pathParameters['id']),
            controller: controller,
            missionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/posts/:id/edit',
          builder: (_, state) => Scaffold(
            appBar: AppBar(title: const Text('Tu publicación')),
            body: PostComposerScreen(
              key: ValueKey(
                '${controller.profile?.id}:${state.pathParameters['id']}',
              ),
              controller: controller,
              postId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/people/:id',
          builder: (_, state) => PublicProfileScreen(
            controller: controller,
            profileId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/moderation',
          builder: (_, _) => ModerationScreen(controller: controller),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/profile/edit',
          builder: (_, _) => EditProfileScreen(controller: controller),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/settings',
          builder: (_, _) => SettingsScreen(controller: controller),
        ),
      ],
    );
  }
}

class AppRouteGuard {
  String? _requestedLocation;

  String? redirectFor(
    AuthStatus status,
    Uri uri, {
    bool recovery = false,
    bool onboarding = false,
    bool legal = false,
  }) {
    final redirect = AppRouter.redirectFor(
      status,
      uri.path,
      recovery: recovery,
      onboarding: onboarding,
      legal: legal,
    );

    if (status == AuthStatus.initializing) {
      if (redirect == '/' && uri.path != '/') {
        _requestedLocation ??= uri.toString();
      }
      return redirect;
    }

    final requestedLocation = _requestedLocation;
    if (requestedLocation != null && uri.path == '/') {
      _requestedLocation = null;
      final requestedPath = Uri.parse(requestedLocation).path;
      return AppRouter.redirectFor(
            status,
            requestedPath,
            recovery: recovery,
            onboarding: onboarding,
            legal: legal,
          ) ??
          requestedLocation;
    }

    _requestedLocation = null;
    return redirect;
  }
}
