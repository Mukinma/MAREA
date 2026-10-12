import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/presentation/mission_feed_card.dart';
import 'package:marea/features/location/models/location_models.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';

class MissionPhoto extends HomeCommunityFake {
  bool broken = false;
  @override
  Future<String> missionImageUrl(String path) =>
      broken ? Future.error(StateError('offline')) : Completer<String>().future;
}

void main() {
  for (final width in [360.0, 390.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'mission photo preserves overlays and touch targets $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = MissionPhoto();
          final session = AppSessionController(
            authRepository: FakeAuthRepository(),
            profileRepository: FakeProfileRepository(),
            communityRepository: repo,
          );
          await session.initialize();
          addTearDown(session.dispose);
          final mission = Mission(
            id: 'm',
            authorId: 'other',
            title: width == 1440
                ? 'Mercado'
                : 'Mercado Creativo en la Playa con un título largo que necesita crecer',
            body: 'Descripción',
            category: 'arte',
            location: 'Ubicación seleccionada (19.1, -104.4)',
            city: const LocationCity(name: 'Manzanillo'),
            imagePath: 'photo',
            startsAt: DateTime(2026, 12, 15, 18, 30),
            capacity: 2,
            createdAt: DateTime(2026, 10, 7),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1600),
                  textScaler: TextScaler.linear(scale),
                ),
                child: TickerMode(
                  enabled: false,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: MissionFeedCard(
                            mission: mission,
                            controller: session,
                            saved: false,
                            onSaved: (_) {},
                            onChanged: () async {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('104.4'), findsNothing);
          final title = tester.widget<Text>(find.text(mission.title));
          expect(title.style!.color, Colors.white);
          expect(
            tester
                .getSize(
                  find
                      .ancestor(
                        of: find.text(mission.title),
                        matching: find.byType(InkWell),
                      )
                      .first,
                )
                .height,
            greaterThanOrEqualTo(48),
          );
          final titleRect = tester.getRect(find.text(mission.title));
          final cityRect = tester.getRect(find.text('Manzanillo'));
          final calendarRect = tester.getRect(find.text('18:30'));
          expect(titleRect.top, greaterThan(calendarRect.bottom));
          expect(cityRect.top, greaterThanOrEqualTo(titleRect.bottom));
          final save = find.byTooltip('Guardar misión');
          expect(tester.getSize(save).shortestSide, greaterThanOrEqualTo(48));
          expect(tester.getCenter(save).dx, greaterThan(titleRect.center.dx));
        },
      );
    }
  }
  testWidgets('failed mission photo becomes full-width text card', (
    tester,
  ) async {
    final repo = MissionPhoto()..broken = true;
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      communityRepository: repo,
    );
    await session.initialize();
    addTearDown(session.dispose);
    final mission = Mission(
      id: 'm',
      authorId: 'other',
      title: 'Título sin foto',
      body: 'Descripción',
      category: 'arte',
      location: 'Manzanillo',
      imagePath: 'broken',
      startsAt: DateTime(2026, 12, 15, 18, 30),
      capacity: 2,
      createdAt: DateTime(2026, 10, 7),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MissionFeedCard(
            mission: mission,
            controller: session,
            saved: false,
            onSaved: (_) {},
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text(mission.title)).style!.color,
      AppColors.brandNavy,
    );
    expect(find.text('Me interesa colaborar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
