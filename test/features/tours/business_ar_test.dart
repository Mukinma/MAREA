import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/tours/models/business_ar_target.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/business_ar_screen.dart';

import '../../support/fakes.dart';
import 'tour_ar_recovery_test.dart' show ARRepo, ARFiles;

class BusinessRepo extends ARRepo {
  BusinessRepo() {
    data['state'] = 'published';
  }
  @override
  Future<List<TourRecord>> publicList(String owner) async => [TourRecord(data)];
}

class Profiles implements CommunityRepository {
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: sampleProfile.id,
      fullName: 'Café de prueba',
      username: 'cafe',
      userType: sampleProfile.userType,
      bio: 'Descripción pública',
    ),
  ];
  @override
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  }) async => [
    for (final id in ['active', 'expired', 'hidden', 'closed'])
      Mission(
        id: id,
        authorId: sampleProfile.id,
        title: 'Misión $id',
        body: '',
        category: 'other',
        location: 'Centro',
        startsAt: DateTime.now().add(Duration(days: id == 'expired' ? -1 : 10)),
        capacity: 5,
        createdAt: DateTime.now(),
        hidden: id == 'hidden',
        status: id == 'closed' ? 'closed' : 'open',
      ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppSessionController> controller(BusinessRepo repo) async {
  final result = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    legalRepository: FakeLegalRepository(),
    communityRepository: Profiles(),
    tourRepository: repo,
  );
  await result.initialize();
  return result;
}

Future<void> send(WidgetTester tester, Map<String, dynamic> value) async {
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'marea/tour_ar/events',
    const StandardMethodCodec().encodeSuccessEnvelope(value),
    (_) {},
  );
  // EventChannel delivers through an asynchronous stream. The first pump
  // delivers the event and schedules a frame; the second draws that frame.
  await tester.pump();
  await tester.pump();
}

