import 'package:marea/features/showcase/presentation/create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/ar_markers/data/marker_repository.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/showcase_repository_fake.dart';
import 'missions_screen_test.dart' show openRoute, tapVisible, capture;

class _AvailableTours implements TourRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AvailableMarkers implements MarkerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotificationReadFails implements SocialRepository {
  @override
  Stream<void> changes(String id) => const Stream.empty();
  @override
  Future<int> unreadCount() async => 1;
  @override
  Future<void> markRead({String? id, DateTime? before}) async =>
      throw const AppFailure('Sin conexión.');
  @override
  Future<List<SocialNotification>> notifications({
    bool unreadOnly = false,
    int offset = 0,
  }) async => [
    SocialNotification(
      id: 'n',
      recipientId: sampleProfile.id,
      actorId: 'author',
      postId: null,
      missionId: 'mission-1',
      kind: NotificationKind.missionAccepted,
      postTitle: 'Una invitación real',
      createdAt: DateTime.now(),
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('NunitoSans');
    for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/NunitoSans-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 390.0, 834.0, 1440.0]) {
    testWidgets('creation palette fits $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (width == 360) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      final key = GlobalKey();
      await openRoute(
        tester,
        MissionRepositoryFake(),
        '/missions',
        captureKey: key,
      );
      await tapVisible(tester, find.byTooltip('Crear'));
      final pixels = width.toInt();
      await capture(tester, key, 'mission-create-menu-$pixels');
      expect(find.byTooltip('Cerrar menú de creación'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'mission notification opens even when read acknowledgement fails',
    (tester) async {
      await openRoute(
        tester,
        MissionRepositoryFake(),
        '/missions',
        socialRepository: _NotificationReadFails(),
      );
      await tapVisible(tester, find.byTooltip('Notificaciones'));
      await tapVisible(tester, find.textContaining('Una invitación real'));
      expect(find.text('Quiero participar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('mission notification parses target without requiring a post', () {
    final n = SocialNotification.fromJson({
      'id': 'n',
      'recipient_id': 'r',
      'actor_id': 'a',
      'post_id': null,
      'mission_id': 'm',
      'kind': 'mission_accepted',
      'post_title': 'Misión',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(n.missionId, 'm');
    expect(n.postId, isNull);
  });
  testWidgets('direct create destination hides unavailable services', (
    tester,
  ) async {
    await openRoute(tester, MissionRepositoryFake(), '/create');
    expect(find.text('Crear misión'), findsOneWidget);
    for (final option in [
      'Historia',
      'Obra / proyecto',
      'Crear recorrido 360°',
      'Crear marcador RA',
    ]) {
      expect(find.text(option), findsNothing);
    }
    await tapVisible(tester, find.text('Crear misión'));
    expect(find.text('Continuar'), findsOneWidget);
  });
  for (final type in UserType.values) {
    testWidgets(
      'mobile create palette uses capability rules for ${type.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openRoute(
          tester,
          MissionRepositoryFake(),
          '/missions',
          userType: type,
          storiesRepository: StoriesFake(),
          showcaseRepository: ShowcaseRepositoryFake(),
          tourRepository: _AvailableTours(),
          markerRepository: _AvailableMarkers(),
        );
        await tapVisible(tester, find.byTooltip('Crear'));
        expect(find.byTooltip('Cerrar menú de creación'), findsOneWidget);
        final create = find.descendant(
          of: find.byType(CreationChoices),
          matching: find.text('Crear misión'),
        );
        expect(create, findsOneWidget);
        final labels = switch (type) {
          UserType.general => <String>[],
          UserType.creator => ['Obra / proyecto', 'Crear recorrido 360°'],
          UserType.entrepreneur => [
            'Producto',
            'Servicio',
            'Crear recorrido 360°',
          ],
          UserType.business => ['Servicio', 'Crear recorrido 360°'],
        };
        for (final label in [
          'Publicación',
          'Historia',
          'Crear misión',
          'Crear marcador RA',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        for (final option in [
          'Obra / proyecto',
          'Producto',
          'Servicio',
          'Crear recorrido 360°',
        ]) {
          expect(
            find.text(option),
            labels.contains(option) ? findsOneWidget : findsNothing,
          );
        }
        await tapVisible(tester, create);
        expect(find.text('Nueva misión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('saved view only lists privately saved missions', (tester) async {
    final repo = MissionRepositoryFake();
    await openRoute(tester, repo, '/missions');
    await tapVisible(tester, find.byTooltip('Misiones guardadas'));
    expect(find.text(repo.value.title), findsNothing);
    expect(find.text('Aún no has guardado misiones.'), findsOneWidget);
  });
  testWidgets('owner detail moves candidature management to a separate route', (
    tester,
  ) async {
    final repo = MissionRepositoryFake()
      ..value = missionFixture(author: sampleProfile.id)
      ..requests = [application()];
    await openRoute(tester, repo, '/missions/mission-1');
    expect(find.text('Mariana Torres'), findsNothing);
    await tapVisible(tester, find.text('Gestionar misión'));
    expect(find.text('Mariana Torres'), findsOneWidget);
  });
}
