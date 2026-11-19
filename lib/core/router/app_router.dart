import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/features/ar_markers/presentation/marker_management_screen.dart';
import 'package:marea/features/ar_markers/presentation/marker_editor_screen.dart';
import 'package:marea/features/ar_markers/presentation/marker_scan_screen.dart';
import 'package:marea/features/ar_markers/presentation/marker_review_screen.dart';
import 'package:marea/features/proximity/presentation/proximity_settings_screen.dart';
import 'package:marea/features/tours/presentation/business_ar_screen.dart';
import 'package:marea/features/missions/presentation/mission_catalog_screen.dart';
import 'package:marea/features/home_feed/presentation/story_composer.dart';
import 'package:marea/features/tours/presentation/tour_management_screen.dart';
import 'package:marea/features/tours/presentation/tour_editor_screen.dart';
import 'package:marea/features/tours/presentation/tour_visit_screen.dart';
import 'package:marea/features/tours/presentation/tour_ar_screen.dart';
import 'package:marea/features/tours/presentation/tour_discovery_screen.dart';
import 'package:marea/features/tours/capture/tour_capture_screen.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/features/community/presentation/mission_application_screen.dart';
import 'package:marea/features/community/presentation/mission_management_screen.dart';
import 'package:marea/features/community/presentation/post_detail_screen.dart';
import 'package:marea/features/community/presentation/post_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/profile/presentation/profile_setup_screen.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_composer_screen.dart';
import 'package:marea/features/showcase/presentation/showcase_detail_screen.dart';
import 'package:marea/features/showcase/presentation/create_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/auth/data/mobile_intro_store.dart';
import 'package:marea/features/auth/presentation/welcome_entry_screen.dart';
import 'package:marea/features/auth/presentation/security_screen.dart';
import 'package:marea/features/auth/presentation/account_security_screen.dart';
import 'package:marea/features/legal/legal_screens.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/splash_screen.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/features/community/presentation/support_settings_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:marea/features/shell/presentation/marea_create_action.dart';
import 'package:marea/features/map/presentation/mission_map_screen.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/community_collection_screen.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/community/presentation/moderation_screen.dart';
import 'package:marea/features/chat/presentation/chat_screen.dart';
import 'package:marea/features/chat/presentation/chat_privacy_screen.dart';
import 'access_destination_store.dart'
    if (dart.library.js_interop) 'access_destination_store_web.dart';

