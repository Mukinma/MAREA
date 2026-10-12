import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFeedCursorExpired implements Exception {
  @override
  String toString() => 'Actualiza el feed para continuar.';
}

abstract interface class HomeFeedRepository {
  Future<HomeFeedPage> page(
    HomeFeedFilter filter, {
    Map<String, dynamic>? cursor,
  });
  Future<bool> isFollowing(String authorId);
  Future<void> setFollowing(String authorId, bool following);
}

class SupabaseHomeFeedRepository implements HomeFeedRepository {
  SupabaseHomeFeedRepository(this.client);
  final SupabaseClient client;
  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      if (e is PostgrestException && e.message == 'feed_cursor_expired') {
        throw HomeFeedCursorExpired();
      }
      throw communityFailure(e);
    }
  }

  @override
  Future<HomeFeedPage> page(
    HomeFeedFilter filter, {
    Map<String, dynamic>? cursor,
  }) => _run(() async {
    final error = filter.validate();
    if (error != null) throw AppFailure(error);
    final json = await client.rpc(
      'home_feed',
      params: {'filters': filter.toJson(), 'page_cursor': cursor},
    );
    return HomeFeedPage.fromJson(Map<String, dynamic>.from(json as Map));
  });
  @override
  Future<bool> isFollowing(String authorId) => _run(() async {
    final rows = await client
        .from('profile_follows')
        .select('author_id')
        .eq('author_id', authorId);
    return rows.isNotEmpty;
  });
  @override
  Future<void> setFollowing(String authorId, bool following) => _run(() async {
    await client.rpc(
      'set_profile_follow',
      params: {'author_uuid': authorId, 'following': following},
    );
  });
}
