import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../tours/data/tour_local_store.dart';
import '../models/ar_marker.dart';
import 'marker_repository.dart';

/// Persistent private markers: metadata and image are one atomic local record.
class LocalMarkerRepository implements MarkerRepository {
  LocalMarkerRepository({TourLocalStore? localStore, this.currentOwner})
    : _store = localStore ?? TourLocalStore();

  final TourLocalStore _store;
  final String? Function()? currentOwner;
  static final _tails = <String, Future<void>>{};
  static const _uuid = Uuid();
  static const _index = 'ar-markers';

  void _check(String owner) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(owner) ||
        (currentOwner != null && currentOwner!() != owner)) {
      throw StateError('La sesión cambió. Vuelve a abrir tus marcadores.');
    }
  }

  Future<T> _serial<T>(String owner, Future<T> Function() action) {
    final previous = _tails[owner] ?? Future<void>.value();
    final operation = previous.then((_) {
      _check(owner);
      return action();
    });
    final tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[owner] = tail;
    unawaitedCleanup(owner, tail);
    return operation;
  }

  void unawaitedCleanup(String owner, Future<void> tail) {
    tail.then((_) {
      if (identical(_tails[owner], tail)) _tails.remove(owner);
    });
  }

  Future<Map<String, dynamic>?> _read(String owner, String id) async {
    _check(owner);
    validateMarkerId(id);
    final row = await _store.read(owner, 'ar-marker-$id');
    _check(owner);
    if (row == null || row['deleted'] == true) return null;
    if (row['id'] != id || row['owner_id'] != owner) {
      throw StateError('El marcador no pertenece a esta cuenta.');
    }
    return row;
  }

  ArMarker _model(Map<String, dynamic> row) =>
      ArMarker({...row}..remove('image_base64'));

  @override
  Future<List<ArMarker>> listOwned(String ownerId) =>
      _serial(ownerId, () async {
        final index = await _store.read(ownerId, _index);
        _check(ownerId);
        final result = <ArMarker>[];
        for (final id in (index?['ids'] as List? ?? const [])) {
          if (id is! String) continue;
          final row = await _read(ownerId, id);
          if (row != null) result.add(_model(row));
        }
        return result;
      });

  @override
  Future<List<ArMarker>> nearbyPublic({
    double? latitude,
    double? longitude,
  }) async => [];

  @override
  Future<ArMarker?> get(String ownerId, String id) =>
      _serial(ownerId, () async {
        final row = await _read(ownerId, id);
        return row == null ? null : _model(row);
      });

  @override
  Future<ArMarker> save(
    String ownerId,
    Map<String, dynamic> values, {
    Uint8List? imageBytes,
  }) => _serial(ownerId, () async {
    final id = values['id'] as String? ?? _uuid.v4();
    final previous = await _read(ownerId, id);
    if (values['id'] != null && previous == null) {
      throw StateError('El marcador ya no está disponible.');
    }
    final editable = markerEditableValues({...?previous, ...values});
    if (previous == null && imageBytes == null) {
      throw StateError('Añade la imagen que reconocerá la cámara.');
    }
    if (imageBytes != null) validateMarkerImage(imageBytes);
    final changed =
        previous == null ||
        imageBytes != null ||
        previous['width_cm'] != editable['width_cm'];
    final version = changed
        ? _uuid.v4()
        : previous['reference_version'] as String;
    final locationChanged =
        previous != null &&
        [
          'latitude',
          'longitude',
          'location_exact',
          'location_accuracy',
        ].any((key) => previous[key] != editable[key]);
    final row = <String, dynamic>{
      ...?previous,
      ...editable,
      'id': id,
      'owner_id': ownerId,
      'storage': 'local',
      'reference_version': version,
      'reference_path': 'local:$id:$version',
      'tested_version': changed ? null : previous['tested_version'],
      'active': false,
      'review_status': 'pending',
      'image_base64': imageBytes == null
          ? previous!['image_base64']
          : base64Encode(imageBytes),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final activate =
        !changed &&
        (values['active'] == true ||
            (!locationChanged &&
                values['active'] == null &&
                previous['active'] == true));
    if (activate) {
      final marker = _model(row);
      if (!marker.isTested ||
          !marker.locationExact ||
          marker.latitude == null ||
          marker.locationAccuracy == null ||
          marker.locationAccuracy! > 20) {
        throw StateError(
          'Prueba la imagen y guarda una ubicación exacta con precisión de hasta 20 metros antes de activar el aviso.',
        );
      }
      row['active'] = true;
    }
    _check(ownerId);
    await _store.write(ownerId, 'ar-marker-$id', row);
    if (previous == null) {
      try {
        _check(ownerId);
        final index = await _store.read(ownerId, _index);
        final ids =
            (index?['ids'] as List? ?? const []).whereType<String>().toSet()
              ..add(id);
        _check(ownerId);
        await _store.write(ownerId, _index, {'ids': ids.toList()});
      } catch (_) {
        await _store.write(ownerId, 'ar-marker-$id', {
          'id': id,
          'owner_id': ownerId,
          'deleted': true,
          'image_base64': null,
        });
        rethrow;
      }
    }
    _check(ownerId);
    return _model(row);
  });

  @override
  Future<void> delete(String ownerId, String id) => _serial(ownerId, () async {
    final row = await _read(ownerId, id);
    if (row == null) return;
    _check(ownerId);
    await _store.write(ownerId, 'ar-marker-$id', {
      'id': id,
      'owner_id': ownerId,
      'deleted': true,
      'image_base64': null,
    });
    final index = await _store.read(ownerId, _index);
    _check(ownerId);
    await _store.write(ownerId, _index, {
      'ids': (index?['ids'] as List? ?? const [])
          .where((entry) => entry != id)
          .toList(),
    });
  });

  @override
  Future<Uint8List> loadImage(String ownerId, ArMarker marker) => _serial(
    ownerId,
    () async {
      if (marker.ownerId != ownerId) {
        throw StateError('El marcador no pertenece a esta cuenta.');
      }
      final row = await _read(ownerId, marker.id);
      if (row == null || row['reference_version'] != marker.referenceVersion) {
        throw StateError('La imagen cambió. Abre de nuevo el marcador.');
      }
      final encoded = row['image_base64'];
      if (encoded is! String || encoded.isEmpty) {
        throw StateError('La imagen ya no está disponible.');
      }
      return base64Decode(encoded);
    },
  );

  @override
  Future<ArMarker> confirmRecognition(
    String ownerId,
    String id,
    String referenceVersion,
    String platform,
    int seconds,
  ) => _serial(ownerId, () async {
    validateMarkerRecognition(platform, seconds);
    final row = await _read(ownerId, id);
    if (row == null || row['reference_version'] != referenceVersion) {
      throw StateError(
        'La referencia cambió. Reconoce de nuevo la imagen actual.',
      );
    }
    final updated = {
      ...row,
      'tested_version': referenceVersion,
      'test_platform': platform,
      'tracking_seconds': seconds,
    };
    _check(ownerId);
    await _store.write(ownerId, 'ar-marker-$id', updated);
    _check(ownerId);
    return _model(updated);
  });
}
