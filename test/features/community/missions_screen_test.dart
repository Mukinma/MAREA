import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';

Future<GoRouter> openRoute(
  WidgetTester tester,
  MissionRepositoryFake repo,
  String path, {
  GlobalKey? captureKey,
  UserType? userType,
  SocialRepository? socialRepository,
}) async {
  final profile = FakeProfileRepository()
    ..value = sampleProfile.copyWith(
      onboardingStatus: OnboardingStatus.skipped,
      userType: userType,
    );
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: profile,
    communityRepository: repo,
    socialRepository: socialRepository,
  );
  await session.initialize();
  final router = AppRouter.create(session)..go(path);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (_, child) => RepaintBoundary(key: captureKey, child: child!),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    router.dispose();
    session.dispose();
  });
  return router;
}

Finder field(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  ),
  matching: find.byType(TextFormField),
);
Future<void> fill(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), text);
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> validComposer(WidgetTester tester) async {
  await fill(tester, 'Título de la misión', 'Nueva misión publicada');
  await fill(
    tester,
    'Descripción',
    'Una colaboración para transformar el barrio.',
  );
  await tapVisible(tester, find.text('Continuar'));
  await tapVisible(tester, find.text('Continuar'));
  await fill(tester, 'Lugar', 'Centro cultural');
  FocusManager.instance.primaryFocus?.unfocus();
  await tapVisible(tester, find.text('Seleccionar fecha'));
  // The next month always provides a future date, independent of the test clock.
  await tester.tap(
    find.byTooltip(
      MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      ).nextMonthTooltip,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('15').last);
  await tester.tap(
    find.text(
      MaterialLocalizations.of(
        tester.element(find.byType(Dialog).last),
      ).okButtonLabel,
    ),
  );
  await tester.pumpAndSettle();
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
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['MAREA_SCREENSHOTS'] != '1') return;
  await tester.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final im = await b.toImage(pixelRatio: 1);
    final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
    await Directory('/tmp/marea-validation').create(recursive: true);
    await File(
      '/tmp/marea-validation/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    im.dispose();
  });
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
  testWidgets(
    'real creation route owns Scaffold, validates inline and focuses first error',
    (tester) async {
      await openRoute(tester, MissionRepositoryFake(), '/missions/new');
      expect(
        find.ancestor(
          of: find.byType(MissionComposerScreen),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      await tapVisible(tester, find.text('Continuar'));
      expect(find.text('Escribe al menos 3 caracteres.'), findsOneWidget);
      expect(field('Lugar'), findsNothing);
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: field('Título de la misión'),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'publishing real route opens new detail and refreshing list sees it',
    (tester) async {
      final repo = MissionRepositoryFake();
      await openRoute(tester, repo, '/missions');
      await tapVisible(tester, find.text('Crear misión'));
      await validComposer(tester);
      await tapVisible(tester, find.text('Publicar misión'));
      expect(find.byType(MissionDetailScreen), findsOneWidget);
      expect(find.text('Nueva misión publicada'), findsOneWidget);
      expect(repo.creations, 1);
      await tester.tap(find.byTooltip('Volver a misiones'));
      await tester.pumpAndSettle();
      expect(find.text('Nueva misión publicada'), findsOneWidget);
      expect(repo.lastScope, 'discover');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'network failure keeps form and double submission sends only once',
    (tester) async {
      final repo = MissionRepositoryFake()..saveGate = Completer<void>();
      await openRoute(tester, repo, '/missions/new');
      await validComposer(tester);
      await tester.tap(find.text('Publicar misión'));
      await tester.pump();
      expect(repo.creations, 1);
      expect(find.text('Guardando…'), findsOneWidget);
      // A repeated tap while pending cannot publish a second mission.
      await tester.tap(find.text('Guardando…'));
      await tester.pump();
      expect(repo.creations, 1);
      repo.failSave = true;
      repo.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión. Inténtalo nuevamente.'), findsOneWidget);
      expect(find.text('Nueva misión publicada'), findsWidgets);
      repo.failSave = false;
      repo.saveGate = null;
      await tapVisible(tester, find.text('Publicar misión'));
      expect(find.byType(MissionDetailScreen), findsOneWidget);
      expect(repo.creations, 2);
    },
  );
  testWidgets('dirty cancel confirms and can continue editing', (tester) async {
    await openRoute(tester, MissionRepositoryFake(), '/missions/new');
    await fill(tester, 'Título de la misión', 'No perder esta idea');
    await tapVisible(tester, find.byTooltip('Cerrar'));
    expect(find.text('¿Qué hacemos con tu idea?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(field('Título de la misión'))
          .controller!
          .text,
      'No perder esta idea',
    );
  });
  testWidgets(
    'locked edit preserves exact timestamp and disables original conditions',
    (tester) async {
      final repo = MissionRepositoryFake()
        ..value = missionFixture(author: sampleProfile.id, locked: true);
      final original = repo.value.startsAt;
      await openRoute(tester, repo, '/missions/mission-1/edit');
      await fill(tester, 'Título de la misión', 'Título corregido');
      await tapVisible(tester, find.text('Continuar'));
      await tapVisible(tester, find.text('Continuar'));
      expect(tester.widget<TextFormField>(field('Lugar')).enabled, isFalse);
      await tapVisible(tester, find.text('Continuar'));
      await tapVisible(tester, find.text('Guardar cambios'));
      expect(repo.saved!.startsAt, original);
      expect(repo.updates, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('closed owner mission can accept pending participant', (
    tester,
  ) async {
    final repo = MissionRepositoryFake()
      ..value = missionFixture(author: sampleProfile.id, status: 'closed')
      ..requests = [application()];
    await openRoute(tester, repo, '/missions/mission-1');
    await tapVisible(tester, find.text('Gestionar misión'));
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Confirmar selección (1)'));
    await tapVisible(tester, find.text('Confirmar participantes'));
    expect(repo.reviewed, 'accepted');
    await tapVisible(tester, find.text('Aceptadas 1'));
    expect(find.text('Aceptada'), findsOneWidget);
  });
  testWidgets('withdraw retains history and permits reapplying', (
    tester,
  ) async {
    final repo = MissionRepositoryFake()
      ..requests = [
        application(applicant: sampleProfile.id, status: 'accepted'),
      ];
    await openRoute(tester, repo, '/missions/mission-1');
    await tapVisible(tester, find.text('Retirar postulación'));
    expect(repo.requests.single.status, 'withdrawn');
    expect(find.text('Tu postulación: retirada.'), findsOneWidget);
    expect(find.text('Quiero participar'), findsOneWidget);
  });
  testWidgets(
    'unavailable applications stay in history without exposing others',
    (tester) async {
      final repo = MissionRepositoryFake()
        ..unavailable = true
        ..requests = [
          application(),
          application(applicant: sampleProfile.id, status: 'withdrawn'),
        ];
      await openRoute(tester, repo, '/missions');
      await tapVisible(tester, find.text('Mis candidaturas'));
      expect(find.text('Misión no disponible'), findsOneWidget);
      expect(find.textContaining('Postulación retirada'), findsOneWidget);
      expect(find.textContaining('Postulación pendiente'), findsNothing);
    },
  );
  testWidgets(
    'discover sends search to server and own list separates history',
    (tester) async {
      final repo = MissionRepositoryFake();
      await openRoute(tester, repo, '/missions');
      await tester.enterText(find.byType(TextField).first, 'mural');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repo.lastQuery, 'mural');
      await tapVisible(tester, find.text('Mis misiones'));
      expect(repo.lastScope, 'active');
      await tapVisible(tester, find.text('Historial'));
      expect(repo.lastScope, 'history');
    },
  );
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(834, 1000),
    const Size(1440, 900),
  ]) {
    for (final path in ['/missions', '/missions/new', '/missions/mission-1']) {
      testWidgets('integrated $path at ${size.width}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final repo = MissionRepositoryFake()
          ..value = missionFixture(author: sampleProfile.id)
          ..requests = [application()];
        await openRoute(tester, repo, path, captureKey: key);
        await capture(
          tester,
          key,
          'integrated-${path.split('/').last}-${size.width.toInt()}',
        );
        if (path.endsWith('new')) {
          await fill(tester, 'Título de la misión', 'Pintemos el barrio');
          await fill(
            tester,
            'Descripción',
            'Buscamos artistas y vecinos para compartir una mañana de creatividad.',
          );
          if (size.width < 960) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(find.text('Continuar').hitTestable(), findsOneWidget);
            tester.view.resetViewInsets();
          }
          FocusManager.instance.primaryFocus?.unfocus();
          await validComposer(tester);
          expect(find.text('Nueva misión publicada'), findsOneWidget);
          await capture(
            tester,
            key,
            'integrated-preview-${size.width.toInt()}',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