abstract final class AppRouter {
  static const _mfaPath = '/auth/verify-2fa';
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
    bool recoveryComplete = false,
    bool onboarding = false,
    bool legal = false,
    bool needsMfa = false,
  }) {
    if (_publicDocs.contains(location)) return null;
    if (status == AuthStatus.initializing) return location == '/' ? null : '/';
    if (status == AuthStatus.unauthenticated) {
      if (location == '/') return '/welcome';
      return _authPaths.contains(location) ? null : '/login';
    }
    if (needsMfa) return location == _mfaPath ? null : _mfaPath;
    if (recovery) {
      return location == '/reset-password' ? null : '/reset-password';
    }
    if (recoveryComplete) {
      return location == '/password-updated' ? null : '/password-updated';
    }
    if (legal) {
      return location == '/legal/accept' ||
              location == '/settings' ||
              location == '/settings/personal'
          ? null
          : '/legal/accept';
    }
    if (onboarding) {
      return location == '/onboarding' ? null : '/onboarding';
    }
    if (location == '/onboarding') return '/profile';
    return location == '/' ||
            location == _mfaPath ||
            _authPaths.contains(location) ||
            location == '/legal/accept' ||
            location == '/reset-password' ||
            location == '/password-updated'
        ? '/home'
        : null;
  }

  static Widget _profileSetup(
    AppSessionController controller, {
    bool preferencesOnly = false,
  }) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => controller.profile == null
        ? const Scaffold(
            body: Center(child: MareaSkeleton(kind: SkeletonKind.profile)),
          )
        : ProfileSetupScreen(
            key: ValueKey(controller.profile!.id),
            controller: controller,
            preferencesOnly: preferencesOnly,
          ),
  );

  static GoRouter create(
    AppSessionController controller, {
    MobileIntroStore? mobileIntroStore,
    bool allowGoogle = true,
  }) {
    final rootKey = GlobalKey<NavigatorState>();
    final guard = AppRouteGuard(persistDestination: true);
    final introStore = mobileIntroStore ?? SharedPreferencesMobileIntroStore();
    GoRouterWidgetBuilder withCreate(GoRouterWidgetBuilder build) =>
        (context, state) => MareaCreationPage(
          controller: controller,
          child: build(context, state),
        );

    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      refreshListenable: controller,
      redirect: (_, state) => guard.redirectFor(
        controller.status,
        state.uri,
        recovery: controller.isRecovering,
        recoveryComplete: controller.isRecoveryComplete,
        onboarding: controller.needsOnboarding,
        legal: controller.needsLegalAcceptance,
        needsMfa: controller.needsMfa,
      ),
      errorBuilder: (_, _) => Scaffold(
        body: Center(
          child: Text(AppLocalizations.tr('Esta página no existe.')),
        ),
      ),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: _mfaPath,
          builder: (_, _) => ProfileFlatStyle(
            child: MfaChallengeScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, _) => WelcomeEntryScreen(
            store: introStore,
            controller: controller,
            allowGoogle: allowGoogle,
          ),
        ),
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
          builder: (_, _) => PasswordUpdatedScreen(
            onContinue: controller.continueAfterRecovery,
          ),
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
            allowGoogle: allowGoogle,
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
            returnToMissions:
                state.uri.path == '/map' &&
                state.uri.queryParameters['from'] == 'missions',
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
              path: '/discover',
              redirect: (_, state) =>
                  state.uri.replace(path: '/missions').toString(),
            ),
            GoRoute(
              path: '/explore',
              redirect: (_, state) => _legacyExploreDestination(state.uri),
            ),
            for (final entry in const {
              '/profile/saved': 'saved',
              '/search/people': 'people',
              '/search/showcases': 'showcases',
            }.entries)
              GoRoute(
                path: entry.key,
                builder: (_, state) => CommunityCollectionScreen(
                  key: ValueKey((controller.profile?.id, state.uri)),
                  controller: controller,
                  section: entry.value,
                  initialCategory: _routeCategory(state.uri),
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
              builder: (_, state) {
                final section = state.uri.queryParameters['section'];
                final key = ValueKey((controller.profile?.id, section));
                return switch (section) {
                  'own' || 'drafts' || 'applications' => PersonalMissionsScreen(
                    key: key,
                    controller: controller,
                    initialSection: section!,
                  ),
                  _ => MissionCatalogScreen(
                    key: key,
                    session: controller,
                    compatibleOnly: section == 'compatible',
                    savedOnly: section == 'saved',
                  ),
                };
              },
            ),
            GoRoute(
              path: '/map',
              builder: (_, state) => MissionMapScreen(
                key: ValueKey((controller.profile?.id, state.uri)),
                session: controller,
                initialQuery: state.uri.queryParameters['q'] ?? '',
                initialCategory: _routeCategory(state.uri),
                showTours: state.uri.queryParameters['experiences'] == '1',
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => ProfileScreen(controller: controller),
            ),
          ],
        ),
        GoRoute(
          path: '/messages',
          builder: (_, state) => ChatInboxScreen(
            key: ValueKey(controller.profile?.id),
            controller: controller,
            initialConversationId: state.uri.queryParameters['conversation'],
          ),
        ),
        GoRoute(
          path: '/stories/new',
          builder: (_, _) =>
              StoryComposer(controller: controller, autoOpenCamera: true),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/posts/new',
          builder: (_, _) => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.tr('Crear publicación')),
            ),
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
          builder: withCreate(
            (_, state) => ShowcaseDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              controller: controller,
              itemId: state.pathParameters['id']!,
            ),
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
          builder: withCreate(
            (_, state) => MissionApplicationSentScreen(
              key: ValueKey('sent:${state.uri}'),
              controller: controller,
              missionId: state.pathParameters['id']!,
              applicationId: state.uri.queryParameters['application'],
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id/manage',
          builder: withCreate(
            (_, state) => MissionManagementScreen(
              key: ValueKey(
                'manage:${state.pathParameters['id']}:${controller.profile?.id}',
              ),
              controller: controller,
              missionId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/missions/:id',
          builder: withCreate(
            (_, state) => MissionDetailScreen(
              key: ValueKey(state.uri.toString()),
              controller: controller,
              missionId: state.pathParameters['id']!,
              panel: state.uri.queryParameters['panel'],
              commentId: state.uri.queryParameters['comment'],
              notificationId: state.uri.queryParameters['notification'],
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/messages/:id',
          builder: (_, state) => ChatConversationScreen(
            key: ValueKey((controller.profile?.id, state.pathParameters['id'])),
            controller: controller,
            conversationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/search/posts',
          builder: (_, state) => PostSearchScreen(
            key: ValueKey((controller.profile?.id, state.uri)),
            controller: controller,
            discoverOnly: state.uri.queryParameters['from'] == 'discover',
            initialCategory: _routeCategory(state.uri),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/posts/:id',
          builder: (_, state) => PostDetailScreen(
            key: ValueKey((controller.profile?.id, state.uri)),
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
            appBar: AppBar(title: Text(AppLocalizations.tr('Tu publicación'))),
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
          path: '/tours',
          parentNavigatorKey: rootKey,
          builder: withCreate(
            (_, _) => TourManagementScreen(
              key: ValueKey(controller.profile?.id),
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: '/ar-markers',
          parentNavigatorKey: rootKey,
          builder: withCreate((_, state) {
            final device = state.uri.queryParameters['device'] == '1';
            final repository = device
                ? controller.deviceMarkerRepository
                : controller.markerRepository;
            return repository == null
                ? const _MarkerUnavailable()
                : MarkerManagementScreen(
                    key: ValueKey((controller.profile?.id, device)),
                    controller: controller,
                    repository: repository,
                    device: device,
                  );
          }),
        ),
        GoRoute(
          path: '/ar-markers/new',
          parentNavigatorKey: rootKey,
          builder: (_, state) {
            final repository = state.uri.queryParameters['device'] == '1'
                ? controller.deviceMarkerRepository
                : controller.markerRepository;
            return repository == null
                ? const _MarkerUnavailable()
                : MarkerEditorScreen(
                    key: ValueKey(
                      'new-marker:${controller.profile?.id}:${state.uri}',
                    ),
                    controller: controller,
                    repository: repository,
                  );
          },
        ),
        GoRoute(
          path: '/ar-markers/:id/edit',
          parentNavigatorKey: rootKey,
          builder: (_, state) {
            final repository = state.uri.queryParameters['device'] == '1'
                ? controller.deviceMarkerRepository
                : controller.markerRepository;
            return repository == null
                ? const _MarkerUnavailable()
                : MarkerEditorScreen(
                    key: ValueKey('${controller.profile?.id}:${state.uri}'),
                    controller: controller,
                    repository: repository,
                    markerId: state.pathParameters['id'],
                  );
          },
        ),
        GoRoute(
          path: '/ar-markers/:id/scan',
          parentNavigatorKey: rootKey,
          builder: (_, state) {
            final repository = state.uri.queryParameters['remote'] == '1'
                ? controller.markerRepository
                : controller.deviceMarkerRepository ??
                      controller.markerRepository;
            return repository == null
                ? const _MarkerUnavailable()
                : MarkerScanScreen(
                    key: ValueKey('${controller.profile?.id}:${state.uri}'),
                    controller: controller,
                    repository: repository,
                    markerId: state.pathParameters['id']!,
                  );
          },
        ),
        GoRoute(
          path: '/ar-markers/:id/visit',
          parentNavigatorKey: rootKey,
          builder: (_, state) {
            final repository = controller.markerPublicationRepository;
            return repository == null
                ? const _MarkerUnavailable()
                : MarkerScanScreen(
                    key: ValueKey('${controller.profile?.id}:${state.uri}'),
                    controller: controller,
                    repository: repository,
                    markerId: state.pathParameters['id']!,
                    publicVisit: true,
                  );
          },
        ),
        GoRoute(
          path: '/moderation/ar-markers',
          parentNavigatorKey: rootKey,
          builder: (_, _) => MarkerReviewScreen(
            key: ValueKey(controller.profile?.id),
            controller: controller,
          ),
        ),
        GoRoute(
          path: '/nearby-alerts',
          parentNavigatorKey: rootKey,
          builder: (_, _) => ProximitySettingsScreen(
            key: ValueKey(controller.profile?.id),
            controller: controller,
          ),
        ),
        GoRoute(
          path: '/tours/new',
          parentNavigatorKey: rootKey,
          builder: (_, _) => TourEditorScreen(
            key: ValueKey('new-tour:${controller.profile?.id}'),
            controller: controller,
          ),
        ),
        GoRoute(
          path: '/tours/requests',
          parentNavigatorKey: rootKey,
          builder: withCreate(
            (_, _) => TourRequestsScreen(
              key: ValueKey(controller.profile?.id),
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: '/tours/nearby',
          parentNavigatorKey: rootKey,
          builder: withCreate(
            (_, _) => TourDiscoveryScreen(
              key: ValueKey(controller.profile?.id),
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: '/tours/:id/edit',
          parentNavigatorKey: rootKey,
          builder: (_, s) => TourEditorScreen(
            key: ValueKey(
              '${controller.profile?.id}:${s.pathParameters['id']}',
            ),
            controller: controller,
            tourId: s.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/tours/:id/capture',
          parentNavigatorKey: rootKey,
          builder: (_, s) => TourCaptureScreen(
            key: ValueKey('${controller.profile?.id}:${s.uri}'),
            controller: controller,
            tourId: s.pathParameters['id']!,
            sceneId: s.uri.queryParameters['scene'] ?? '',
            importOnly: s.uri.queryParameters['import'] == 'true',
          ),
        ),
        GoRoute(
          path: '/tours/:id/business-ar',
          parentNavigatorKey: rootKey,
          builder: (_, s) => BusinessARScreen(
            key: ValueKey('${controller.profile?.id}:${s.uri}'),
            controller: controller,
            tourId: s.pathParameters['id']!,
            ownerId: s.uri.queryParameters['owner'] ?? '',
            pointId: s.uri.queryParameters['point'] ?? '',
          ),
        ),
        GoRoute(
          path: '/tours/:id/ar',
          parentNavigatorKey: rootKey,
          builder: (_, s) => TourARScreen(
            key: ValueKey('${controller.profile?.id}:${s.uri}'),
            controller: controller,
            tourId: s.pathParameters['id']!,
            preview: s.uri.queryParameters['preview'] == 'true',
            pointId: s.uri.queryParameters['point'],
          ),
        ),
        GoRoute(
          path: '/tours/:id',
          parentNavigatorKey: rootKey,
          builder: withCreate(
            (_, s) => TourVisitScreen(
              key: ValueKey('${controller.profile?.id}:${s.uri}'),
              controller: controller,
              tourId: s.pathParameters['id']!,
              preview: s.uri.queryParameters['preview'] == 'true',
              pointId: s.uri.queryParameters['point'],
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/moderation',
          builder: withCreate(
            (_, _) => ModerationScreen(controller: controller),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/profile/edit',
          builder: (_, state) => ProfileFlatStyle(
            child: EditProfileScreen(
              controller: controller,
              initialSection: state.uri.queryParameters['section'],
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/settings',
          builder: (_, _) => SettingsScreen(controller: controller),
        ),
        GoRoute(
          path: '/settings/personal',
          builder: (_, _) => ProfileFlatStyle(
            child: PersonalDataScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (_, _) => AccountNotificationsScreen(controller: controller),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (_, _) => ProfileFlatStyle(
            child: ChatPrivacyScreen(
              key: ValueKey(controller.profile?.id),
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: '/settings/security',
          builder: (_, _) => ProfileFlatStyle(
            child: AccountSecurityScreen(
              key: ValueKey(controller.profile?.id),
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: '/settings/support',
          builder: (_, _) => SupportSettingsScreen(controller: controller),
        ),
        GoRoute(
          path: '/settings/support/reports',
          builder: (_, _) => UserReportsScreen(
            key: ValueKey(controller.profile?.id),
            controller: controller,
          ),
        ),
      ],
    );
  }
}

class _MarkerUnavailable extends StatelessWidget {
  const _MarkerUnavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const ProfileBackButton(fallback: '/explore')),
    body: Center(
      child: Text(
        AppLocalizations.tr('Esta experiencia ya no está disponible.'),
      ),
    ),
  );
}

class AppRouteGuard {
  AppRouteGuard({bool persistDestination = false})
    : _persistDestination = persistDestination,
      _requestedLocation = persistDestination
          ? internalDestination(readAccessDestination())
          : null;

  final bool _persistDestination;
  String? _requestedLocation;
  bool _visitedPendingProfile = false;

  void _remember(String? location) {
    if (_requestedLocation == location) return;
    _requestedLocation = location;
    if (_persistDestination) {
      writeAccessDestination(internalDestination(location));
    }
  }

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
          r'^/(explore|discover|map|people/[A-Za-z0-9_-]+|showcase/[A-Za-z0-9_-]+(?:/edit)?|messages(?:/[A-Za-z0-9_-]+)?|settings(?:/(?:personal|notifications|privacy|security|support(?:/reports)?))?|profile/(?:edit|saved)|tours(?:/new|/requests|/nearby|/[A-Za-z0-9_-]+(?:/(?:edit|capture|ar|business-ar))?)?|ar-markers(?:/new|/[A-Za-z0-9_-]+/(?:edit|scan))?|nearby-alerts|search/(?:posts|people|showcases)|posts/[A-Za-z0-9_-]+|missions(?:/new|/drafts/[A-Za-z0-9_-]+/edit|/[A-Za-z0-9_-]+(?:/(?:edit|apply|sent|manage))?)?)$',
        ).hasMatch(uri.path)) {
      return null;
    }
    return uri.toString();
  }

  String? redirectFor(
    AuthStatus status,
    Uri uri, {
    bool recovery = false,
    bool recoveryComplete = false,
    bool onboarding = false,
    bool legal = false,
    bool needsMfa = false,
  }) {
    if (_requestedLocation == null) {
      _remember(internalDestination(uri.queryParameters['returnTo']));
    }
    final post = internalDestination(uri.toString());
    if (post != null &&
        (status != AuthStatus.authenticated ||
            needsMfa ||
            recovery ||
            recoveryComplete ||
            onboarding ||
            legal)) {
      _remember(post);
    }
    final previousPendingProfile = _visitedPendingProfile;
    _visitedPendingProfile =
        status == AuthStatus.authenticated &&
        onboarding &&
        (previousPendingProfile || uri.path == '/onboarding');
    final appRedirect = AppRouter.redirectFor(
      status,
      uri.path,
      recovery: recovery,
      recoveryComplete: recoveryComplete,
      onboarding: onboarding,
      legal: legal,
      needsMfa: needsMfa,
    );
    final redirect =
        previousPendingProfile &&
            uri.path == '/onboarding' &&
            appRedirect == '/profile'
        ? '/home'
        : appRedirect;
    if (status == AuthStatus.initializing) {
      if (redirect == '/' && uri.path != '/') {
        if (_requestedLocation == null) _remember(uri.toString());
      }
      return redirect;
    }
    final requested = _requestedLocation;
    if (requested != null) {
      if (status == AuthStatus.authenticated &&
          !needsMfa &&
          !recovery &&
          !recoveryComplete &&
          !onboarding &&
          !legal &&
          (uri.path == '/' ||
              uri.path == AppRouter._mfaPath ||
              AppRouter._authPaths.contains(uri.path) ||
              uri.path == '/legal/accept' ||
              uri.path == '/onboarding' ||
              uri.path == '/password-updated')) {
        _remember(null);
        return requested;
      }
      if (uri.path == '/') {
        return AppRouter.redirectFor(
              status,
              Uri.parse(requested).path,
              recovery: recovery,
              recoveryComplete: recoveryComplete,
              onboarding: onboarding,
              legal: legal,
              needsMfa: needsMfa,
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
              uri.path == AppRouter._mfaPath ||
              uri.path == '/legal/accept' ||
              uri.path == '/onboarding' ||
              uri.path == '/reset-password' ||
              uri.path == '/password-updated')) {
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

String? _routeCategory(Uri uri) {
  final category = uri.queryParameters['category'];
  return communityCategories.containsKey(category) ? category : null;
}

String _legacyExploreDestination(Uri uri) {
  final category = _routeCategory(uri);
  final discovery = uri.queryParameters['from'] == 'discover';
  final path = switch (uri.queryParameters['section']) {
    'people' => '/search/people',
    'showcases' => '/search/showcases',
    'saved' => '/profile/saved',
    'posts' => '/search/posts',
    _ => category != null || discovery ? '/search/posts' : '/home',
  };
  final parameters = {
    if (category != null && path != '/search/people') 'category': category,
    if (discovery && path == '/search/posts') 'from': 'discover',
  };
  return Uri(path: path, queryParameters: parameters.isEmpty ? null : parameters).toString();
}
