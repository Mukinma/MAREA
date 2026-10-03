// Browser QA fixture only. Never signs in to Supabase or adds production routes.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';

class _MapProbe implements MissionMapRepository {
  final List<Mission> values = [
    for (final (i, category, latitude, longitude, title) in [
      (0, 'arte', 19.435, -99.134, 'Pinta con la comunidad'),
      (1, 'musica', 19.435, -99.134, 'Un escenario para tu música'),
      (2, 'fotografia', 19.435, -99.134, 'Una mirada al barrio'),
      (3, 'gastronomia', 19.430, -99.130, 'Comparte tu cocina'),
      (4, 'digital', 19.437, -99.138, 'Crea una historia local'),
    ])
      Mission(
        id: 'map-$i',
        authorId: 'organizer',
        title: title,
        body: 'Colaboración de prueba para revisar la interfaz.',
        category: category,
        location: 'Ciudad de México',
        organizerName: 'Comunidad creativa',
        startsAt: DateTime(2100, 1, 1, 17),
        capacity: 8,
        createdAt: DateTime(2026),
        coordinates: PostCoordinates(
          latitude: latitude,
          longitude: longitude,
          precision: PostLocationPrecision.approximate,
        ),
      ),
  ];
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    final visible = values
        .where(
          (m) =>
              (filters.category == null || m.category == filters.category) &&
              filters.date != MissionMapDate.today &&
              (query.isEmpty ||
                  m.title.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
    return MissionMapPage(missions: visible, total: visible.length);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final map = _MapProbe();
  final community = MissionRepositoryFake()..value = map.values.first;
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        onboardingStatus: OnboardingStatus.skipped,
      ),
    communityRepository: community,
    missionMapRepository: map,
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
    ),
  );
}
