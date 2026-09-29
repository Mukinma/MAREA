import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/notifications_controller.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/features/community/data/community_repository.dart';
import '../../support/test_app.dart';

class Community implements CommunityRepository {
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Social implements SocialRepository {
  final ids = <String>[];
  bool fail = true;
  final rows = <PostComment>[];
  final counts = <Completer<int>>[];
  @override
  Future<List<PostComment>> comments(String postId, {int offset = 0}) async =>
      rows;
  @override
  Future<String> createComment(
    String postId,
    String body,
    String operationId,
  ) async {
    ids.add(operationId);
    if (!rows.any((c) => c.id == operationId)) {
      rows.add(
        PostComment(
          id: operationId,
          postId: postId,
          authorId: 'b',
          body: body,
          createdAt: DateTime.utc(2026),
        ),
      );
    }
    if (fail) {
      fail = false;
      throw const AppFailure('Respuesta perdida. Reintenta.');
    }
    return operationId;
  }

  @override
  Stream<void> changes(String id) => const Stream.empty();
  @override
  Future<int> unreadCount() {
    final c = Completer<int>();
    counts.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final post = CommunityPost(
  id: 'p',
  authorId: 'a',
  kind: PostKind.product,
  title: 'Pieza',
  body: 'Descripción',
  category: 'arte',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
void main() {
  testWidgets('cancelled share never reports success', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => sharePost(
                ctx,
                Uri.parse('https://example.com/posts/p'),
                share: (params) async {
                  calls++;
                  expect(params.uri?.path, '/posts/p');
                  return const ShareResult('', ShareResultStatus.dismissed);
                },
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir enlace'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets(
    'comment draft survives failure and reopening, retry uses same operation',
    (tester) async {
      final repo = Social(), draft = CommentDraft();
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSocialPanel(
                  context,
                  CommentsPanel(
                    post: post,
                    repository: repo,
                    community: Community(),
                    viewerId: 'b',
                    draft: draft,
                    onChanged: () async {},
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Me gusta esta idea');
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(draft.text, 'Me gusta esta idea');
      expect(find.text('Respuesta perdida. Reintenta.'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.ids.length, 2);
      expect(repo.ids.first, repo.ids.last);
      expect(repo.rows.length, 1);
      expect(draft.text, isEmpty);
    },
  );
  testWidgets('notification response from previous session is ignored', (
    tester,
  ) async {
    final repo = Social();
    final c = NotificationsController(repo);
    addTearDown(c.dispose);
    c.setSession('a');
    c.setSession('b');
    repo.counts.last.complete(2);
    await tester.pump();
    expect(c.unread, 2);
    repo.counts.first.complete(99);
    await tester.pump();
    expect(c.unread, 2);
    c.setSession(null);
    expect(c.unread, 0);
  });
  for (final width in [360.0, 900.0]) {
    testWidgets('comments panel fits keyboard and enlarged text $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      final draft = CommentDraft()
        ..text = List.filled(25, 'Una respuesta larga.').join(' ');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        testApp(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 320),
            ),
            child: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showSocialPanel(
                    ctx,
                    CommentsPanel(
                      post: post,
                      repository: Social(),
                      community: Community(),
                      viewerId: 'b',
                      draft: draft,
                      onChanged: () async {},
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
