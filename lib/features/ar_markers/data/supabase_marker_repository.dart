import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/ar_marker.dart';
import 'marker_repository.dart';

class SupabaseMarkerRepository implements MarkerRepository {
  SupabaseMarkerRepository(this.client, {this.currentOwner});
  final SupabaseClient client;
  final String? Function()? currentOwner;
  static const _uuid = Uuid();
  static const _bucket = 'ar-marker-images';

  void _check(String owner) {
    final actor = currentOwner == null
        ? client.auth.currentUser?.id
        : currentOwner!();
    if (actor != owner) {
      throw StateError('La sesión cambió. Vuelve a abrir tus marcadores.');
    }
    validateMarkerId(owner);
  }

  @override
  Future<List<ArMarker>> listOwned(String ownerId) async {
    _check(ownerId);
    final rows = await client
        .from('ar_markers')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    _check(ownerId);
    return rows.map(ArMarker.new).toList();
  }

  @override
  Future<List<ArMarker>> nearbyPublic({
    double? latitude,
    double? longitude,
  }) async {
    final rows = await client
        .from('ar_markers')
        .select()
        .eq('active', true)
        .eq('review_status', 'approved');
    return rows.map(ArMarker.new).where((marker) => marker.isTested).toList();
  }

  @override
  Future<ArMarker?> get(String ownerId, String id) async {
    _check(ownerId);
    validateMarkerId(id);
    final row = await client
        .from('ar_markers')
        .select()
        .eq('id', id)
        .maybeSingle();
    _check(ownerId);
    return row == null ? null : ArMarker(row);
  }

  @override
  Future<ArMarker> save(
    String ownerId,
    Map<String, dynamic> values, {
    Uint8List? imageBytes,
  }) async {
    _check(ownerId);
    final id = values['id'] as String? ?? _uuid.v4();
    validateMarkerId(id);
    final previous = values['id'] == null ? null : await get(ownerId, id);
    if (values['id'] != null &&
        (previous == null || previous.ownerId != ownerId)) {
      throw StateError('El marcador ya no está disponible.');
    }
    final editable = markerEditableValues({...?previous?.data, ...values});
    if (previous == null && imageBytes == null) {
      throw StateError('Añade la imagen que reconocerá la cámara.');
    }
    if (imageBytes != null) {
      validateMarkerImage(imageBytes);
      final path = '$ownerId/$id/${_uuid.v4()}.jpg';
      _check(ownerId);
      await client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      editable['reference_path'] = path;
    }
    _check(ownerId);
    final Map<String, dynamic>? row;
    if (previous == null) {
      row = await client
          .from('ar_markers')
          .insert({'id': id, 'owner_id': ownerId, ...editable})
          .select()
          .single();
    } else {
      row = await client
          .from('ar_markers')
          .update(editable)
          .eq('owner_id', ownerId)
          .eq('id', id)
          .eq('reference_version', previous.referenceVersion)
          .select()
          .maybeSingle();
    }
    _check(ownerId);
    if (row == null) {
      throw StateError(
        'El marcador cambió mientras lo editabas. Vuelve a abrirlo.',
      );
    }
    return ArMarker(row);
  }

  @override
  Future<void> delete(String ownerId, String id) async {
    final marker = await get(ownerId, id);
    if (marker == null) return;
    if (marker.ownerId != ownerId) {
      throw StateError('El marcador no pertenece a esta cuenta.');
    }
    _check(ownerId);
    final deleted = await client
        .from('ar_markers')
        .delete()
        .eq('owner_id', ownerId)
        .eq('id', id)
        .eq('reference_version', marker.referenceVersion)
        .select('id');
    if (deleted.isEmpty) {
      throw StateError(
        'El marcador cambió. Vuelve a abrirlo antes de eliminarlo.',
      );
    }
    _check(ownerId);
    final prefix = '$ownerId/$id';
    while (true) {
      final files = await client.storage.from(_bucket).list(path: prefix);
      _check(ownerId);
      if (files.isEmpty) break;
      await client.storage.from(_bucket).remove([
        for (final file in files) '$prefix/${file.name}',
      ]);
      _check(ownerId);
    }
  }

  @override
  Future<Uint8List> loadImage(String ownerId, ArMarker marker) async {
    final current = await get(ownerId, marker.id);
    if (current == null ||
        current.referenceVersion != marker.referenceVersion ||
        current.referencePath == null) {
      throw StateError('La imagen cambió. Abre de nuevo el marcador.');
    }
    _check(ownerId);
    final bytes = await client.storage
        .from(_bucket)
        .download(current.referencePath!);
    _check(ownerId);
    validateMarkerImage(bytes);
    final latest = await get(ownerId, marker.id);
    if (latest == null || latest.referenceVersion != marker.referenceVersion) {
      throw StateError(
        'La imagen cambió mientras se abría. Vuelve a intentarlo.',
      );
    }
    return bytes;
  }

  @override
  Future<ArMarker> confirmRecognition(
    String ownerId,
    String id,
    String referenceVersion,
    String platform,
    int seconds,
  ) async {
    _check(ownerId);
    validateMarkerId(id);
    validateMarkerRecognition(platform, seconds);
    final row = await client.rpc(
      'ar_markers_confirm_recognition',
      params: {
        'p_id': id,
        'p_reference_version': referenceVersion,
        'p_platform': platform,
        'p_seconds': seconds,
      },
    );
    _check(ownerId);
    return ArMarker(Map<String, dynamic>.from(row as Map));
  }
}
