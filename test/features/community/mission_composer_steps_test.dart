import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/models/community_models.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/fakes.dart';
import 'missions_screen_test.dart'
    show openRoute, field, fill, tapVisible, capture;

class _LostPublishResponseRepository extends MissionRepositoryFake {
  bool lostResponse = true;
  @override
  Future<String> saveMissionDraft(
    Map<String, dynamic> data, {
    required String id,
  }) {
    if (publishedDrafts.containsKey(id)) {
      throw const AppFailure('El borrador ya está publicado.');
    }
    return super.saveMissionDraft(data, id: id);
  }

  @override
  Future<String> publishMissionDraft(String id, MissionInput input) async {
    final result = await super.publishMissionDraft(id, input);
    if (lostResponse) {
      lostResponse = false;
      throw const AppFailure('Se perdió la respuesta. Inténtalo nuevamente.');
    }
    return result;
  }
}

class _LostSaveResponseRepository extends MissionRepositoryFake {
  @override
  Future<String> saveMissionDraft(
    Map<String, dynamic> data, {
    required String id,
  }) async {
    await super.saveMissionDraft(data, id: id);
    throw const AppFailure('Respuesta de guardado perdida.');
  }
}

Future<void> _chooseFutureDate(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tapVisible(tester, find.text('Seleccionar fecha'));
  final l = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  );
  await tester.tap(find.byTooltip(l.nextMonthTooltip));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15').last);
  await tester.tap(find.text(l.okButtonLabel));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('NunitoSans');
    for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/NunitoSans-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final width in [390, 834, 1440]) {
    testWidgets(
      'review shows all conditions and editing preserves values at $width px',
      (tester) async {
        tester.view.physicalSize = Size(width.toDouble(), 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final repo = MissionRepositoryFake();
        const id = 'de534381-c948-4335-8b16-d2759c61c2ee';
        repo.drafts[id] = MissionDraft(
          id: id,
          updatedAt: DateTime.now(),
          data: {
            'title': 'Retrata la vida de nuestro mercado',
            'body':
                'Queremos mostrar la nueva vida del mercado: sus puestos, su gente y la energía del barrio.',
            'category': 'fotografia',
            'location': 'Mercado del centro',
            'capacity': 3,
            'starts_at': DateTime.now()
                .add(const Duration(days: 7))
                .toUtc()
                .toIso8601String(),
            'requirements': 'Experiencia fotografiando comercios locales.',
            'conditions':
                'Entregar diez fotografías editadas en una semana. Compartiremos los créditos de cada participante.',
            'compensation_type': 'paid',
            'compensation_amount_cents': 25050,
          },
        );
        final key = GlobalKey();
        await openRoute(
          tester,
          repo,
          '/missions/drafts/$id/edit',
          captureKey: key,
        );
        await capture(tester, key, 'mission-composer-idea-$width');
        await tapVisible(tester, find.text('Continuar'));
        await capture(tester, key, 'mission-composer-collaboration-$width');
        await tapVisible(tester, find.text('Continuar'));
        await capture(tester, key, 'mission-composer-place-$width');
        await tapVisible(tester, find.text('Continuar'));
        expect(
          find.textContaining(
            'Entregar diez fotografías editadas en una semana.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('250.50 MXN por participante'),
          findsOneWidget,
        );
        await capture(tester, key, 'mission-composer-review-$width');
        await tapVisible(tester, find.text('Editar la idea'));
        expect(
          tester
              .widget<TextFormField>(field('Título de la misión'))
              .controller!
              .text,
          'Retrata la vida de nuestro mercado',
        );
        expect(repo.creations, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('draft resume retains a partial date and compensation cents', (
    tester,
  ) async {
    final repo = MissionRepositoryFake();
    final router = await openRoute(tester, repo, '/missions/new');
    await fill(tester, 'Título de la misión', 'Una misión que retomaremos');
    await fill(tester, 'Descripción', 'Transformemos el centro cultural.');
    await tapVisible(tester, find.text('Continuar'));
    await tapVisible(tester, find.text('Importe fijo'));
    await fill(tester, 'Importe por participante (MXN)', '250.50');
    await tapVisible(tester, find.text('Continuar'));
    await fill(tester, 'Lugar', 'Centro cultural');
    await _chooseFutureDate(tester);
    await tapVisible(tester, find.text('Guardar borrador'));
    final draft = repo.drafts.values.single;
    expect(draft.data['starts_at'], isNull);
    expect(draft.data['starts_date'], isNotNull);
    expect(draft.data['compensation_amount_cents'], 25050);
    router.go('/missions/drafts/${draft.id}/edit');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(field('Título de la misión'))
          .controller!
          .text,
      'Una misión que retomaremos',
    );
    await tapVisible(tester, find.text('Continuar'));
    expect(
      tester
          .widget<TextFormField>(field('Importe por participante (MXN)'))
          .controller!
          .text,
      '250.50',
    );
    await tapVisible(tester, find.text('Continuar'));
    expect(find.text('Seleccionar fecha'), findsNothing);
    expect(find.text('Seleccionar hora'), findsOneWidget);
    await tapVisible(tester, find.text('Continuar'));
    expect(find.text('Selecciona la fecha y la hora.'), findsOneWidget);
    expect(repo.creations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'close can save an incomplete idea or retain it after a failed save',
    (tester) async {
      final repo = MissionRepositoryFake()..failSave = true;
      await openRoute(tester, repo, '/missions/new');
      await fill(tester, 'Título de la misión', 'No perder mi idea');
      await tapVisible(tester, find.byTooltip('Cerrar'));
      await tester.tap(find.text('Guardar borrador').last);
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión. Inténtalo nuevamente.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(field('Título de la misión'))
            .controller!
            .text,
        'No perder mi idea',
      );
      repo.failSave = false;
      await tapVisible(tester, find.byTooltip('Cerrar'));
      await tester.tap(find.text('Guardar borrador').last);
      await tester.pumpAndSettle();
      expect(field('Título de la misión'), findsNothing);
      expect(repo.drafts.values.single.data['title'], 'No perder mi idea');
      expect(repo.creations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small mobile composer remains usable with enlarged text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await openRoute(tester, MissionRepositoryFake(), '/missions/new');
      await fill(tester, 'Título de la misión', 'Una idea accesible');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.text('Continuar')).dy, lessThan(520));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Completa este campo.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'publishing recovers a lost response without saving over a published draft',
    (tester) async {
      final repo = _LostPublishResponseRepository();
      await openRoute(tester, repo, '/missions/new');
      await fill(
        tester,
        'Título de la misión',
        'Una misión publicada una sola vez',
      );
      await fill(
        tester,
        'Descripción',
        'Retratemos la vida de nuestro barrio.',
      );
      await tapVisible(tester, find.text('Continuar'));
      await tapVisible(tester, find.text('Continuar'));
      await fill(tester, 'Lugar', 'Centro cultural');
      await _chooseFutureDate(tester);
      await tapVisible(tester, find.text('Seleccionar hora'));
      await tester.tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(Dialog).last),
          ).okButtonLabel,
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Continuar'));
      await tapVisible(tester, find.text('Publicar misión'));
      expect(
        find.text('Se perdió la respuesta. Inténtalo nuevamente.'),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('Publicar misión'));
      expect(find.text('Publicar misión'), findsNothing);
      expect(repo.creations, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edited retry explains which publication actually persisted', (
    tester,
  ) async {
    final repo = _LostPublishResponseRepository();
    const id = 'da534381-c948-4335-8b16-d2759c61c2ee';
    repo.drafts[id] = MissionDraft(
      id: id,
      updatedAt: DateTime.now(),
      data: {
        'title': 'Primera versión publicada',
        'body': 'Nuestra idea original.',
        'category': 'otros',
        'capacity': 5,
        'location': 'Centro cultural',
        'starts_at': DateTime.now()
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'compensation_type': 'negotiable',
      },
    );
    await openRoute(tester, repo, '/missions/drafts/$id/edit');
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, find.text('Continuar'));
    }
    await tapVisible(tester, find.text('Publicar misión'));
    await tapVisible(tester, find.text('Editar la idea'));
    await fill(tester, 'Título de la misión', 'Cambios posteriores a publicar');
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, find.text('Continuar'));
    }
    await tapVisible(tester, find.text('Publicar misión'));
    expect(
      find.text(
        'Tu misión ya fue publicada. Los cambios posteriores no se publicaron.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ver misión publicada'), findsOneWidget);
    expect(repo.creations, 1);
    expect(repo.saved!.title, 'Primera versión publicada');
    await tapVisible(tester, find.text('Ver misión publicada'));
    expect(find.text('Ver misión publicada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discard removes a draft even when its save response was lost', (
    tester,
  ) async {
    final repo = _LostSaveResponseRepository();
    await openRoute(tester, repo, '/missions/new');
    await fill(tester, 'Título de la misión', 'Idea que voy a descartar');
    await tapVisible(tester, find.text('Guardar borrador'));
    expect(repo.drafts.length, 1);
    await tapVisible(tester, find.byTooltip('Cerrar'));
    await tester.tap(find.text('Descartar cambios'));
    await tester.pumpAndSettle();
    expect(repo.drafts, isEmpty);
    expect(field('Título de la misión'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a removed published mission never reappears as an editable draft',
    (tester) async {
      final repo = MissionRepositoryFake();
      const id = 'da534381-c948-4335-8b16-d2759c61c2ee';
      repo.drafts[id] = MissionDraft(
        id: id,
        updatedAt: DateTime.now(),
        data: {'title': 'Ya publicada'},
        publishedAt: DateTime.now(),
      );
      await openRoute(tester, repo, '/missions/drafts/$id/edit');
      expect(find.text('Este borrador no está disponible.'), findsOneWidget);
      expect(field('Título de la misión'), findsNothing);
      expect(await repo.missionDrafts(), isEmpty);
      expect(repo.creations, 0);
    },
  );

  testWidgets('saving an incomplete draft never runs publication validation', (
    tester,
  ) async {
    final repo = MissionRepositoryFake();
    await openRoute(tester, repo, '/missions/new');
    await fill(tester, 'Título de la misión', 'Mi próxima idea');
    await tapVisible(tester, find.text('Guardar borrador'));
    expect(find.text('Completa este campo.'), findsNothing);
    expect(repo.drafts.values.single.data['title'], 'Mi próxima idea');
    expect(repo.drafts.values.single.data['starts_at'], isNull);
    expect(repo.drafts.values.single.data['compensation_type'], 'negotiable');
    expect(repo.creations, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('steps validate locally and back preserves entered values', (
    tester,
  ) async {
    await openRoute(tester, MissionRepositoryFake(), '/missions/new');
    expect(field('Lugar'), findsNothing);
    await tapVisible(tester, find.text('Continuar'));
    expect(find.text('Escribe al menos 3 caracteres.'), findsOneWidget);
    expect(field('Cupo'), findsNothing);
    await fill(tester, 'Título de la misión', 'El barrio en imágenes');
    await fill(tester, 'Descripción', 'Retratemos la vida de nuestro barrio.');
    await tapVisible(tester, find.text('Continuar'));
    expect(field('Cupo'), findsOneWidget);
    expect(field('Título de la misión'), findsNothing);
    await tapVisible(tester, find.text('Atrás'));
    expect(
      tester
          .widget<TextFormField>(field('Título de la misión'))
          .controller!
          .text,
      'El barrio en imágenes',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid collaboration requires a positive two-decimal amount', (
    tester,
  ) async {
    await openRoute(tester, MissionRepositoryFake(), '/missions/new');
    await fill(tester, 'Título de la misión', 'El barrio en imágenes');
    await fill(tester, 'Descripción', 'Retratemos la vida de nuestro barrio.');
    await tapVisible(tester, find.text('Continuar'));
    await tapVisible(tester, find.text('Importe fijo'));
    await fill(tester, 'Importe por participante (MXN)', '0');
    await tapVisible(tester, find.text('Continuar'));
    expect(field('Lugar'), findsNothing);
    expect(
      find.text('Introduce un importe positivo con hasta dos decimales.'),
      findsOneWidget,
    );
    await fill(tester, 'Importe por participante (MXN)', '250.50');
    await tapVisible(tester, find.text('Continuar'));
    expect(field('Lugar'), findsOneWidget);
    await tapVisible(tester, find.text('Atrás'));
    expect(
      tester
          .widget<TextFormField>(field('Importe por participante (MXN)'))
          .controller!
          .text,
      '250.50',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'locked edit explains restrictions and retains original schedule',
    (tester) async {
      final repo = MissionRepositoryFake()
        ..value = missionFixture(author: sampleProfile.id, locked: true);
      final original = repo.value.startsAt;
      await openRoute(tester, repo, '/missions/mission-1/edit');
      await fill(tester, 'Título de la misión', 'Título corregido');
      await tapVisible(tester, find.text('Continuar'));
      expect(find.textContaining('compensación quedan fijos'), findsOneWidget);
      await tapVisible(tester, find.text('Continuar'));
      expect(tester.widget<TextFormField>(field('Lugar')).enabled, isFalse);
      await tapVisible(tester, find.text('Continuar'));
      await tapVisible(tester, find.text('Guardar cambios'));
      expect(repo.saved!.startsAt, original);
      expect(repo.updates, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
