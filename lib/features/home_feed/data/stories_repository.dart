import 'dart:typed_data';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StoriesRepository {
  Future<StoryBatch> stories();
  Future<String> upload(String storyId, Uint8List bytes);
  Future<void> publish(StoryInput input);
  Future<String> imageUrl(Story story);
  Future<void> markSeen(String id);
  Future<void> delete(String id);
  Future<void> report(String id, String reason);
  Future<List<Story>> reported();
  Future<void> moderate(String id, bool hidden);
}

class SupabaseStoriesRepository implements StoriesRepository {
  SupabaseStoriesRepository(this.client);
  final SupabaseClient client;
  Future<T> _run<T>(Future<T> Function() op) async {
    try {
      return await op();
    } catch (e) {
      if (e is PostgrestException && e.message.contains('story_unavailable')) {
        throw const AppFailure('Esta historia ya no está disponible.');
      }
      if (e is PostgrestException &&
          (e.code == 'PGRST202' ||
              e.code == 'PGRST204' ||
              e.code == 'PGRST205' ||
              e.code == '42703' ||
              e.code == '42P01') &&
          (e.message.contains('publish_story') ||
              e.message.contains('story_') ||
              e.message.contains('stories') ||
              e.message.contains('schema cache'))) {
        if (e.code == 'PGRST202' || e.code == 'PGRST204' || e.code == '42703') {
          throw AppFailure(
            'El servidor rechazó el RPC de historias '
            '(${e.code}): ${e.message}',
          );
        }
        throw const AppFailure(
          'Supabase aún no tiene activadas las migraciones 016, 018, 019 y 034 '
          'para historias. Aplica las migraciones y vuelve a intentarlo.',
        );
      }
      throw communityFailure(e);
    }
  }

  @override
  Future<StoryBatch> stories() => _run(() async {
    final json = Map<String, dynamic>.from(
      await client.rpc('list_stories') as Map,
    );
    return StoryBatch(
      stories: (json['stories'] as List)
          .map((e) => Story.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      serverTime: DateTime.parse(json['server_time'] as String),
    );
  });
  @override
  Future<String> upload(String storyId, Uint8List bytes) => _run(() async {
    final user = client.auth.currentSession?.user.id;
    if (user == null) throw const AppFailure('Inicia sesión nuevamente.');
    final path = '$user/$storyId.png';
    try {
      await client.storage
          .from('story-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      if (e.statusCode != '409' && e.error != 'Duplicate') rethrow;
    }
    return path;
  });
  @override
  Future<void> publish(StoryInput input) => _run(() async {
    final error = input.validate();
    if (error != null) throw AppFailure(error);
    if (client.auth.currentSession == null) {
      throw const AppFailure('Tu sesión expiró. Inicia sesión nuevamente.');
    }
    await client.rpc(
      'publish_story',
      params: {
        'story_uuid': input.id,
        'story_body': input.text.trim(),
        'story_image': input.imagePath,
        'story_category': input.category,
        'story_target_type': input.targetType?.databaseValue,
      },
    );
  });
  @override
  Future<String> imageUrl(Story story) => _run(
    () => client.storage
        .from('story-images')
        .createSignedUrl(story.imagePath!, 60),
  );
  @override
  Future<void> markSeen(String id) => _run(() async {
    await client.rpc('mark_story_seen', params: {'story_uuid': id});
  });
  @override
  Future<void> delete(String id) => _run(() async {
    await client.rpc('delete_story', params: {'story_uuid': id});
  });
  @override
  Future<void> report(String id, String reason) => _run(() async {
    await client.rpc(
      'report_story',
      params: {'story_uuid': id, 'report_reason': reason.trim()},
    );
  });
  @override
  Future<List<Story>> reported() => _run(() async {
    final rows = await client.rpc('reported_stories');
    return (rows as List)
        .map((e) => Story.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  });
  @override
  Future<void> moderate(String id, bool hidden) => _run(() async {
    await client.rpc(
      'moderate_story',
      params: {'story_uuid': id, 'hide': hidden},
    );
  });
}
