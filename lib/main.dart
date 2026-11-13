import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/community/data/mission_social_repository.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:marea/features/notifications/data/inbox_only_gateway.dart';
import 'package:marea/features/notifications/data/android_push_gateway.dart';
import 'package:marea/features/notifications/data/push_controller.dart';
import 'package:marea/features/notifications/data/notification_preferences_repository.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/showcase/data/showcase_repository.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:marea/app.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/localization/app_locale_controller.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/localization/content_translation_service.dart';
import 'package:marea/core/localization/on_device_post_translator.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/configuration_screen.dart';
import 'package:marea/features/profile/data/profile_repository.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/legal/legal_repository.dart';
import 'package:marea/features/auth/presentation/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() => startMarea();

Future<void> startMarea({bool productionPilot = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final config = AppConfig.fromEnvironment();
  if (productionPilot && (!kDebugMode || config.isDevelopment)) {
    throw StateError(
      'El piloto autorizado requiere debug y la configuración actual.',
    );
  }

  runApp(_StartupApp(productionPilot: productionPilot));
}

class _StartupApp extends StatefulWidget {
  const _StartupApp({required this.productionPilot});

  final bool productionPilot;

  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  late final Future<Widget> _app = _initializeApp();

  Future<Widget> _initializeApp() async {
    final config = AppConfig.fromEnvironment();
    if (!config.isValid) {
      return ConfigurationScreen(message: config.validationMessage!);
    }

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: widget.productionPilot
          ? FlutterAuthClientOptions(
              localStorage: SharedPreferencesLocalStorage(
                persistSessionKey:
                    'marea-ra-pilot-${Uri.parse(config.supabaseUrl).host}-auth-token',
              ),
              detectSessionInUri: false,
            )
          : config.isDevelopment
          ? FlutterAuthClientOptions(
              localStorage: SharedPreferencesLocalStorage(
                persistSessionKey: config.developmentSessionKey,
              ),
              detectSessionInUriPredicate:
                  config.acceptsDevelopmentAuthCallback,
            )
          : const FlutterAuthClientOptions(),
    );
    final client = Supabase.instance.client;
    final localeController = AppLocaleController();
    await localeController.load();
    return MareaApp(
      development: config.isDevelopment,
      productionPilot: widget.productionPilot,
      localeController: localeController,
      controller: AppSessionController(
        authRepository: SupabaseAuthRepository(
          client,
          allowGoogleOAuth: !widget.productionPilot,
        ),
        push: PushController(
          SupabaseNotificationPreferencesRepository(client),
          !widget.productionPilot &&
                  !config.isDevelopment &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android
              ? AndroidPushGateway()
              : InboxOnlyGateway(),
        ),
        communityRepository: SupabaseCommunityRepository(client),
        homeFeedRepository: SupabaseHomeFeedRepository(client),
        storiesRepository: SupabaseStoriesRepository(client),
        missionMapRepository: SupabaseMissionMapRepository(client),
        tourRepository: SupabaseTourRepository(client, config.supabaseUrl),
        socialRepository: SupabaseSocialRepository(client),
        missionSocialRepository: SupabaseMissionSocialRepository(client),
        locationRepository: SupabaseLocationRepository(client),
        publicUrl: config.publicUrl,
        showcaseRepository: SupabaseShowcaseRepository(client),
        mediaRepository: SupabaseProfileMediaRepository(),
        profileRepository: SupabaseProfileRepository(client),
        chatRepository: SupabaseChatRepository(client),
        translationService: ContentTranslationService(client),
        postContentTranslator: MlKitPostContentTranslator(),
        legalRepository: SupabaseLegalRepository(client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _app,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ConfigurationScreen(
            message: AppLocalizations.tr(
              'No se pudo iniciar la conexión con el servidor.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
