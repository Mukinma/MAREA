import 'package:marea/features/community/models/community_models.dart';

enum HomeFeedMode { forYou, nearby, following, trending }

enum HomeFeedKind { all, post, mission }

class HomeFeedFilter {
  const HomeFeedFilter({
    this.mode = HomeFeedMode.forYou,
    this.kind = HomeFeedKind.all,
    this.category,
    this.latitude,
    this.longitude,
    this.radiusKm = 10,
  });
  final HomeFeedMode mode;
  final HomeFeedKind kind;
  final String? category;
  final double? latitude, longitude;
  final int radiusKm;
  String? validate() {
    if (![5, 10, 25, 50].contains(radiusKm)) {
      return 'Selecciona un radio válido.';
    }
    if (mode == HomeFeedMode.nearby && (latitude == null || longitude == null)) {
      return 'Elige tu ubicación para ver contenido cercano.';
    }
    if (latitude != null && (!latitude!.isFinite || latitude!.abs() > 90) ||
        longitude != null && (!longitude!.isFinite || longitude!.abs() > 180)) {
      return 'Elige una ubicación válida.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'kind': kind.name,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'radius_km': radiusKm,
  };
}

class HomeFeedEntry {
  HomeFeedEntry.post(CommunityPost value) : post = value, mission = null;
  HomeFeedEntry.mission(Mission value) : mission = value, post = null;
  final CommunityPost? post;
  final Mission? mission;
  String get id => post?.id ?? mission!.id;
  String get authorId => post?.authorId ?? mission!.authorId;
  DateTime get createdAt => post?.createdAt ?? mission!.createdAt;
  String get key => '${post != null ? 'post' : 'mission'}:$id';
  factory HomeFeedEntry.fromJson(Map<String, dynamic> json) =>
      json['kind'] == 'post'
      ? HomeFeedEntry.post(
          CommunityPost.fromJson(
            Map<String, dynamic>.from(json['content'] as Map),
          ),
        )
      : HomeFeedEntry.mission(
          Mission.fromJson(Map<String, dynamic>.from(json['content'] as Map)),
        );
}

class HomeFeedPage {
  const HomeFeedPage({required this.entries, this.cursor});
  final List<HomeFeedEntry> entries;
  final Map<String, dynamic>? cursor;
  factory HomeFeedPage.fromJson(Map<String, dynamic> json) => HomeFeedPage(
    entries: (json['entries'] as List)
        .map((e) => HomeFeedEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    cursor: json['cursor'] == null
        ? null
        : Map<String, dynamic>.from(json['cursor'] as Map),
  );
}
