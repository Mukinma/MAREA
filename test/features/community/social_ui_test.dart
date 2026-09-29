import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/data/community_repository.dart';
import '../../support/test_app.dart';

class Repo implements CommunityRepository {
  @override
  Future<String> imageUrl(String path) async =>
      throw StateError('image unavailable');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Social implements SocialRepository {
  PostReaction? selected;
  @override
  Future<void> setReaction(String id, PostReaction? r) async {
    selected = r;
  }

  @override
  Future<Map<String, PostSocialStats>> stats(List<String> ids) async => {
    for (final id in ids)
      id: PostSocialStats(
        postId: id,
        myReaction: selected,
        reactionCount: selected == null ? 0 : 1,
      ),
  };
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  for (final width in [360.0, 390.0, 600.0, 900.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('post layout $width / $scale has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          testApp(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: PostCard(
                    post: CommunityPost(
                      id: 'p',
                      authorId: 'a',
                      kind: PostKind.product,
                      title: 'Un objeto hecho entre todos',
                      body: List.filled(
                        20,
                        'Una descripción que puede crecer.',
                      ).join(' '),
                      category: 'arte',
                      imagePath: 'a/img.png',
                      createdAt: DateTime.utc(2026),
                      updatedAt: DateTime.utc(2026),
                    ),
                    repository: Repo(),
                    viewerId: 'b',
                    saved: false,
                    onChanged: () async {},
                    socialRepository: Social(),
                    stats: const PostSocialStats(postId: 'p'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Ver más'), findsOneWidget);
      });
    }
  }
  testWidgets('reaction is confirmed then can be removed', (tester) async {
    final social = Social();
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: CommunityPost(
                id: 'p',
                authorId: 'a',
                kind: PostKind.product,
                title: 'Pieza',
                body: 'Descripción',
                category: 'arte',
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026),
              ),
              repository: Repo(),
              viewerId: 'b',
              saved: false,
              onChanged: () async {},
              socialRepository: social,
              stats: const PostSocialStats(postId: 'p'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me inspira'));
    await tester.pumpAndSettle();
    expect(social.selected, PostReaction.inspire);
    await tester.tap(find.byTooltip('Me inspira'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirar reacción'));
    await tester.pumpAndSettle();
    expect(social.selected, isNull);
  });
}
