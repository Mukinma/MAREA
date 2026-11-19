import 'dart:typed_data';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/ar_marker.dart';
import 'marker_repository.dart';

class SupabaseMarkerRepository implements MarkerPublicationRepository {
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
    var query = client
        .from('ar_markers')
        .select()
        .eq('active', true)
        .eq('review_status', 'approved');
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude.abs() <= 90 &&
        longitude.abs() <= 180) {
      // Refresh the vicinity, then let proximity tracking apply its 20 m radius.
      const span = .5;
      query = query
          .gte('latitude', math.max(-90, latitude - span))
          .lte('latitude', math.min(90, latitude + span));
      if (latitude.abs() < 89.5) {
        final west = longitude - span;
        final east = longitude + span;
        if (west < -180) {
          query = query.or('longitude.gte.${west + 360},longitude.lte.$east');
        } else if (east > 180) {
          query = query.or('longitude.gte.$west,longitude.lte.${east - 360}');
        } else {
          query = query.gte('longitude', west).lte('longitude', east);
        }
      }
    }
    final rows = await query;
    return rows.map(ArMarker.new).where((marker) => marker.isPublic).toList();
  }

  @override
  Future<ArMarker?> get(String ownerId, String id) async {
    _check(ownerId);
    validateMarkerId(id);
    final row = await client
        .from('ar_markers')
        .select()
        .eq('id', id)
        .eq('owner_id', ownerId)
        .maybeSingle();
    _check(ownerId);
    return row == null ? null : ArMarker(row);
  }

  @override
  Future<List<ArMarker>> publicForOwner(String viewerId, String ownerId) async {
    _check(viewerId);
    validateMarkerId(ownerId);
    final rows = await client
        .from('ar_markers')
        .select()
        .eq('owner_id', ownerId)
        .eq('active', true)
        .eq('review_status', 'approved')
        .order('created_at', ascending: false);
    _check(viewerId);
    return rows.map(ArMarker.new).where((m) => m.isPublic).toList();
  }

  @override
  Future<ArMarker?> getPublic(String viewerId, String id) async {
    _check(viewerId);
    validateMarkerId(id);
    final row = await client
        .from('ar_markers')
        .select()
        .eq('id', id)
        .eq('active', true)
        .eq('review_status', 'approved')
        .maybeSingle();
    _check(viewerId);
    final marker = row == null ? null : ArMarker(row);
    return marker?.isPublic == true ? marker : null;
  }

  @override
  Future<Uint8List> loadPublicImage(String viewerId, ArMarker marker) async {
    final current = await getPublic(viewerId, marker.id);
    if (current == null ||
        current.referenceVersion != marker.referenceVersion ||
        current.referencePath == null) {
      throw MarkerUnavailable();
    }
    final bytes = await client.storage
        .from(_bucket)
        .download(current.referencePath!);
    final latest = await getPublic(viewerId, marker.id);
    if (latest == null || latest.referenceVersion != current.referenceVersion) {
      throw MarkerUnavailable();
    }
    validateMarkerImage(bytes);
    return bytes;
  }

  @override
  Future<ArMarker> copyLocal(
    String ownerId,
    ArMarker marker,
    Uint8List image,
  ) async {
    _check(ownerId);
    if (!marker.isLocal || marker.ownerId != ownerId) {
      throw StateError('El marcador ya no está disponible.');
    }
    final id = marker.id;
    final existing = await get(ownerId, id);
    if (existing != null) return existing;
    final values = markerEditableValues(marker.data);
    validateMarkerImage(image);
    final localVersion = marker.referenceVersion;
    validateMarkerId(localVersion);
    final path = '$ownerId/$id/$localVersion.jpg';
    final bucket = client.storage.from(_bucket);
    try {
      await bucket.uploadBinary(
        path,
        image,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
    } catch (_) {
      // A previous attempt may have uploaded this exact immutable reference.
      _check(ownerId);
      if (!await bucket.exists(path)) rethrow;
    }
    _check(ownerId);
    try {
      final row = await client
          .from('ar_markers')
          .insert({
            'id': id,
            'owner_id': ownerId,
            ...values,
            'reference_path': path,
          })
          .select()
          .single();
      _check(ownerId);
      return ArMarker(row);
    } catch (_) {
      // The insert may have committed or another device may have copied it.
      final recovered = await get(ownerId, id);
      if (recovered == null) rethrow;
      if (recovered.referencePath != path) {
        try {
          await client.storage.from(_bucket).remove([path]);
        } catch (_) {
          // A failed cleanup does not undo the existing marker.
        }
      }
      _check(ownerId);
      return recovered;
    }
  }

  @override
  Future<void> submit(String ownerId, String id) =>
      _publicationAction(ownerId, 'ar_marker_submit', id);

  @override
  Future<void> withdraw(String ownerId, String id) =>
      _publicationAction(ownerId, 'ar_marker_withdraw', id);

  Future<void> _publicationAction(String ownerId, String rpc, String id) async {
    _check(ownerId);
    validateMarkerId(id);
    await client.rpc(rpc, params: {'p_id': id});
    _check(ownerId);
  }

  @override
  Future<List<ArMarker>> reviewQueue(
    String reviewerId, {
    int offset = 0,
  }) async {
    _check(reviewerId);
    final rows = await client.rpc<List<dynamic>>(
      'ar_marker_review_queue',
      params: {'p_offset': offset},
    );
    _check(reviewerId);
    return rows
        .map((row) => ArMarker(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<Uint8List> loadReviewImage(String reviewerId, ArMarker marker) async {
    _check(reviewerId);
    if (!marker.awaitingReview || marker.referencePath == null) {
      throw StateError('El marcador ya no está en revisión.');
    }
    final bytes = await client.storage
        .from(_bucket)
        .download(marker.referencePath!);
    _check(reviewerId);
    validateMarkerImage(bytes);
    return bytes;
  }

  @override
  Future<void> review(
    String reviewerId,
    ArMarker marker, {
    required bool approve,
    String? reason,
  }) async {
    _check(reviewerId);
    await client.rpc(
      'ar_marker_review',
      params: {
        'p_id': marker.id,
        'p_updated_at': marker.updatedAt,
        'p_approve': approve,
        'p_reason': reason,
      },
    );
    _check(reviewerId);
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
