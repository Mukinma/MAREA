import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_editor_screen.dart';
import '../../support/fakes.dart';

Map<String, dynamic> clone(Map<String, dynamic> v) =>
    jsonDecode(jsonEncode(v)) as Map<String, dynamic>;

class MemoryDrafts extends TourLocalStore {
  final values = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> read(String a, String k) async =>
      values['$a/$k'];
  @override
  Future<void> write(String a, String k, Map<String, dynamic> d) async {
    values['$a/$k'] = clone(d);
  }
}

class EditorialRepo implements TourRepository {
  var saves = 0, submissions = 0;
  var data = <String, dynamic>{
    'id': 'tour',
    'owner_id': sampleProfile.id,
    'title': 'Café Marea',
    'state': 'draft',
    'revision_id': 'v1',
    'space': {
      'name': 'Café Marea',
      'context': 'Soy responsable',
      'verified': false,
    },
    'document': {
      'zones': [
        {
          'id': 'zone',
          'name': 'Barra',
          'scenes': [
            {
              'id': 'scene',
              'name': 'Barra',
              'panorama_path': 'p',
              'preview_path': 'p',
              'points': [],
              'connections': [],
            },
          ],
        },
      ],
      'start_scene_id': 'scene',
      'ar_order': [],
    },
  };
  @override
  Future<TourRecord?> get(String id, {bool edit = false}) async =>
      TourRecord(clone(data));
  @override
  Future<TourRecord> save(
    String? id,
    String title,
    Map<String, dynamic> space,
    TourDocument document,
  ) async {
    saves++;
    data = {...data, 'title': title, 'space': space, 'document': document.data};
    return TourRecord(clone(data));
  }

  @override
  Future<TourRecord> submit(String id) async {
    submissions++;
    data['state'] = 'submitted';
    if (submissions == 1) throw StateError('Respuesta perdida');
    return TourRecord(clone(data));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<AppSessionController> session(TourRepository repo) async {
  final c = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    legalRepository: FakeLegalRepository(),
    tourRepository: repo,
  );
  await c.initialize();
  return c;
}

class OfflineRepo extends EditorialRepo {
  @override
  Future<TourRecord?> get(String id, {bool edit = false}) async =>
      throw StateError('offline');
}

void main() {
  testWidgets(
    'offline reopening restores accepted local edits and back preserves them',
    (tester) async {
      final disk = MemoryDrafts();
      disk.values['${sampleProfile.id}/draft-tour'] = {
        'title': 'Cambio pendiente',
        'space': {'name': 'Local guardado'},
        'document': {'zones': [], 'ar_order': []},
        'pending': true,
      };
      final c = await session(OfflineRepo());
      await tester.pumpWidget(
        MaterialApp(
          home: TourEditorScreen(
            controller: c,
            tourId: 'tour',
            localStore: disk,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextField, 'Cambio pendiente'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Local guardado'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(
        disk.values['${sampleProfile.id}/draft-tour']?['title'],
        'Cambio pendiente',
      );
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );

  testWidgets('immediate back flushes accepted typing before leaving', (
    tester,
  ) async {
    final disk = MemoryDrafts(), c = await session(EditorialRepo());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      TourEditorScreen(controller: c, localStore: disk),
                ),
              ),
              child: const Text('Crear'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Título recién escrito',
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      disk.values['${sampleProfile.id}/draft-new']?['title'],
      'Título recién escrito',
    );
    expect(disk.values['${sampleProfile.id}/draft-new']?['pending'], true);
    expect(find.text('Crear'), findsOneWidget);
    expect(tester.takeException(), isNull);
    c.dispose();
  });
  testWidgets(
    'lost submission response reconciles without a new save or request',
    (tester) async {
      final repo = EditorialRepo(), c = await session(repo);
      await tester.pumpWidget(
        MaterialApp(
          home: TourEditorScreen(
            controller: c,
            tourId: 'tour',
            localStore: MemoryDrafts(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicación'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enviar a revisión'));
      await tester.tap(find.text('Enviar a revisión'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.saves, 0);
      await tester.ensureVisible(find.text('Enviar a revisión'));
      await tester.tap(find.text('Enviar a revisión'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.saves, 0);
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );
}
