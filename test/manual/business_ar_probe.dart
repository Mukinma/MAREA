// Manual development target. Never import this entry point from lib/main.dart.
// flutter run -d DEVICE -t test/manual/business_ar_probe.dart
//   --dart-define=MAP_TILE_URL=http://127.0.0.1:38765/tiles/{z}/{x}/{y}.png
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';

import '../support/business_ar_fixture.dart';
import '../support/fakes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode) throw StateError('El laboratorio RA solo admite debug.');
  if (const String.fromEnvironment('SUPABASE_URL').isNotEmpty ||
      const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty) {
    throw StateError('Ejecuta el laboratorio sin archivos ni claves Supabase.');
  }
  if (const String.fromEnvironment('MAP_TILE_URL') != businessARLocalMapUrl) {
    throw StateError(
      'Agrega --dart-define=MAP_TILE_URL=$businessARLocalMapUrl',
    );
  }
  HttpOverrides.global = BusinessARLoopbackOnly();
  final assets = await BusinessARLocalAssets.start();
  final mission = businessARLocalMission();
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        fullName: 'Visitante QA local',
        username: 'visitante_qa',
        userType: UserType.general,
        locationLatitude: 19.4326,
        locationLongitude: -99.1332,
      ),
    legalRepository: FakeLegalRepository(),
    communityRepository: BusinessARLocalCommunity(mission),
    showcaseRepository: BusinessARLocalShowcase(),
    missionMapRepository: BusinessARLocalMap(mission),
    tourRepository: BusinessARLocalTours(assets.referenceUrl),
    publicUrl: 'http://127.0.0.1:${assets.port}/',
  );
  await session.initialize();
  final router = AppRouter.create(session)..go('/map');
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => Banner(
        message: 'QA LOCAL',
        location: BannerLocation.topEnd,
        color: Colors.deepOrange,
        child: child!,
      ),
    ),
  );
}
