import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_tools_sheet.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/business_ar_target.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/business_ar_screen.dart';

import '../../support/fakes.dart';

// These repositories supply public-list responses only. No native tracking or
// publication report is fabricated by the entry-point tests.
class _PublicTours implements TourRepository {
  List<TourRecord> records = [];
  final owners = <String>[];
  Future<List<TourRecord>> Function(String owner)? load;

  @override
  Future<List<TourRecord>> publicList(String owner) async {
    owners.add(owner);
    return load == null ? records : await load!(owner);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TourRecord _tour({
  String owner = 'organizer',
  String state = 'published',
  bool paused = false,
  String? testedVersion = 'reference-v1',
  List<String> points = const ['mural'],
}) => TourRecord({
  'id': 'public-tour',
  'owner_id': owner,
  'state': state,
  'paused': paused,
  'title': 'Recorrido público',
  'public_revision_id': 'public-v1',
  'revision_id': 'public-v1',
  'document': {
    'zones': [
      {
        'id': 'zone',
        'scenes': [
          {
            'id': 'scene',
            'points': [
              for (final id in points)
                {
                  'id': id,
                  'name': 'Imagen $id',
                  'ar': {
                    'reference_path': '$owner/references/$id.jpg',
                    'reference_version': 'reference-v1',
                    'tested_version': testedVersion,
                    'width_cm': 20,
                  },
                },
            ],
          },
        ],
      },
    ],
  },
});

Future<void> _mountAction(
  WidgetTester tester,
  _PublicTours repository, {
  String owner = 'organizer',
  ValueChanged<BusinessARTarget>? onOpen,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: BusinessARAction(
        ownerId: owner,
        repository: repository,
        onOpen: onOpen ?? (_) {},
      ),
    ),
  ),
);

void main() {
  for (final (description, records) in <(String, List<TourRecord>)>[
    ('no public tour', []),
    ('an untested reference', [_tour(testedVersion: null)]),
    ('an earlier reference test', [_tour(testedVersion: 'reference-v0')]),
    ('another organizer', [_tour(owner: 'someone-else')]),
    ('a draft', [_tour(state: 'draft')]),
    ('a paused publication', [_tour(paused: true)]),
  ]) {
    testWidgets('map AR entry stays hidden with $description', (tester) async {
      final repository = _PublicTours()..records = records;
      await _mountAction(tester, repository);
      await tester.pumpAndSettle();

      expect(repository.owners, ['organizer']);
      expect(find.text('Explorar en RA'), findsNothing);
      expect(find.text('Reintentar consultar RA'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a tested public reference opens its selected target', (
    tester,
  ) async {
    final repository = _PublicTours()..records = [_tour()];
    BusinessARTarget? opened;
    await _mountAction(tester, repository, onOpen: (target) => opened = target);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar en RA'));
    await tester.pumpAndSettle();

    expect(opened?.tour.ownerId, 'organizer');
    expect(opened?.tour.revisionId, 'public-v1');
    expect(opened?.point.id, 'mural');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('changing mission organizer removes the previous AR action', (
    tester,
  ) async {
    final pending = Completer<List<TourRecord>>();
    final repository = _PublicTours()
      ..load = (owner) async =>
          owner == 'organizer' ? [_tour()] : pending.future;
    await _mountAction(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Explorar en RA'), findsOneWidget);

    await _mountAction(tester, repository, owner: 'next-organizer');
    await tester.pump();
    expect(repository.owners, ['organizer', 'next-organizer']);
    expect(find.text('Explorar en RA'), findsNothing);

    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Explorar en RA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public lookup errors can be retried without opening AR', (
    tester,
  ) async {
    var attempts = 0;
    final repository = _PublicTours()
      ..load = (_) async {
        if (++attempts == 1) throw StateError('Offline');
        return [_tour()];
      };
    BusinessARTarget? opened;
    await _mountAction(tester, repository, onOpen: (target) => opened = target);
    await tester.pumpAndSettle();
    expect(find.text('Explorar en RA'), findsNothing);
    expect(opened, isNull);

    await tester.tap(find.text('Reintentar consultar RA'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Explorar en RA'), findsOneWidget);
    expect(find.text('Reintentar consultar RA'), findsNothing);
    expect(opened, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'multiple public references require choosing the physical image',
    (tester) async {
      final repository = _PublicTours()
        ..records = [
          _tour(points: ['mural', 'cartel']),
        ];
      BusinessARTarget? opened;
      await _mountAction(
        tester,
        repository,
        onOpen: (target) => opened = target,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explorar en RA'));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(find.text('Elige la imagen que vas a buscar'), findsOneWidget);
      expect(find.text('Imagen mural'), findsOneWidget);
      await tester.tap(find.text('Imagen cartel'));
      await tester.pumpAndSettle();

      expect(opened?.point.id, 'cartel');
      expect(opened?.tour.ownerId, 'organizer');
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final type in UserType.values) {
    testWidgets('${type.name} profile exposes its permitted tour tools', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository()
          ..value = sampleProfile.copyWith(userType: type),
        tourRepository: _PublicTours(),
      );
      await controller.initialize();
      addTearDown(() async {
        controller.dispose();
        await auth.close();
      });
      String? selectedRoute;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selectedRoute = await showProfileTools(
                    context,
                    profile: CommunityProfile(
                      id: sampleProfile.id,
                      fullName: sampleProfile.fullName,
                      username: sampleProfile.username,
                      userType: type,
                    ),
                    controller: controller,
                    admin: false,
                  );
                },
                child: const Text('Herramientas'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Herramientas'));
      await tester.pumpAndSettle();

      final professional = type != UserType.general;
      expect(
        find.text('Tus recorridos 360°'),
        professional ? findsOneWidget : findsNothing,
      );
      expect(find.text('Solicitudes de recorridos'), findsOneWidget);
      final destination = find.text(
        professional ? 'Tus recorridos 360°' : 'Solicitudes de recorridos',
      );
      await tester.ensureVisible(destination);
      await tester.tap(destination);
      await tester.pumpAndSettle();

      expect(selectedRoute, professional ? '/tours' : '/tours/requests');
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
