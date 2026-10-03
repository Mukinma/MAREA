import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/mission_application_screen.dart';
import 'package:marea/features/community/presentation/mission_management_screen.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/showcase_repository_fake.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'missions_screen_test.dart' as captures;

class ParticipationRepository extends MissionRepositoryFake {
  final operationIds = <String>[];
  List<String>? selected;
  bool failSubmission = false,
      persistThenFail = false,
      preserveCommittedPayload = false,
      failRecoveryLookup = false;
  @override
  Future<String> submitApplication(
    String id,
    MissionApplicationInput input,
  ) async {
    operationIds.add(input.operationId);
    if (preserveCommittedPayload && requests.isNotEmpty) {
      throw const AppFailure('Esta operación ya envió otros datos.');
    }
    if (failSubmission) {
      throw const AppFailure('Sin conexión. Inténtalo nuevamente.');
    }
    requests = [
      MissionApplication(
        id: 'sent-id',
        missionId: id,
        applicantId: sampleProfile.id,
        message: input.message,
        status: 'pending',
        createdAt: DateTime.now(),
        availabilityConfirmed: input.availabilityConfirmed,
        evidence: input.evidence,
      ),
    ];
    if (persistThenFail) {
      throw const AppFailure('Se perdió la respuesta.');
    }
    return 'sent-id';
  }

  @override
  Future<List<MissionApplication>> applications({String? missionId}) async {
    if (failRecoveryLookup && requests.isNotEmpty) {
      throw const AppFailure('No pudimos recuperar la candidatura.');
    }
    return super.applications(missionId: missionId);
  }

  @override
  Future<Set<String>> missionFinalists(String id) async => finalists;
  @override
  Future<void> setMissionFinalist(
    String id,
    String applicationId,
    bool finalist,
  ) async {
    finalist ? finalists.add(applicationId) : finalists.remove(applicationId);
  }

  @override
  Future<void> confirmMissionSelection(String id, List<String> ids) async {
    selected = ids;
  }
}

