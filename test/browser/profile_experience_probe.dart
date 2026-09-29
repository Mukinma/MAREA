import 'package:marea/features/community/models/community_models.dart';
// Isolated visual fixture using production routes and screens, never Supabase.
// flutter run -d web-server -t test/browser/profile_experience_probe.dart --web-port 7364
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';
import '../support/showcase_repository_fake.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.ensureSemantics();
  final params = Uri.base.queryParameters;
  final type =
      UserType.values.where((t) => t.name == params['type']).firstOrNull ??
      UserType.business;
  final profiles = FakeProfileRepository()
    ..value = sampleProfile.copyWith(
      userType: type,
      fullName: type == UserType.business
          ? 'Estudio MAREA'
          : sampleProfile.fullName,
      contactUrl: type == UserType.general
          ? null
          : 'https://example.com/contacto',
      openToCollaboration: type == UserType.creator,
      location: type == UserType.business ? 'Manzanillo, Colima' : null,
      businessHours: type == UserType.business
          ? {'mon': '09:00-18:00', 'fri': '09:00-18:00', 'sun': null}
          : {},
      initialProfileCompletedAt: params['onboarding'] == 'true'
          ? null
          : DateTime.utc(2026, 9, 27),
      onboardingStatus: params['onboarding'] == 'true'
          ? OnboardingStatus.pending
          : OnboardingStatus.completed,
    );
  final showcase = ShowcaseRepositoryFake();
  if (type == UserType.business || type == UserType.entrepreneur) {
    await showcase.save(
      const ShowcaseInput(
        kind: ShowcaseKind.service,
        title: 'Diseño de identidad',
        body:
            'Damos forma a la identidad visual de tu proyecto. Diseño cercano para ideas que quieren crecer.',
        category: 'diseno',
        price: 1800,
        status: ShowcaseStatus.published,
      ),
    );
  }
  if (type == UserType.creator) {
    for (final title in ['Entre mareas', 'Luz de barrio']) {
      await showcase.save(
        ShowcaseInput(
          kind: ShowcaseKind.project,
          title: title,
          body: 'Una obra que explora la luz y el movimiento.',
          category: 'arte',
        ),
      );
    }
  }
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: profiles,
    communityRepository: _PreviewCommunity(
      CommunityProfile.fromJson({
        ...profiles.value.toJson(),
        'id': 'public-profile',
        'full_name': type == UserType.business
            ? 'Taller Brisa'
            : 'Mariana Torres',
        'username': 'publico',
      }),
    ),
    showcaseRepository: showcase,
  );
  await controller.initialize();
  final router = AppRouter.create(controller)
    ..go(params['route'] ?? '/profile');
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

class _PreviewCommunity extends MissionRepositoryFake {
  _PreviewCommunity(this.visitor);
  final CommunityProfile visitor;
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    if (ids == null || ids.contains(sampleProfile.id))
      CommunityProfile.fromJson(sampleProfile.toJson()),
    if (ids == null || ids.contains(visitor.id)) visitor,
  ];
}
