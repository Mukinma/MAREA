class Story {
  const Story({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.expiresAt,
    this.imagePath,
    this.seen = false,
    this.hidden = false,
    this.reportReasons = const [],
  });
  final String id, authorId, text;
  final String? imagePath;
  final DateTime createdAt, expiresAt;
  final bool seen, hidden;
  final List<String> reportReasons;
  bool isAvailableAt(DateTime now) => !hidden && expiresAt.isAfter(now);
  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    text: json['body'] as String? ?? '',
    imagePath: json['image_path'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: DateTime.parse(json['expires_at'] as String),
    seen: json['seen'] == true,
    hidden: json['hidden'] == true,
    reportReasons: (json['reports'] as List? ?? [])
        .map((r) => (r as Map)['reason'] as String)
        .toList(),
  );
}

class StoryInput {
  const StoryInput({required this.id, this.text = '', this.imagePath});
  final String id, text;
  final String? imagePath;
  String? validate() {
    if (text.trim().isEmpty && imagePath == null) {
      return 'Escribe algo o añade una foto.';
    }
    if (text.runes.length > 500) return 'Usa hasta 500 caracteres.';
    return null;
  }
}

class StoryBatch {
  StoryBatch({required this.stories, required this.serverTime})
    : receivedAt = DateTime.now();
  final List<Story> stories;
  final DateTime serverTime, receivedAt;
  DateTime get now => serverTime.add(DateTime.now().difference(receivedAt));
}