Future<GoRouter> open(
  WidgetTester tester,
  ParticipationRepository repo,
  String path, {
  ShowcaseRepositoryFake? showcase,
  UserType? viewerType,
  double textScale = 1,
  GlobalKey? captureKey,
}) async {
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        userType: viewerType ?? sampleProfile.userType,
      ),
    showcaseRepository: showcase,
    communityRepository: repo,
  );
  await session.initialize();
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(
        path: '/apply',
        builder: (_, _) => MissionApplicationScreen(
          controller: session,
          missionId: 'mission-1',
        ),
      ),
      GoRoute(
        path: '/manage',
        builder: (_, _) => MissionManagementScreen(
          controller: session,
          missionId: 'mission-1',
        ),
      ),
      GoRoute(
        path: '/missions/:id/sent',
        builder: (_, state) => MissionApplicationSentScreen(
          controller: session,
          missionId: state.pathParameters['id']!,
          applicationId: state.uri.queryParameters['application'],
        ),
      ),
      GoRoute(
        path: '/missions',
        builder: (_, _) => const Scaffold(body: Text('Explorar destino')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(key: captureKey, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    router.dispose();
    session.dispose();
  });
  return router;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
  testWidgets(
    'candidature blocks missing message and availability and preserves retry identity',
    (tester) async {
      final repo = ParticipationRepository()..failSubmission = true;
      await open(tester, repo, '/apply');
      await tap(tester, find.text('Continuar'));
      await tap(tester, find.text('Revisar candidatura'));
      expect(find.text('Cuéntanos por qué encajas.'), findsOneWidget);
      expect(repo.operationIds, isEmpty);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Puedo compartir mi experiencia pintando murales.',
      );
      await tap(tester, find.byType(CheckboxListTile));
      await tap(tester, find.text('Revisar candidatura'));
      await tap(tester, find.text('Atrás'));
      expect(
        find.text('Puedo compartir mi experiencia pintando murales.'),
        findsOneWidget,
      );
      await tap(tester, find.text('Revisar candidatura'));
      await tap(tester, find.text('Enviar candidatura'));
      expect(find.text('Sin conexión. Inténtalo nuevamente.'), findsOneWidget);
      repo.failSubmission = false;
      await tap(tester, find.text('Enviar candidatura'));
      expect(repo.operationIds.length, 2);
      expect(repo.operationIds.first, repo.operationIds.last);
      expect(find.byType(MissionApplicationSentScreen), findsOneWidget);
      expect(
        find.text('¡Tu candidatura ya está en movimiento!'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'failed submission refreshes closure and preserves the candidature for reopening',
    (tester) async {
      final repo = ParticipationRepository()..failSubmission = true;
      await open(tester, repo, '/apply');
      await tap(tester, find.text('Continuar'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Mi propuesta se conserva.',
      );
      await tap(tester, find.textContaining('Confirmo mi disponibilidad'));
      await tap(tester, find.text('Revisar candidatura'));
      repo.value = missionFixture(status: 'closed');
      await tap(tester, find.text('Enviar candidatura'));
      expect(find.text('Enviar candidatura'), findsNothing);
      expect(
        find.text('El organizador cerró la convocatoria.'),
        findsOneWidget,
      );
      repo.value = missionFixture();
      await tap(tester, find.text('Reintentar'));
      expect(find.text('Mi propuesta se conserva.'), findsOneWidget);
      expect(find.text('Enviar candidatura'), findsOneWidget);
    },
  );

  testWidgets('recovers own persisted candidature after response is lost', (
    tester,
  ) async {
    final repo = ParticipationRepository()..persistThenFail = true;
    await open(tester, repo, '/apply');
    await tap(tester, find.text('Continuar'));
    await tester.enterText(
      find.byType(TextFormField).first,
      'Esta es mi propuesta para el barrio.',
    );
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, find.text('Revisar candidatura'));
    await tap(tester, find.text('Enviar candidatura'));
    expect(find.byType(MissionApplicationSentScreen), findsOneWidget);
    expect(repo.operationIds.length, 1);
  });
  testWidgets(
    'recovery discloses persisted original when edited retry conflicts',
    (tester) async {
      final repo = ParticipationRepository()
        ..persistThenFail = true
        ..preserveCommittedPayload = true
        ..failRecoveryLookup = true;
      await open(tester, repo, '/apply');
      await tap(tester, find.text('Continuar'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'La propuesta original que se guardó.',
      );
      await tap(tester, find.byType(CheckboxListTile));
      await tap(tester, find.text('Revisar candidatura'));
      await tap(tester, find.text('Enviar candidatura'));
      expect(find.byType(MissionApplicationSentScreen), findsNothing);
      await tap(tester, find.text('Atrás'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Estos cambios todavía no se enviaron.',
      );
      await tap(tester, find.text('Revisar candidatura'));
      repo.failRecoveryLookup = false;
      await tap(tester, find.text('Enviar candidatura'));
      expect(
        find.text(
          'Tu candidatura ya fue enviada. Los cambios posteriores no se enviaron.',
        ),
        findsOneWidget,
      );
      expect(find.text('La propuesta original que se guardó.'), findsOneWidget);
      expect(find.text('Estos cambios todavía no se enviaron.'), findsNothing);
      expect(find.text('Enviar candidatura'), findsNothing);
      expect(find.text('Ver mis candidaturas'), findsOneWidget);
    },
  );
  testWidgets('sent screen refuses application owned by another user', (
    tester,
  ) async {
    final repo = ParticipationRepository()..requests = [application()];
    await open(
      tester,
      repo,
      '/missions/mission-1/sent?application=application-1',
    );
    expect(find.text('¡Tu candidatura ya está en movimiento!'), findsNothing);
    expect(
      find.text('No encontramos una candidatura tuya para esta misión.'),
      findsOneWidget,
    );
  });
  testWidgets('management refuses non organizer', (tester) async {
    await open(tester, ParticipationRepository(), '/manage');
    expect(
      find.text('Solo el organizador puede gestionar esta misión.'),
      findsOneWidget,
    );
    expect(find.text('Mariana Torres'), findsNothing);
  });
  testWidgets(
    'selection remains provisional until confirmed and finalists stay pending',
    (tester) async {
      final repo = ParticipationRepository()
        ..value = missionFixture(author: sampleProfile.id)
        ..requests = [application()];
      await open(tester, repo, '/manage');
      await tap(tester, find.byTooltip('Marcar finalista'));
      expect(repo.requests.single.status, 'pending');
      await tap(tester, find.byType(Checkbox));
      await tap(tester, find.text('Confirmar selección (1)'));
      expect(repo.selected, isNull);
      expect(find.text('Confirmar participantes'), findsOneWidget);
      await tap(tester, find.text('Confirmar participantes'));
      expect(repo.selected, ['application-1']);
    },
  );
  for (final type in UserType.values) {
    testWidgets(
      'every profile can submit with optional HTTPS evidence: ${type.name}',
      (tester) async {
        final repo = ParticipationRepository();
        await open(tester, repo, '/apply', viewerType: type);
        await tap(tester, find.text('Continuar'));
        await tap(tester, find.text('Añadir enlace · 0/3'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título de la muestra'),
          'Mi proyecto',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enlace HTTPS'),
          'http://example.com/work',
        );
        await tap(tester, find.text('Añadir muestra'));
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enlace HTTPS'),
          'https://example.com/work',
        );
        await tap(tester, find.text('Añadir muestra'));
        expect(find.byType(AlertDialog), findsNothing);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Tengo una propuesta para colaborar.',
        );
        await tap(tester, find.byType(CheckboxListTile));
        await tap(tester, find.text('Revisar candidatura'));
        await tap(tester, find.text('Enviar candidatura'));
        expect(
          repo.requests.single.evidence.single.url,
          'https://example.com/work',
        );
        expect(repo.requests.single.availabilityConfirmed, isTrue);
      },
    );
  }
  testWidgets('additional published work is reachable after the first page', (
    tester,
  ) async {
    final showcase = ShowcaseRepositoryFake();
    for (var i = 0; i < 31; i++) {
      showcase.records['work-$i'] = ShowcaseItem(
        id: 'work-$i',
        ownerId: sampleProfile.id,
        kind: ShowcaseKind.service,
        title: 'Trabajo $i',
        body: 'Muestra',
        category: 'arte',
        status: ShowcaseStatus.published,
        createdAt: DateTime.now(),
      );
    }
    await open(tester, ParticipationRepository(), '/apply', showcase: showcase);
    await tap(tester, find.text('Continuar'));
    await tap(tester, find.text('Cargar más fichas'));
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Trabajo 30'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Trabajo 30'), findsOneWidget);
  });
  testWidgets(
    'only own visible published fiches can be selected and combined with links up to three',
    (tester) async {
      final showcase = ShowcaseRepositoryFake();
      for (final entry in [
        ('published', ShowcaseStatus.published, false, sampleProfile.id),
        ('draft', ShowcaseStatus.draft, false, sampleProfile.id),
        ('hidden', ShowcaseStatus.published, true, sampleProfile.id),
        ('foreign', ShowcaseStatus.published, false, 'other'),
      ]) {
        showcase.records[entry.$1] = ShowcaseItem(
          id: entry.$1,
          ownerId: entry.$4,
          kind: ShowcaseKind.service,
          title: '${entry.$1} ficha',
          body: 'Trabajo propio',
          category: 'arte',
          status: entry.$2,
          hidden: entry.$3,
          createdAt: DateTime.now(),
        );
      }
      final repo = ParticipationRepository();
      await open(tester, repo, '/apply', showcase: showcase);
      await tap(tester, find.text('Continuar'));
      expect(find.text('draft ficha'), findsNothing);
      expect(find.text('hidden ficha'), findsNothing);
      expect(find.text('foreign ficha'), findsNothing);
      await tap(tester, find.text('published ficha'));
      for (final suffix in ['a', 'b']) {
        await tap(
          tester,
          find.text('Añadir enlace · ${suffix == 'a' ? 1 : 2}/3'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título de la muestra'),
          'Muestra $suffix',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enlace HTTPS'),
          'https://example.com/$suffix',
        );
        await tap(tester, find.text('Añadir muestra'));
      }
      final addButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Añadir enlace · 3/3'),
      );
      expect(addButton.onPressed, isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Puedo aportar este trabajo propio.',
      );
      await tap(tester, find.byType(CheckboxListTile));
      await tap(tester, find.text('Revisar candidatura'));
      await tap(tester, find.text('Enviar candidatura'));
      expect(repo.requests.single.evidence.map((e) => e.showcaseId ?? e.url), [
        'published',
        'https://example.com/a',
        'https://example.com/b',
      ]);
    },
  );
  testWidgets(
    'removed evidence remains unavailable and terminal management is read only',
    (tester) async {
      final repo = ParticipationRepository()
        ..value = missionFixture(author: sampleProfile.id, status: 'completed')
        ..requests = [
          MissionApplication(
            id: 'application-1',
            missionId: 'mission-1',
            applicantId: 'applicant',
            message: 'Mi propuesta',
            status: 'accepted',
            evidence: const [
              MissionEvidence(title: 'Trabajo oculto', showcaseId: 'gone'),
            ],
            createdAt: DateTime.now(),
          ),
        ];
      await open(tester, repo, '/manage', showcase: ShowcaseRepositoryFake());
      await tap(tester, find.text('Aceptadas 1'));
      await tester.scrollUntilVisible(
        find.text('Muestra no disponible'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Muestra no disponible'), findsOneWidget);
      expect(find.byTooltip('Opciones de misión'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.textContaining('Confirmar selección'), findsNothing);
    },
  );
  testWidgets(
    'participation captures application, review, sent and management at mobile size',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final repo = ParticipationRepository();
      final router = await open(tester, repo, '/apply', captureKey: key);
      await tap(tester, find.text('Continuar'));
      await captures.capture(tester, key, 'mission-application-mobile');
      await tester.enterText(
        find.byType(TextFormField).first,
        'He trabajado con iniciativas de barrio y me gustaría aportar una nueva mirada.',
      );
      await tap(tester, find.byType(CheckboxListTile));
      await tap(tester, find.text('Revisar candidatura'));
      await captures.capture(tester, key, 'mission-application-review-mobile');
      await tap(tester, find.text('Enviar candidatura'));
      await captures.capture(tester, key, 'mission-application-sent-mobile');
      repo.value = missionFixture(author: sampleProfile.id);
      router.go('/manage');
      await tester.pumpAndSettle();
      await captures.capture(tester, key, 'mission-management-mobile');
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [360.0, 390.0, 768.0, 1440.0]) {
    testWidgets('participation pages fit width $width with scaled text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, ParticipationRepository(), '/apply', textScale: 1.4);
      await tap(tester, find.text('Continuar'));
      expect(tester.takeException(), isNull);
    });
  }
}
