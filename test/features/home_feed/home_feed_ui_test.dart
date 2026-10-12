import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import '../../support/fakes.dart';

class FeedFake implements HomeFeedRepository {
  final requests = <HomeFeedFilter>[];
  @override
  Future<HomeFeedPage> page(
    HomeFeedFilter filter, {
    Map<String, dynamic>? cursor,
  }) async {
    requests.add(filter);
    return const HomeFeedPage(entries: []);
  }

  @override
  Future<bool> isFollowing(String authorId) async => false;
  @override
  Future<void> setFollowing(String authorId, bool following) async {}
}

void main() {
  testWidgets(
    'home filters request real data and show an explicit empty state',
    (tester) async {
      final feed = FeedFake();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        homeFeedRepository: feed,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: HomeScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu historia'), findsOneWidget);
      expect(find.text('Para ti'), findsOneWidget);
      expect(find.textContaining('No hay contenido'), findsOneWidget);
      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();
      expect(feed.requests.last.mode, HomeFeedMode.following);
      controller.dispose();
    },
  );
}
