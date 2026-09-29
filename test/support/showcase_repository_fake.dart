import 'dart:typed_data';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/showcase/data/showcase_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';

class ShowcaseRepositoryFake implements ShowcaseRepository {
  final Map<String, ShowcaseItem> records = {};
  final Set<String> saved = {};
  ShowcaseInput? submitted;
  bool failSave = false;
  int listings = 0;
  String ownerId = '3dd684f0-b55f-4d4f-b4cf-a0df3fd8b246';
  @override
  Future<List<ShowcaseItem>> items({
    String? ownerId,
    String query = '',
    String? category,
    ShowcaseKind? kind,
    bool management = false,
    bool savedOnly = false,
    int offset = 0,
  }) async {
    listings++;
    return records.values
        .where(
          (v) =>
              (ownerId == null || ownerId == v.ownerId) &&
              (management ||
                  (v.status == ShowcaseStatus.published &&
                      v.available &&
                      !v.hidden)) &&
              (category == null || category == v.category) &&
              (kind == null || kind == v.kind) &&
              (!savedOnly || saved.contains(v.id)) &&
              v.title.contains(query),
        )
        .skip(offset)
        .take(30)
        .toList();
  }

  @override
  Future<ShowcaseItem?> item(String id) async => records[id];
  @override
  Future<String> save(ShowcaseInput input, {String? id}) async {
    submitted = input;
    if (failSave) throw const AppFailure('No pudimos conectarnos.');
    final key = id ?? 'fiche-${records.length}';
    records[key] = ShowcaseItem(
      id: key,
      ownerId: ownerId,
      kind: input.kind,
      title: input.title,
      body: input.body,
      category: input.category,
      status: input.status,
      available: input.available,
      price: input.price,
      projectUrl: input.projectUrl,
      imagePaths: input.imagePaths,
      hidden: records[key]?.hidden ?? false,
      createdAt: DateTime.utc(2026, 9, 27),
    );
    return key;
  }

  @override
  Future<void> delete(ShowcaseItem item) async {
    records.remove(item.id);
  }

  @override
  Future<Set<String>> savedIds() async => {...saved};
  @override
  Future<void> setSaved(String id, bool save) async {
    save ? saved.add(id) : saved.remove(id);
  }

  @override
  Future<void> report(String id, String reason) async {}
  @override
  Future<void> moderate(String id, bool hide) async {}
  @override
  Future<String> upload(Uint8List png) async => 'owner/photo.png';
  @override
  Future<String> imageUrl(String path) async =>
      'https://example.invalid/photo.png';
  @override
  Future<void> removeImage(String path) async {}
}
