import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/post_social.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import 'missions_screen_test.dart' show openRoute, tapVisible, capture;

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
      expect(find.text('Pon tu idea en movimiento'), findsOneWidget);
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
  testWidgets('every profile can create a mission from create destination', (
    tester,
  ) async {
    await openRoute(tester, MissionRepositoryFake(), '/create');
    expect(find.text('Crear misión'), findsOneWidget);
    await tapVisible(tester, find.text('Crear misión'));
    expect(find.text('Continuar'), findsOneWidget);
  });
  for (final type in UserType.values) {
    testWidgets('create palette includes mission for ${type.name}', (
      tester,
    ) async {
      await openRoute(
        tester,
        MissionRepositoryFake(),
        '/missions',
        userType: type,
      );
      await tapVisible(tester, find.byTooltip('Crear'));
      expect(find.text('Pon tu idea en movimiento'), findsOneWidget);
      expect(find.text('Crear misión'), findsNWidgets(2));
      await tapVisible(tester, find.text('Crear misión').last);
      expect(find.text('Nueva misión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('saved view only lists privately saved missions', (tester) async {
    final repo = MissionRepositoryFake();
    await openRoute(tester, repo, '/missions');
    await tapVisible(tester, find.text('Guardadas'));
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
