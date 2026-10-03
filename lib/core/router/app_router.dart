import 'package:marea/features/community/presentation/mission_application_screen.dart';
import 'package:marea/features/community/presentation/mission_management_screen.dart';
import 'package:marea/features/community/presentation/post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/profile/presentation/profile_setup_screen.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_composer_screen.dart';
import 'package:marea/features/showcase/presentation/showcase_detail_screen.dart';
import 'package:marea/features/showcase/presentation/create_screen.dart';
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
import 'package:marea/features/map/presentation/mission_map_screen.dart';
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
    if (location == '/reset-password') return '/home';
    if (legal) {
      return location == '/legal/accept' || location == '/settings'
          ? null
          : '/legal/accept';
    }
    if (onboarding && location != '/onboarding') return '/onboarding';
    if (!onboarding && location == '/onboarding') return '/profile';
    return location == '/' ||
            _authPaths.contains(location) ||
            location == '/legal/accept'
        ? '/home'
        : null;
  }

  static Widget _profileSetup(
    AppSessionController controller, {
    bool preferencesOnly = false,
  }) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => controller.profile == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : ProfileSetupScreen(
            key: ValueKey(controller.profile!.id),
            controller: controller,
            preferencesOnly: preferencesOnly,
          ),
  );

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
          path: '/profile/setup',
          builder: (_, _) => _profileSetup(controller),
        ),
        GoRoute(
          path: '/profile/preferences',
          builder: (_, _) => _profileSetup(controller, preferencesOnly: true),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => OnboardingScreen(controller: controller),
        ),
        GoRoute(
          path: '/recover-password',
          builder: (_, state) => EmailCodeScreen(
            controller: controller,
            recovery: true,
            email: state.extra as String?,
          ),
        ),
        GoRoute(
          path: '/password-updated',
          builder: (_, _) => const PasswordUpdatedScreen(),
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
          builder: (_, state) => LoginScreen(
            controller: controller,
            email: state.extra as String?,
          ),
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
            controller: controller,
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
              builder: (_, state) => ExploreScreen(
                key: ValueKey(controller.profile?.id),
                controller: controller,
                initialSection: state.uri.queryParameters['section'],
              ),
            ),
            GoRoute(
              path: '/create',
              builder: (_, _) => CreateScreen(
                key: ValueKey(
                  '${controller.profile?.id}:${controller.profile?.userType.name}',
                ),
                controller: controller,
              ),
            ),
            GoRoute(
              path: '/missions',
              builder: (_, state) => MissionsScreen(
                key: ValueKey(
                  '${controller.profile?.id}:${state.uri.queryParameters['section']}',
                ),
                controller: controller,
                initialSection: state.uri.queryParameters['section'],
              ),
            ),
            GoRoute(
              path: '/map',
              builder: (_, _) => MissionMapScreen(
                key: ValueKey(controller.profile?.id),
                session: controller,
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
          path: '/posts/new',
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('Crear publicación')),
            body: PostComposerScreen(controller: controller),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/showcase/new',
          builder: (_, state) => ShowcaseComposerScreen(
            controller: controller,
            initialKind: ShowcaseKind.values
                .where((v) => v.name == state.uri.queryParameters['kind'])
                .firstOrNull,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/showcase/:id/edit',
          builder: (_, state) => ShowcaseComposerScreen(
            key: ValueKey(state.pathParameters['id']),
            controller: controller,
            itemId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/showcase/:id',
          builder: (_, state) => ShowcaseDetailScreen(
            key: ValueKey(state.pathParameters['id']),
            controller: controller,
            itemId: state.pathParameters['id']!,
          ),
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
          path: '/missions/drafts/:id/edit',
          builder: (_, state) => MissionComposerScreen(
            key: ValueKey('draft:${state.pathParameters['id']}'),
            controller: controller,
            draftId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id/apply',
          builder: (_, state) => MissionApplicationScreen(
            key: ValueKey(
              'apply:${state.pathParameters['id']}:${controller.profile?.id}',
            ),
            controller: controller,
            missionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id/sent',
          builder: (_, state) => MissionApplicationSentScreen(
            key: ValueKey('sent:${state.uri}'),
            controller: controller,
            missionId: state.pathParameters['id']!,
            applicationId: state.uri.queryParameters['application'],
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id/manage',
          builder: (_, state) => MissionManagementScreen(
            key: ValueKey(
              'manage:${state.pathParameters['id']}:${controller.profile?.id}',
            ),
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
          path: '/posts/:id',
          builder: (_, state) => PostDetailScreen(
            key: ValueKey(state.uri.toString()),
            controller: controller,
            postId: state.pathParameters['id']!,
            panel: state.uri.queryParameters['panel'],
            commentId: state.uri.queryParameters['comment'],
            interestId: state.uri.queryParameters['interest'],
            notificationId: state.uri.queryParameters['notification'],
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
          redirect: (_, state) =>
              state.pathParameters['id'] == controller.profile?.id
              ? '/profile'
              : null,
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
          builder: (_, state) => EditProfileScreen(
            controller: controller,
            initialSection: state.uri.queryParameters['section'],
          ),
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
  static String? internalDestination(String? value) {
    if (value == null ||
        !value.startsWith('/') ||
        value.startsWith('//') ||
        value.contains('\\')) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !RegExp(
          r'^/(posts/[A-Za-z0-9_-]+|missions(?:/new|/drafts/[A-Za-z0-9_-]+/edit|/[A-Za-z0-9_-]+(?:/(?:edit|apply|sent|manage))?)?)$',
        ).hasMatch(uri.path)) {
      return null;
    }
    return uri.toString();
  }

  String? redirectFor(
    AuthStatus status,
    Uri uri, {
    bool recovery = false,
    bool onboarding = false,
    bool legal = false,
  }) {
    _requestedLocation ??= internalDestination(uri.queryParameters['returnTo']);
    final post = internalDestination(uri.toString());
    if (post != null &&
        (status != AuthStatus.authenticated ||
            recovery ||
            onboarding ||
            legal)) {
      _requestedLocation = post;
    }
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
    final requested = _requestedLocation;
    if (requested != null) {
      if (status == AuthStatus.authenticated &&
          !recovery &&
          !onboarding &&
          !legal &&
          (uri.path == '/' ||
              AppRouter._authPaths.contains(uri.path) ||
              uri.path == '/legal/accept' ||
              uri.path == '/onboarding')) {
        _requestedLocation = null;
        return requested;
      }
      if (uri.path == '/') {
        return AppRouter.redirectFor(
              status,
              Uri.parse(requested).path,
              recovery: recovery,
              onboarding: onboarding,
              legal: legal,
            ) ??
            requested;
      }
      if (redirect != null && internalDestination(requested) != null) {
        return Uri(
          path: redirect,
          queryParameters: {'returnTo': requested},
        ).toString();
      }
      if (redirect == null &&
          internalDestination(requested) != null &&
          uri.queryParameters['returnTo'] != requested &&
          (AppRouter._authPaths.contains(uri.path) ||
              uri.path == '/legal/accept' ||
              uri.path == '/onboarding' ||
              uri.path == '/reset-password')) {
        return uri
            .replace(
              queryParameters: {...uri.queryParameters, 'returnTo': requested},
            )
            .toString();
      }
      return redirect;
    }
    return redirect;
  }
}
