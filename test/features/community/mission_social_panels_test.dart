import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import '../../support/fakes.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/data/mission_social_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/mission_social_actions.dart';
import 'package:marea/features/community/presentation/mission_social_panels.dart';
import 'package:marea/features/community/presentation/reaction_button.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import '../../support/test_app.dart';

class Profiles implements CommunityRepository {
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Social implements MissionSocialRepository {
  bool fail = true;
  PostReaction? reaction;
  final operations = <String>[];
  final rows = <MissionComment>[];
  @override
  Future<Map<String, MissionSocialStats>> stats(List<String> ids) async => {
    for (final id in ids)
      id: MissionSocialStats(
        missionId: id,
        reactionCount: reaction == null ? 0 : 1,
        myReaction: reaction,
        commentCount: rows.length,
      ),
  };
  @override
  Future<void> setReaction(String id, PostReaction? next) async {
    if (fail) throw const AppFailure('No se guardó la reacción.');
    reaction = next;
  }

  @override
  Future<List<MissionComment>> comments(String id, {int offset = 0}) async =>
      rows;
  @override
  Future<MissionComment?> comment(String id) async =>
      rows.where((c) => c.id == id).firstOrNull;
  @override
  Future<String> createComment(String id, String body, String operation) async {
    operations.add(operation);
    if (!rows.any((c) => c.id == operation)) {
      rows.add(
        MissionComment(
          id: operation,
          missionId: id,
          authorId: 'b',
          body: body,
          createdAt: DateTime.utc(2026),
        ),
      );
    }
    if (fail) {
      fail = false;
      throw const AppFailure('Respuesta perdida.');
    }
    return operation;
  }

  @override
  Future<void> deleteComment(String id) async =>
      rows.removeWhere((c) => c.id == id);
}

class DetailCommunity extends Profiles {
  @override
  Future<Mission?> mission(String id) async =>
      id == 'm' ? missionFixture : null;
  @override
  Future<List<MissionApplication>> applications({String? missionId}) async =>
      [];
  @override
  Future<Set<String>> savedMissionIds() async => {};
}

class Inbox implements SocialRepository {
  final read = <String>[];
  @override
  Future<void> markRead({String? id, DateTime? before}) async {
    if (id != null) read.add(id);
  }

  @override
  Stream<void> changes(String recipientId) => const Stream.empty();
  @override
  Future<int> unreadCount() async => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final missionFixture = Mission(
  id: 'm',
  authorId: 'a',
  title: 'Misión',
  body: 'Colaboración',
  category: 'arte',
  location: 'CDMX',
  startsAt: DateTime.utc(2027),
  capacity: 3,
  createdAt: DateTime.utc(2026),
);
void main() {
  testWidgets(
    'mission detail comment link marks notice read only after target is loaded',
    (tester) async {
      final social = Social()
        ..rows.add(
          MissionComment(
            id: 'target',
            missionId: 'm',
            authorId: 'b',
            body: 'Comentario destino',
            createdAt: DateTime.utc(2026),
          ),
        );
      final inbox = Inbox();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        communityRepository: DetailCommunity(),
        missionSocialRepository: social,
        socialRepository: inbox,
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testApp(
          MissionDetailScreen(
            controller: controller,
            missionId: 'm',
            panel: 'comments',
            commentId: 'target',
            notificationId: 'notice',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Comentario destino'), findsOneWidget);
      expect(inbox.read, ['notice']);
    },
  );
  testWidgets(
    'mission comment retry keeps payload and operation after lost response',
    (tester) async {
      final repository = Social(), draft = CommentDraft();
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: MissionCommentsPanel(
              mission: missionFixture,
              repository: repository,
              community: Profiles(),
              viewerId: 'b',
              draft: draft,
              onChanged: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Hola misión');
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(draft.text, 'Hola misión');
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(repository.operations[0], repository.operations[1]);
      expect(repository.rows, hasLength(1));
      expect(draft.text, isEmpty);
    },
  );
  testWidgets('missing notification comment is not marked read', (
    tester,
  ) async {
    var ready = 0;
    final draft = CommentDraft();
    addTearDown(draft.dispose);
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: MissionCommentsPanel(
            mission: missionFixture,
            repository: Social(),
            community: Profiles(),
            viewerId: 'b',
            draft: draft,
            commentId: 'removed',
            onReady: () async {
              ready++;
            },
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Este comentario fue retirado.'), findsOneWidget);
    expect(ready, 0);
  });
  testWidgets(
    'failed mission reaction preserves confirmed selection and count',
    (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: MissionSocialActions(
              mission: missionFixture,
              repository: Social(),
              community: Profiles(),
              config: AppConfig.fromValues(
                supabaseUrl: '',
                supabaseAnonKey: '',
              ),
              viewerId: 'b',
              stats: const MissionSocialStats(missionId: 'm'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      final button = tester.widget<ReactionButton>(find.byType(ReactionButton));
      expect(button.selected, isNull);
      expect(button.count, 0);
      expect(find.text('No se guardó la reacción.'), findsOneWidget);
    },
  );
  for (final width in [360.0, 390.0]) {
    testWidgets('mission social actions fit $width with 200 percent text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(2),
              ),
              child: MissionSocialActions(
                mission: missionFixture,
                repository: Social(),
                community: Profiles(),
                config: AppConfig.fromValues(
                  supabaseUrl: '',
                  supabaseAnonKey: '',
                ),
                viewerId: 'b',
                stats: const MissionSocialStats(
                  missionId: 'm',
                  reactionCount: 100,
                ),
                trailingCTA: FilledButton(
                  onPressed: () {},
                  child: const Text('Postularme'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
