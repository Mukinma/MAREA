import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';

class _Repo implements CommunityRepository {
  final values = <CommunityPost>[];
  final saved = <String>{};
  PostInput? published;
  @override
  Future<void> savePost(PostInput input, {String? id}) async {
    published = input;
    values.add(
      CommunityPost(
        id: 'post-1',
        authorId: sampleProfile.id,
        kind: input.kind,
        title: input.title,
        body: input.body,
        category: input.category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        price: input.price,
      ),
    );
  }

  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async => values.where((p) => !savedOnly || saved.contains(p.id)).toList();
  @override
  Future<Set<String>> savedPostIds() async => {...saved};
  @override
  Future<void> setSaved(String postId, bool value) async {
    if (value) {
      saved.add(postId);
    } else {
      saved.remove(postId);
    }
  }

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: sampleProfile.id,
      fullName: sampleProfile.fullName,
      username: sampleProfile.username,
      userType: UserType.entrepreneur,
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
  });
  for (final size in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('community navigation fits ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      await repo.savePost(
        const PostInput(
          kind: PostKind.product,
          title: 'Diseño hecho en Manzanillo',
          body:
              'Una colección de piezas creadas en nuestro taller. Conoce el proceso y colabora con nosotros.',
          category: 'moda',
          price: 250,
        ),
      );
      final session = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository()
          ..value = sampleProfile.copyWith(
            userType: UserType.entrepreneur,
            onboardingStatus: OnboardingStatus.skipped,
          ),
        communityRepository: repo,
      );
      await session.initialize();
      final router = AppRouter.create(session);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final path in ['/home', '/explore', '/create']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (Platform.environment['MAREA_SCREENSHOTS'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('/tmp/marea-validation').create(recursive: true);
            await File(
              '/tmp/marea-validation/${path.substring(1)}-${size.width.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      session.dispose();
    });
  }

  testWidgets('entrepreneur publishes a product and sees it in the feed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final profileRepo = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        userType: UserType.entrepreneur,
        onboardingStatus: OnboardingStatus.skipped,
      );
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: profileRepo,
      communityRepository: repo,
    );
    await session.initialize();
    final router = AppRouter.create(session);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    router.go('/create');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Camisa hecha en Manzanillo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Describe tu producto'),
      'Diseño local en algodón. Disponible por encargo.',
    );
    final price = find.widgetWithText(
      TextFormField,
      'Precio en MXN (opcional)',
    );
    await tester.ensureVisible(price);
    await tester.enterText(price, '250.50');
    final publish = find.widgetWithText(FilledButton, 'Publicar');
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    expect(repo.published?.kind, PostKind.product);
    expect(repo.published?.price, 250.5);
    expect(find.text('Camisa hecha en Manzanillo'), findsOneWidget);
    expect(find.text('\$250.50 MXN'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });

  testWidgets('non-admin cannot access moderation from a direct route', (
    tester,
  ) async {
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository()
        ..value = sampleProfile.copyWith(
          onboardingStatus: OnboardingStatus.skipped,
        ),
      communityRepository: _Repo(),
    );
    await session.initialize();
    final router = AppRouter.create(session);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    router.go('/moderation');
    await tester.pumpAndSettle();
    expect(
      find.text('Esta sección está reservada para administradores.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });
}
