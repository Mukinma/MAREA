import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_identity.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/features/profile/presentation/wave_color_editor.dart';
import 'package:marea/shared/widgets/profile_image.dart';

import '../../support/fakes.dart';

void main() {
  test('colors round-trip for owners and visitors without touching media', () {
    final profile = sampleProfile.copyWith(
      waveColors: [0xFF123456, 0xFFABCDEF],
    );
    final loaded = Profile.fromJson(profile.toJson());
    final visitor = CommunityProfile.fromJson(profile.toJson());
    expect(loaded.waveColors, profile.waveColors);
    expect(visitor.waveColors, profile.waveColors);
    expect(loaded.avatarPath, sampleProfile.avatarPath);
    expect(loaded.coverPath, sampleProfile.coverPath);
    expect(loaded.updateInput.toJson()['wave_colors'], profile.waveColors);
    expect(sampleProfile.updateInput.toJson(), isNot(contains('wave_colors')));
    expect(readWaveColors([1]), isNull);
    expect(readWaveColors(['bad', null]), isNull);
    expect(
      () => profile.copyWith(waveColors: [1]).toJson(),
      throwsArgumentError,
    );
    expect(wavePalettes.length, 20);
  });

  testWidgets(
    'manual colors, separate layers, presets and cancel are live drafts',
    (tester) async {
      List<int>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<List<int>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const SizedBox(
                      height: 560,
                      child: WaveColorEditor(
                        colors: ProfileWaves.defaultColors,
                        cover: ColoredBox(color: Colors.grey),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      final upper = Colors.pink.shade300.toARGB32();
      final lower = Colors.teal.shade800.toARGB32();
      final upperSwatch = find.byKey(ValueKey('wave-swatch-$upper'));
      await tester.ensureVisible(upperSwatch);
      await tester.tap(upperSwatch);
      await tester.pump();
      ProfileWaves preview() => tester.widget<ProfileWaves>(
        find.descendant(
          of: find.byKey(const Key('wave-live-preview')),
          matching: find.byType(ProfileWaves),
        ),
      );
      expect(preview().colors, [upper, ProfileWaves.defaultColors[1]]);
      expect(
        find.descendant(
          of: upperSwatch,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      final previousPreview = preview();
      await tester.ensureVisible(find.text('Color de la ola inferior'));
      await tester.tap(find.text('Color de la ola inferior'));
      final lowerSwatch = find.byKey(ValueKey('wave-swatch-$lower'));
      await tester.ensureVisible(lowerSwatch);
      await tester.tap(lowerSwatch);
      await tester.pump();
      expect(preview().colors, [upper, lower]);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Capa 1'), findsNothing);
      expect(previousPreview.colors[1], ProfileWaves.defaultColors[1]);
      expect(
        ProfileWavesPainter(
          colors: preview().colors,
          surface: Colors.white,
        ).shouldRepaint(
          ProfileWavesPainter(
            colors: previousPreview.colors,
            surface: Colors.white,
          ),
        ),
        isTrue,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(preview().colors, ProfileWaves.defaultColors);
      await tester.ensureVisible(find.text('Negro y dorado'));
      await tester.tap(find.text('Negro y dorado'));
      await tester.pump();
      expect(preview().colors, wavePalettes['Negro y dorado']);
      await tester.ensureVisible(
        find.text('Restablecer colores predeterminados'),
      );
      await tester.tap(find.text('Restablecer colores predeterminados'));
      await tester.pump();
      expect(preview().colors, ProfileWaves.defaultColors);
      await tester.tap(find.text('Aplicar colores'));
      await tester.pumpAndSettle();
      expect(result, ProfileWaves.defaultColors);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'more colors previews any shade and cancellation restores the current wave',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaveColorEditor(
              colors: ProfileWaves.defaultColors,
              cover: const ColoredBox(color: Colors.grey),
            ),
          ),
        ),
      );
      ProfileWaves preview() => tester.widget<ProfileWaves>(
        find.descendant(
          of: find.byKey(const Key('wave-live-preview')),
          matching: find.byType(ProfileWaves),
        ),
      );
      Future<void> openMoreColors() async {
        await tester.ensureVisible(find.text('Más colores'));
        await tester.tap(find.text('Más colores'));
        await tester.pumpAndSettle();
      }

      Future<void> chooseShade() async {
        final field = find.byKey(const Key('wave-color-field'));
        await tester.ensureVisible(field);
        var rect = tester.getRect(field);
        await tester.tapAt(
          Offset(rect.left + rect.width * .23, rect.top + rect.height * .45),
        );
        await tester.pump();
        final lightness = find.byKey(const Key('wave-color-lightness'));
        await tester.ensureVisible(lightness);
        rect = tester.getRect(lightness);
        await tester.tapAt(
          Offset(rect.left + rect.width * .68, rect.center.dy),
        );
        await tester.pump();
      }

      await openMoreColors();
      await chooseShade();
      expect(preview().colors[0], isNot(ProfileWaves.defaultColors[0]));
      expect(preview().colors[1], ProfileWaves.defaultColors[1]);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar').last);
      await tester.pumpAndSettle();
      expect(preview().colors, ProfileWaves.defaultColors);
      await openMoreColors();
      await chooseShade();
      final chosen = List<int>.of(preview().colors);
      await tester.tap(find.text('Usar color'));
      await tester.pumpAndSettle();
      expect(preview().colors, chosen);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('color palette and dialog fit small screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaveColorEditor(
            colors: const [0xFF123456, 0xFFABCDEF],
            cover: const ColoredBox(color: Colors.grey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Más colores'));
    await tester.tap(find.text('Más colores'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Usar color'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'existing editor saves wave draft through the profile repository',
    (tester) async {
      final repository = FakeProfileRepository();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: repository,
        legalRepository: FakeLegalRepository(),
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      final before = repository.value;
      final router = GoRouter(
        initialLocation: '/profile/edit',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('Perfil guardado')),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (_, _) => EditProfileScreen(controller: controller),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Personalizar olitas'));
      await tester.tap(find.text('Personalizar olitas'));
      await tester.pumpAndSettle();
      final color = Colors.pink.shade300.toARGB32();
      final swatch = find.byKey(ValueKey('wave-swatch-$color'));
      await tester.ensureVisible(swatch);
      await tester.tap(swatch);
      await tester.tap(find.text('Aplicar colores'));
      await tester.pumpAndSettle();
      expect(repository.value.waveColors, isNull);
      await tester.tap(find.byKey(const Key('edit-save-button')));
      await tester.pumpAndSettle();
      expect(repository.value.waveColors, [
        color,
        ProfileWaves.defaultColors[1],
      ]);
      expect(repository.value.coverPath, before.coverPath);
      expect(repository.value.fullName, before.fullName);
      expect(repository.value.bio, before.bio);
      expect(repository.value.interests, before.interests);
      await tester.pump(const Duration(seconds: 3));
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Personalizar olitas'));
      await tester.tap(find.text('Personalizar olitas'));
      await tester.pumpAndSettle();
      final preview = tester.widget<ProfileWaves>(
        find.descendant(
          of: find.byKey(const Key('wave-live-preview')),
          matching: find.byType(ProfileWaves),
        ),
      );
      expect(preview.colors[0], color);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'public identity overlays saved colors on independent cover image',
    (tester) async {
      final controller = await authenticatedController();
      addTearDown(controller.dispose);
      final profile = CommunityProfile.fromJson(
        sampleProfile.copyWith(waveColors: [0xFF123456, 0xFFABCDEF]).toJson(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileIdentity(
                profile: profile,
                controller: controller,
                wide: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileWaves>(find.byType(ProfileWaves)).colors,
        profile.waveColors,
      );
      expect(find.byType(ProfileImage), findsNWidgets(2));
      expect(find.text(sampleProfile.fullName), findsOneWidget);
      expect(find.text(sampleProfile.bio!), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
