import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/data/community_repository.dart';
import '../../support/test_app.dart';
import 'package:marea/features/community/presentation/reaction_button.dart';

class Repo implements CommunityRepository {
  @override
  Future<String> imageUrl(String path) async =>
      throw StateError('image unavailable');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Social implements SocialRepository {
  PostReaction? selected;
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> setReaction(String id, PostReaction? r) async {
    await pending?.future;
    if (fail) throw StateError('offline');
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

Widget card(Social social, {String viewerId = 'b'}) => testApp(
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
        viewerId: viewerId,
        saved: false,
        onChanged: () async {},
        socialRepository: social,
        stats: const PostSocialStats(postId: 'p'),
      ),
    ),
  ),
);

void main() {
  testWidgets('compact reaction count stays visible with enlarged text', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ReactionButton(
              compact: true,
              selected: null,
              count: 126,
              enabled: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final count = tester.renderObject<RenderParagraph>(find.text('126'));
    expect(count.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact reaction keeps toggle, count and keyboard palette', (
    tester,
  ) async {
    PostReaction? selected;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (_, update) => ReactionButton(
              compact: true,
              selected: selected,
              count: selected == null ? 12 : 13,
              enabled: true,
              onSelected: (r) => update(() => selected = r),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pumpAndSettle();
    expect(selected, PostReaction.like);
    expect(find.text('13'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Me inspira'), findsOneWidget);
    await tester.tap(find.text('Me inspira'));
    await tester.pumpAndSettle();
    expect(selected, PostReaction.inspire);
  });

  testWidgets('reaction controls have one accessible action each', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(card(Social()));
    expect(find.bySemanticsLabel('Reaccionar'), findsOneWidget);
    expect(find.bySemanticsLabel('Elegir reacción'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('reaction palette supports keyboard selection and escape', (
    tester,
  ) async {
    final social = Social();
    await tester.pumpWidget(card(social));
    await tester.tap(find.byTooltip('Elegir reacción'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(social.selected, PostReaction.inspire);
    await tester.tap(find.byTooltip('Elegir reacción'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Me inspira'), findsNothing);
    expect(social.selected, PostReaction.inspire);
  });

  testWidgets('holding and dragging selects the reaction under the finger', (
    tester,
  ) async {
    final social = Social();
    await tester.pumpWidget(card(social));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip('Reaccionar')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Me inspira'), findsOneWidget);
    await gesture.moveTo(tester.getCenter(find.text('Me inspira')));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Me inspira'), findsNothing);
  });
  testWidgets('releasing outside the palette cancels without reacting', (
    tester,
  ) async {
    final social = Social();
    await tester.pumpWidget(card(social));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip('Reaccionar')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(const Offset(5, 5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
  testWidgets('a second tap wins while the first request is pending', (
    tester,
  ) async {
    final social = Social()..pending = Completer<void>();
    await tester.pumpWidget(card(social));
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byTooltip('Me gusta'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0'), findsNWidgets(2));
    social.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
  testWidgets('short tap reacts immediately while the server is pending', (
    tester,
  ) async {
    final social = Social()..pending = Completer<void>();
    await tester.pumpWidget(card(social));
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Me inspira'), findsNothing);
    social.pending!.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Me gusta'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
  testWidgets('failed reaction restores the icon and count', (tester) async {
    final social = Social()
      ..pending = Completer<void>()
      ..fail = true;
    await tester.pumpWidget(card(social));
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1'), findsOneWidget);
    social.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
  testWidgets('an old reaction response cannot update a new viewer', (
    tester,
  ) async {
    final social = Social()..pending = Completer<void>();
    await tester.pumpWidget(card(social));
    await tester.tap(find.byTooltip('Reaccionar'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(card(social, viewerId: 'new-account'));
    social.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
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
    await tester.tap(find.byTooltip('Elegir reacción'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me inspira'));
    await tester.pumpAndSettle();
    expect(social.selected, PostReaction.inspire);
    await tester.tap(find.byTooltip('Elegir reacción'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirar reacción'));
    await tester.pumpAndSettle();
    expect(social.selected, isNull);
  });
}
