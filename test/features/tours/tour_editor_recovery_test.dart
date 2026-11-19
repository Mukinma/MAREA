import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/shell/presentation/marea_create_action.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_editor_screen.dart';
import 'package:marea/features/tours/presentation/tour_management_screen.dart';
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
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async => saves == 0 ? [] : [TourRecord(clone(data))];

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
    data['state'] = 'published';
    data['public_revision_id'] = data['revision_id'];
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

Future<void> chooseEditorStep(WidgetTester tester, String label) async {
  final step = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(step);
  await tester.tap(step);
  await tester.pumpAndSettle();
}

class PointEditorRepo extends EditorialRepo {
  PointEditorRepo({bool reference = false}) {
    data = clone(data);
    TourRecord(data).document.scenes.first.data['points'] = [
      {
        'id': 'point',
        'name': 'Mural del local',
        'description': 'Encuentra el mural',
        if (reference)
          'ar': {
            'reference_path': 'owner/references/reference.jpg',
            'reference_version': 'reference-v1',
            'tested_version': 'reference-v1',
            'width_cm': 20,
          },
      },
    ];
  }
}

void main() {
  testWidgets('a new tour created from the shared menu updates the list', (
    tester,
  ) async {
    final repo = EditorialRepo(), controller = await session(repo);
    final router = GoRouter(
      initialLocation: '/tours',
      routes: [
        GoRoute(
          path: '/tours',
          builder: (_, _) => MareaCreationPage(
            controller: controller,
            child: TourManagementScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: '/tours/new',
          builder: (_, _) => TourEditorScreen(
            controller: controller,
            localStore: MemoryDrafts(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Crear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear recorrido 360°'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Título del recorrido'),
      'Nuevo recorrido',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre del local'),
      'Nuestro taller',
    );
    final save = find.text('Guardar borrador');
    await tester.scrollUntilVisible(
      save,
      180,
      scrollable: find
          .descendant(
            of: find.byType(TourEditorScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo recorrido'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    controller.dispose();
  });
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
      await chooseEditorStep(tester, 'Publicar');
      await tester.ensureVisible(find.text('Subir recorrido'));
      await tester.tap(find.text('Subir recorrido'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.saves, 0);
      await tester.ensureVisible(find.text('Subir recorrido'));
      await tester.tap(find.text('Subir recorrido'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.saves, 0);
      expect(find.text('Publicado'), findsOneWidget);
      expect(find.text('Respuesta perdida'), findsNothing);
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );
  testWidgets('point exposes one AR action and moves editing into a menu', (
    tester,
  ) async {
    final repo = PointEditorRepo(), c = await session(repo);
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
    expect(find.text('Editar recorrido 360°'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Puntos y AR'), findsNothing);
    await tester.tap(find.byTooltip('Más opciones del recorrido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Puntos y AR'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Añadir imagen RA'));
    expect(find.text('Editar texto'), findsNothing);
    expect(find.text('Vincular contenido'), findsNothing);
    await tester.tap(find.byTooltip('Más opciones de Mural del local'));
    await tester.pumpAndSettle();
    expect(find.text('Editar texto'), findsOneWidget);
    expect(find.text('Ubicar en 360°'), findsOneWidget);
    await tester.tap(find.text('Editar texto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Texto actualizado');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Texto actualizado'), findsOneWidget);
    expect(repo.saves, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'an earlier pending submission is published instead of reconciled as done',
    (tester) async {
      final repo = EditorialRepo()..data['state'] = 'submitted';
      final c = await session(repo);
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
      await chooseEditorStep(tester, 'Publicar');
      await tester.ensureVisible(find.text('Subir recorrido'));
      await tester.tap(find.text('Subir recorrido'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.data['state'], 'published');
      expect(repo.saves, 0);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'adding a panorama creates its position and reuses it after returning',
    (tester) async {
      final repo = EditorialRepo()
        ..data['document'] = TourDocument.empty().data;
      final c = await session(repo);
      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/edit',
            builder: (_, _) => TourEditorScreen(
              controller: c,
              tourId: 'tour',
              localStore: MemoryDrafts(),
            ),
          ),
          GoRoute(
            path: '/tours/:id/capture',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Volver de captura'),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await chooseEditorStep(tester, 'Panoramas');
      await tester.ensureVisible(find.text('Añadir panorama'));
      await tester.tap(find.text('Añadir panorama'));
      await tester.pumpAndSettle();
      expect(find.text('Volver de captura'), findsOneWidget);
      final sceneId = TourRecord(repo.data).document.scenes.single.id;
      await tester.tap(find.text('Volver de captura'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Añadir panorama'));
      await tester.tap(find.text('Añadir panorama'));
      await tester.pumpAndSettle();
      expect(TourRecord(repo.data).document.scenes.single.id, sceneId);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      c.dispose();
    },
  );

  testWidgets(
    'reference chooser groups photo and printed mark without replacing tested data on cancel',
    (tester) async {
      final repo = PointEditorRepo(reference: true),
          c = await session(repo),
          disk = MemoryDrafts();
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
      await tester.tap(find.byTooltip('Más opciones del recorrido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Puntos y AR'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Volver a probar RA'));
      await tester.tap(find.byTooltip('Más opciones de Mural del local'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar imagen RA'));
      await tester.pumpAndSettle();
      expect(find.text('Usar una imagen del lugar'), findsOneWidget);
      expect(find.text('Crear una marca para imprimir'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Volver a probar RA'), findsOneWidget);
      expect(
        TourRecord(repo.data).document.point('point')!.ar!['tested_version'],
        'reference-v1',
      );
      expect(repo.saves, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'continue synchronizes entered fields before advancing the editor',
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
      await tester.enterText(
        find.byType(TextField).first,
        'Recorrido corregido',
      );
      await tester.scrollUntilVisible(
        find.text('Continuar'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      final steps = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(steps.indexWhere((step) => step.selected), 1);
      await tester.scrollUntilVisible(
        find.text('Guardar borrador'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.data['title'], 'Recorrido corregido');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
