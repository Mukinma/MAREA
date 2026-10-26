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
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/configuration_screen.dart';
import 'package:marea/features/profile/data/profile_repository.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/legal/legal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final config = AppConfig.fromEnvironment();
  if (!config.isValid) {
    runApp(ConfigurationScreen(message: config.validationMessage!));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  runApp(
    MareaApp(
      controller: AppSessionController(
        authRepository: SupabaseAuthRepository(client),
        push: PushController(
          SupabaseNotificationPreferencesRepository(client),
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
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
        legalRepository: SupabaseLegalRepository(client),
      ),
    ),
  );
}
