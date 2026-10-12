import 'package:marea/features/profile/models/profile.dart';
import 'dart:typed_data';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'mission_repository_fake.dart';

CommunityPost homePost({
  String id = 'post',
  String title = 'Creamos juntos',
  String? imagePath,
}) => CommunityPost(
  id: id,
  authorId: 'other',
  kind: PostKind.community,
  title: title,
  body: 'Una idea, una novedad y un espacio para compartir con la comunidad.',
  category: 'arte',
  imagePath: imagePath,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  allowsCollaboration: true,
);
Mission homeMission() => Mission(
  id: 'mission',
  authorId: 'other',
  title: 'Colabora en el mercado creativo',
  body: 'Buscamos personas para crear una experiencia local.',
  category: 'arte',
  location: 'Manzanillo',
  startsAt: DateTime.now().add(const Duration(days: 5)),
  capacity: 5,
  createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
);

class HomeCommunityFake extends MissionRepositoryFake {
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    const CommunityProfile(
      id: 'other',
      fullName: 'Mariana Torres',
      username: 'mariana',
      userType: UserType.creator,
    ),
  ];
  @override
  Future<String> imageUrl(String path) async =>
      throw StateError('Imagen no disponible');
}

class HomeFeedFake implements HomeFeedRepository {
  final requests = <HomeFeedFilter>[];
  final cursors = <Map<String, dynamic>?>[];
  List<HomeFeedEntry> entries = [];
  Map<String, dynamic>? next;
  final follows = <String>{};
  Future<HomeFeedPage> Function(HomeFeedFilter, Map<String, dynamic>?)? onPage;
  bool failFollow = false;
  @override
  Future<HomeFeedPage> page(
    HomeFeedFilter filter, {
    Map<String, dynamic>? cursor,
  }) async {
    requests.add(filter);
    cursors.add(cursor);
    if (onPage != null) return onPage!(filter, cursor);
    return HomeFeedPage(entries: entries, cursor: next);
  }

  @override
  Future<bool> isFollowing(String id) async => follows.contains(id);
  @override
  Future<void> setFollowing(String id, bool following) async {
    if (failFollow) throw StateError('Sin conexión');
    if (following) {
      follows.add(id);
    } else {
      follows.remove(id);
    }
  }
}

class StoriesFake implements StoriesRepository {
  Future<StoryBatch> Function()? onList;
  final values = <Story>[];
  final viewed = <String>{};
  final published = <StoryInput>[];
  bool failPublish = false;
  @override
  Future<StoryBatch> stories() async => onList != null
      ? onList!()
      : StoryBatch(stories: values, serverTime: DateTime.now());
  @override
  Future<String> upload(String id, Uint8List bytes) async => 'user/$id.png';
  @override
  Future<void> publish(StoryInput input) async {
    published.add(input);
    if (failPublish) throw StateError('Sin conexión');
  }

  @override
  Future<String> imageUrl(Story story) async =>
      throw StateError('Foto no disponible');
  @override
  Future<void> markSeen(String id) async {
    viewed.add(id);
  }

  @override
  Future<void> delete(String id) async {
    values.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> report(String id, String reason) async {}
  @override
  Future<List<Story>> reported() async => [];
  @override
  Future<void> moderate(String id, bool hidden) async {}
}