// Platform cancellation may complete outside the test's fake-async zone.
// Wait for the visible destination, allowing both real microtasks and frames.
Future<void> _waitForPlatformWidget(WidgetTester tester, Finder target) async {
  for (var frame = 0; frame < 60; frame++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 16));
    if (target.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .where((text) => text.isNotEmpty)
      .join(' | ');
  fail('La transición no mostró $target. Textos presentes: $texts');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('marea/tour_ar');
  const events = MethodChannel('marea/tour_ar/events');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (_) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(events, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(events, null);
  });
  test(
    'public targets exclude drafts, paused tours, other owners and untested versions',
    () {
      final repo = BusinessRepo();
      expect(
        BusinessARTarget.fromPublicTours([
          TourRecord(repo.data),
        ], sampleProfile.id),
        hasLength(2),
      );
      for (final state in ['draft', 'paused']) {
        expect(
          BusinessARTarget.fromPublicTours([
            TourRecord({...repo.data, 'state': state}),
          ], sampleProfile.id),
          isEmpty,
        );
      }
      expect(
        BusinessARTarget.fromPublicTours([
          TourRecord(repo.data),
        ], 'someone-else'),
        isEmpty,
      );
      expect(
        BusinessARTarget.isTestedReference({
          'reference_path': 'p',
          'width_cm': 20,
        }),
        isFalse,
      );
      expect(
        BusinessARTarget.isTestedReference({
          'reference_path': 'p',
          'width_cm': 20,
          'reference_version': 'new',
          'tested_version': 'old',
        }),
        isFalse,
      );
      expect(
        BusinessARTarget.isTestedReference({
          'reference_path': '',
          'width_cm': 20,
          'reference_version': 'v',
          'tested_version': 'v',
        }),
        isFalse,
      );
      expect(
        BusinessARTarget.isTestedReference({
          'reference_path': 'p',
          'width_cm': double.nan,
          'reference_version': 'v',
          'tested_version': 'v',
        }),
        isFalse,
      );
    },
  );
  test('homography maps every corner onto the native perspective plane', () {
    const viewport = Size(400, 800), card = Size(280, 120);
    const corners = [.2, .3, .8, .35, .7, .65, .25, .6];
    final transform = arCardTransform(corners, viewport, card)!;
    final local = [
      Offset.zero,
      Offset(card.width, 0),
      Offset(card.width, card.height),
      Offset(0, card.height),
    ];
    for (var i = 0; i < 4; i++) {
      final projected = MatrixUtils.transformPoint(transform, local[i]);
      expect(projected.dx, closeTo(corners[2 * i] * viewport.width, .0001));
      expect(
        projected.dy,
        closeTo(corners[2 * i + 1] * viewport.height, .0001),
      );
    }
    expect(arCardTransform([0, 0, 0, 0, 0, 0, 0, 0], viewport, card), isNull);
    expect(
      arCardTransform([double.nan, 0, 0, 0, 0, 0, 0, 0], viewport, card),
      isNull,
    );
    expect(arCardTransform(null, viewport, card), isNull);
  });
  testWidgets('backgrounding during download cannot create a native camera', (
    tester,
  ) async {
    final repo = BusinessRepo(), session = await controller(BusinessRepo());
    final download = Completer<Uint8List>();
    var cameras = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessARScreen(
          controller: session,
          ownerId: sampleProfile.id,
          tourId: repo.data['id'] as String,
          pointId: 'one',
          localStore: ARFiles(),
          referenceLoader: (_) => download.future,
          cameraBuilder: (_) {
            cameras++;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir cámara'));
    await tester.tap(find.text('Abrir cámara'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    download.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(cameras, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('a paused publication cannot start a new camera session', (
    tester,
  ) async {
    final repo = BusinessRepo();
    final current = await controller(repo);
    var downloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessARScreen(
          controller: current,
          ownerId: sampleProfile.id,
          tourId: 'tour',
          pointId: 'one',
          localStore: ARFiles(),
          referenceLoader: (_) async {
            downloads++;
            return Uint8List.fromList([1, 2, 3]);
          },
          cameraBuilder: (_) => const SizedBox(key: ValueKey('native-camera')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    repo.data['paused'] = true;
    await tester.ensureVisible(find.text('Abrir cámara'));
    await tester.tap(find.text('Abrir cámara'));
    await tester.pumpAndSettle();
    expect(downloads, 0);
    expect(find.byKey(const ValueKey('native-camera')), findsNothing);
    expect(find.textContaining('ya no está disponible'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    current.dispose();
  });
  testWidgets('retrying the preview cancels a pending reference download', (
    tester,
  ) async {
    final session = await controller(BusinessRepo());
    final pending = Completer<Uint8List>();
    var downloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessARScreen(
          controller: session,
          ownerId: sampleProfile.id,
          tourId: 'tour',
          pointId: 'one',
          localStore: ARFiles(),
          referenceLoader: (_) {
            downloads++;
            return pending.future;
          },
          cameraBuilder: (_) => const SizedBox(key: ValueKey('native-camera')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir cámara'));
    await tester.tap(find.text('Abrir cámara'));
    await tester.pump();
    expect(downloads, 1);
    // The test HTTP client rejects the preview, exposing its retry action.
    await tester.ensureVisible(find.text('Reintentar imagen'));
    await tester.tap(find.text('Reintentar imagen'));
    await tester.pumpAndSettle();
    pending.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('native-camera')), findsNothing);
    expect(find.text('Preparando cámara…'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Abrir cámara'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets(
    'card needs a matching native projection and hides when lost or stalled',
    (tester) async {
      final session = await controller(BusinessRepo());
      Map<String, dynamic>? params;
      await tester.pumpWidget(
        MaterialApp(
          home: BusinessARScreen(
            controller: session,
            ownerId: sampleProfile.id,
            tourId: 'tour',
            pointId: 'one',
            localStore: ARFiles(),
            referenceLoader: (_) async => Uint8List.fromList([1, 2, 3]),
            cameraBuilder: (value) {
              params = value;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir cámara'));
      await tester.tap(find.text('Abrir cámara'));
      await tester.pumpAndSettle();
      final event = {
        'id': 'one',
        'state': 'tracking',
        'sessionId': params!['sessionId'],
        'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
      };
      expect(find.text('Toca para ver más'), findsNothing);
      await send(tester, {...event, 'sessionId': 'previous-session'});
      expect(find.text('Toca para ver más'), findsNothing);
      await send(tester, event);
      expect(find.text('Toca para ver más'), findsOneWidget);
      await send(tester, {...event, 'state': 'lost'});
      expect(find.text('Toca para ver más'), findsNothing);
      await send(tester, event);
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Toca para ver más'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  testWidgets(
    'opening information releases camera and closing requires fresh recognition',
    (tester) async {
      final session = await controller(BusinessRepo());
      Map<String, dynamic>? params;
      await tester.pumpWidget(
        MaterialApp(
          home: BusinessARScreen(
            controller: session,
            ownerId: sampleProfile.id,
            tourId: 'tour',
            pointId: 'one',
            localStore: ARFiles(),
            referenceLoader: (_) async => Uint8List.fromList([1, 2, 3]),
            cameraBuilder: (value) {
              params = value;
              return const SizedBox(key: ValueKey('native-camera'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir cámara'));
      await tester.tap(find.text('Abrir cámara'));
      await tester.pumpAndSettle();
      final oldSession = params!['sessionId'];
      await send(tester, {
        'id': 'one',
        'state': 'tracking',
        'sessionId': oldSession,
        'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
      });
      await tester.tap(find.text('Toca para ver más'));
      await _waitForPlatformWidget(tester, find.text('Descripción pública'));
      expect(find.byKey(const ValueKey('native-camera')), findsNothing);
      expect(find.text('Descripción pública'), findsOneWidget);
      expect(find.text('Misión active'), findsOneWidget);
      for (final id in ['expired', 'hidden', 'closed']) {
        expect(find.text('Misión $id'), findsNothing);
      }
      await tester.tap(find.byTooltip('Volver a cámara'));
      await _waitForPlatformWidget(
        tester,
        find.byKey(const ValueKey('native-camera')),
      );
      expect(find.byKey(const ValueKey('native-camera')), findsOneWidget);
      expect(params!['sessionId'], isNot(oldSession));
      expect(find.text('Toca para ver más'), findsNothing);
      await send(tester, {
        'id': 'one',
        'state': 'tracking',
        'sessionId': oldSession,
        'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
      });
      expect(find.text('Toca para ver más'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
}
