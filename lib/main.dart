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
        communityRepository: SupabaseCommunityRepository(client),
        missionMapRepository: SupabaseMissionMapRepository(client),
        socialRepository: SupabaseSocialRepository(client),
        publicUrl: config.publicUrl,
        showcaseRepository: SupabaseShowcaseRepository(client),
        mediaRepository: SupabaseProfileMediaRepository(),
        profileRepository: SupabaseProfileRepository(client),
        legalRepository: SupabaseLegalRepository(client),
      ),
    ),
  );
}
