import 'dart:math';
import 'dart:typed_data';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ShowcaseRepository {
  Future<List<ShowcaseItem>> items({
    String? ownerId,
    String query = '',
    String? category,
    ShowcaseKind? kind,
    bool management = false,
    bool savedOnly = false,
    int offset = 0,
  });
  Future<ShowcaseItem?> item(String id);
  Future<String> save(ShowcaseInput input, {String? id});
  Future<void> delete(ShowcaseItem item);
  Future<Set<String>> savedIds();
  Future<void> setSaved(String id, bool saved);
  Future<void> report(String id, String reason);
  Future<void> moderate(String id, bool hide);
  Future<String> upload(Uint8List png);
  Future<String> imageUrl(String path);
  Future<void> removeImage(String path);
}

class SupabaseShowcaseRepository implements ShowcaseRepository {
  SupabaseShowcaseRepository(this._client);
  final SupabaseClient _client;
  static const pageSize = 30;
  static const _selection = '*,showcase_images(path,position)';
  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw const AppFailure('Inicia sesión nuevamente.'));
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw communityFailure(e);
    }
  }

  @override
  Future<List<ShowcaseItem>> items({
    String? ownerId,
    String query = '',
    String? category,
    ShowcaseKind? kind,
    bool management = false,
    bool savedOnly = false,
    int offset = 0,
  }) => _run(() async {
    var request = _client.from('showcase_items').select(_selection);
    if (ownerId != null) request = request.eq('owner_id', ownerId);
    if (!management || ownerId != _userId) {
      request = request
          .eq('status', 'published')
          .eq('available', true)
          .eq('hidden', false);
    }
    if (category != null) request = request.eq('category', category);
    if (kind != null) request = request.eq('kind', kind.name);
    if (query.trim().isNotEmpty) {
      final pattern = query
          .trim()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll('"', r'\"');
      request = request.ilike('title', '%$pattern%');
    }
    if (savedOnly) {
      final ids = await savedIds();
      if (ids.isEmpty) return <ShowcaseItem>[];
      request = request.inFilter('id', ids.toList());
    }
    final start = max(0, offset);
    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(start, start + pageSize - 1);
    return rows.map(ShowcaseItem.fromJson).toList();
  });
  @override
  Future<ShowcaseItem?> item(String id) => _run(() async {
    final row = await _client
        .from('showcase_items')
        .select(_selection)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : ShowcaseItem.fromJson(row);
  });
  @override
  Future<String> save(ShowcaseInput input, {String? id}) => _run(() async {
    final error = input.validate();
    if (error != null) throw AppFailure(error);
    final before = id == null ? null : await item(id);
    final result =
        await _client.rpc(
              'save_showcase',
              params: {'item_input': input.toJson(), 'item_id': id},
            )
            as String;
    for (final path in before?.imagePaths ?? <String>[]) {
      if (!input.imagePaths.contains(path)) {
        try {
          await removeImage(path);
        } catch (_) {
          /* Persisted fiche wins; cleanup may be retried. */
        }
      }
    }
    return result;
  });
  @override
  Future<void> delete(ShowcaseItem item) => _run(() async {
    await _client.rpc('delete_showcase', params: {'item_id': item.id});
    for (final path in item.imagePaths) {
      try {
        await removeImage(path);
      } catch (_) {
        /* Account deletion also cleans this folder. */
      }
    }
  });
  @override
  Future<Set<String>> savedIds() => _run(() async {
    final rows = await _client
        .from('showcase_saves')
        .select('item_id')
        .eq('user_id', _userId);
    return rows.map((r) => r['item_id'] as String).toSet();
  });
  @override
  Future<void> setSaved(String id, bool saved) => _run(() async {
    if (saved) {
      await _client
          .from('showcase_saves')
          .upsert(
            {'item_id': id},
            onConflict: 'user_id,item_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('showcase_saves')
          .delete()
          .eq('item_id', id)
          .eq('user_id', _userId);
    }
  });
  @override
  Future<void> report(String id, String reason) => _run(() async {
    if (reason.trim().length < 5 || reason.trim().length > 500) {
      throw const AppFailure(
        'Describe el motivo usando entre 5 y 500 caracteres.',
      );
    }
    await _client.rpc(
      'report_showcase',
      params: {'item_id': id, 'report_reason': reason.trim()},
    );
  });
  @override
  Future<void> moderate(String id, bool hide) => _run(() async {
    await _client.rpc(
      'moderate_content',
      params: {
        'content_id': id,
        'content_kind': 'showcase',
        'hide_content': hide,
      },
    );
  });
  @override
  Future<String> imageUrl(String path) => _run(
    () => _client.storage.from('showcase-media').createSignedUrl(path, 600),
  );
  @override
  Future<void> removeImage(String path) => _run(() async {
    await _client.storage.from('showcase-media').remove([path]);
  });
  @override
  Future<String> upload(Uint8List png) => _run(() async {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (png.length < 8 ||
        png.length > 4194304 ||
        List.generate(8, (i) => png[i] == signature[i]).contains(false)) {
      throw const AppFailure('Elige una imagen PNG de hasta 4 MB.');
    }
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    final path =
        '$_userId/${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}.png';
    await _client.storage
        .from('showcase-media')
        .uploadBinary(
          path,
          png,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );
    return path;
  });
}
