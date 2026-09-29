import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/community/presentation/moderation_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _Repository implements CommunityRepository {
  final postValue = CommunityPost(
    id: 'post-1',
    authorId: sampleProfile.id,
    kind: PostKind.product,
    title: 'Pieza original',
    body: 'Hecha a mano en nuestro taller.',
    category: 'arte',
    location: 'Taller del centro',
    price: 250,
    imagePath: 'user-1/original.png',
    createdAt: DateTime.utc(2030),
    updatedAt: DateTime.utc(2030),
  );
  int postRequests = 0;
  bool saved = true;
  bool failSave = false;
  bool hidden = false;
  int reportCount = 1;
  final reportOffsets = <int>[];
  final actions = <String>[];
  final imagesRequested = <String>[];
  PostInput? input;
  @override
  Future<CommunityPost?> post(String id) async => CommunityPost(
    id: postValue.id,
    authorId: postValue.authorId,
    kind: postValue.kind,
    title: postValue.title,
    body: postValue.body,
    category: postValue.category,
    location: postValue.location,
    price: postValue.price,
    imagePath: postValue.imagePath,
    createdAt: postValue.createdAt,
    updatedAt: postValue.updatedAt,
    hidden: hidden,
  );
  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async {
    postRequests++;
    return savedOnly && !saved ? [] : [postValue];
  }

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [];
  @override
  Future<Set<String>> savedPostIds() async => saved ? {'post-1'} : {};
  @override
  Future<void> setSaved(String postId, bool value) async {
    saved = value;
  }

  @override
  Future<String> imageUrl(String path) async {
    imagesRequested.add(path);
    throw const AppFailure('Imagen temporalmente no disponible.');
  }

  @override
  Future<void> savePost(PostInput value, {String? id}) async {
    actions.add('save');
    if (failSave) throw const AppFailure('No se pudo guardar.');
    input = value;
  }

  @override
  Future<void> removeImage(String path) async {
    actions.add('remove:$path');
  }

  @override
  Future<List<ContentReport>> reports({int offset = 0}) async {
    reportOffsets.add(offset);
    return List.generate(
      reportCount,
      (i) => ContentReport(
        id: 'r$i',
        reporterId: 'reporter',
        reason: 'Revisar esta imagen',
        state: hidden ? 'resolved' : 'open',
        createdAt: DateTime.utc(2030),
        postId: 'post-1',
      ),
    ).skip(offset).take(30).toList();
  }

  @override
  Future<void> moderate(
    String id, {
    required bool mission,
    required bool hide,
  }) async {
    hidden = hide;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppSessionController> _session(
  _Repository repo, {
  bool admin = false,
}) async {
  final profile = FakeProfileRepository();
  if (admin) {
    profile.value = Profile.fromJson({
      ...sampleProfile.toJson(),
      'role': 'admin',
    });
  }
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: profile,
    communityRepository: repo,
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('hiding the feed heading preserves accessible refresh', (
    tester,
  ) async {
    final repo = _Repository();
    final session = await _session(repo);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: PostsFeed(controller: session, showHeading: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.postRequests, 1);
    final refresh = find.byTooltip('Actualizar publicaciones');
    expect(refresh.hitTestable(), findsOneWidget);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(repo.postRequests, 2);
  });
  testWidgets('removing a saved post removes it from saved-only feed', (
    tester,
  ) async {
    final repo = _Repository();
    final session = await _session(repo);
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: PostsFeed(controller: session, savedOnly: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bookmark = find.byTooltip('Acciones');
    await tester.ensureVisible(bookmark);
    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar guardado'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(repo.saved, isFalse);
    expect(find.text('Pieza original'), findsNothing);
    expect(
      find.text(
        'Guarda las publicaciones que te interesen para encontrarlas aquí.',
      ),
      findsOneWidget,
    );
    session.dispose();
  });

  for (final failSave in [false, true]) {
    testWidgets(
      'image removal cleans original only after successful save ($failSave)',
      (tester) async {
        final repo = _Repository()..failSave = failSave;
        final session = await _session(repo);
        final router = GoRouter(
          initialLocation: '/edit',
          routes: [
            GoRoute(
              path: '/edit',
              builder: (_, _) => Scaffold(
                body: PostComposerScreen(controller: session, postId: 'post-1'),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Inicio')),
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        final remove = find.text('Quitar fotografía');
        await tester.ensureVisible(remove);
        await tester.pumpAndSettle();
        await tester.tap(remove);
        await tester.pumpAndSettle();
        final save = find.text('Guardar cambios');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          repo.actions,
          failSave ? ['save'] : ['save', 'remove:user-1/original.png'],
        );
        if (!failSave) expect(repo.input!.imagePath, isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        session.dispose();
      },
    );
  }

  testWidgets('moderation loads reported image and shows commercial context', (
    tester,
  ) async {
    final repo = _Repository();
    final session = await _session(repo, admin: true);
    await tester.pumpWidget(testApp(ModerationScreen(controller: session)));
    await tester.pumpAndSettle();
    expect(repo.imagesRequested, contains('user-1/original.png'));
    expect(find.textContaining('Taller del centro'), findsOneWidget);
    expect(find.textContaining('250.00 MXN'), findsOneWidget);
    expect(find.text('Hecha a mano en nuestro taller.'), findsOneWidget);
    session.dispose();
  });
  testWidgets(
    'moderation retains reviewed report and can restore hidden content',
    (tester) async {
      final repo = _Repository();
      final session = await _session(repo, admin: true);
      await tester.pumpWidget(testApp(ModerationScreen(controller: session)));
      await tester.pumpAndSettle();
      final hide = find.text('Ocultar contenido');
      await tester.ensureVisible(hide);
      await tester.pumpAndSettle();
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(repo.hidden, isTrue);
      expect(find.text('Revisado'), findsOneWidget);
      final restore = find.text('Restaurar contenido');
      await tester.ensureVisible(restore);
      await tester.pumpAndSettle();
      await tester.tap(restore);
      await tester.pumpAndSettle();
      expect(repo.hidden, isFalse);
      session.dispose();
    },
  );

  testWidgets('moderation can retrieve reports after the first page', (
    tester,
  ) async {
    final repo = _Repository()..reportCount = 31;
    final session = await _session(repo, admin: true);
    await tester.pumpWidget(testApp(ModerationScreen(controller: session)));
    await tester.pumpAndSettle();
    final more = find.text('Cargar más reportes');
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(repo.reportOffsets, [0, 30]);
    expect(find.text('Cargar más reportes'), findsNothing);
    session.dispose();
  });
}
