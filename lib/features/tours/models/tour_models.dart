import 'dart:convert';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String tourId() => _uuid.v4();
double normalizeYaw(num yaw) => ((yaw + 180) % 360 - 180).toDouble();
double angularDistance(
  double yaw,
  double pitch,
  double otherYaw,
  double otherPitch,
) {
  final a = pitch * math.pi / 180, b = otherPitch * math.pi / 180;
  final dot =
      math.sin(a) * math.sin(b) +
      math.cos(a) * math.cos(b) * math.cos((yaw - otherYaw) * math.pi / 180);
  return math.acos(dot.clamp(-1, 1)) * 180 / math.pi;
}

Map<String, dynamic> jsonMap(dynamic value) => value is Map<String, dynamic>
    ? value
    : Map<String, dynamic>.from(value as Map);
List<dynamic> jsonList(dynamic value) => value is List ? value : <dynamic>[];
String tourStateLabel(String state) => switch (state) {
  'published' => 'Publicado',
  'paused' => 'Pausado',
  'in_review' || 'submitted' => 'En revisión',
  'changes_requested' || 'needs_changes' || 'rejected' => 'Requiere cambios',
  'expired' => 'Finalizado',
  _ => 'Borrador',
};

class TourRecord {
  TourRecord(this.data);
  final Map<String, dynamic> data;
  factory TourRecord.fromJson(dynamic json) => TourRecord(jsonMap(json));
  String get id => data['id'] as String;
  String get ownerId => data['owner_id'] as String;
  String get title => data['title'] as String? ?? 'Recorrido';
  String get state =>
      data['paused'] == true ? 'paused' : data['state'] as String? ?? 'draft';
  String get revisionId =>
      data['revision_id'] as String? ??
      data['draft_revision_id'] as String? ??
      '';
  String? get publicRevisionId => data['public_revision_id'] as String?;
  Map<String, dynamic> get space =>
      data['space'] as Map<String, dynamic>? ?? <String, dynamic>{};
  TourDocument get document => TourDocument(
    data['document'] as Map<String, dynamic>? ?? TourDocument.empty().data,
  );
  bool get hasAR => document.points.any(
    (p) =>
        p.ar != null && p.ar!['tested_version'] == p.ar!['reference_version'],
  );
}

class TourDocument {
  TourDocument(this.data);
  final Map<String, dynamic> data;
  factory TourDocument.empty() => TourDocument({
    'zones': <dynamic>[],
    'ar_order': <dynamic>[],
    'start_scene_id': null,
    'starts_at': null,
    'ends_at': null,
  });
  TourDocument copy() => TourDocument(jsonMap(jsonDecode(jsonEncode(data))));
  List<TourZone> get zones =>
      jsonList(data['zones']).map((z) => TourZone(jsonMap(z))).toList();
  List<TourScene> get scenes => zones.expand((z) => z.scenes).toList();
  List<TourPoint> get points => scenes.expand((s) => s.points).toList();
  String? get startSceneId => data['start_scene_id'] as String?;
  TourScene? scene(String id) => scenes.where((s) => s.id == id).firstOrNull;
  TourPoint? point(String id) => points.where((s) => s.id == id).firstOrNull;
  TourZone addZone(String name) {
    final zone = TourZone({
      'id': tourId(),
      'name': name,
      'description': '',
      'scenes': <dynamic>[],
    });
    (data['zones'] as List).add(zone.data);
    return zone;
  }

  void attachResult(String sceneId, String jobId, Map<String, dynamic> result) {
    final s = scene(sceneId);
    if (s == null) return;
    s.data.addAll({...result, 'job_id': jobId});
    for (final p in s.points) {
      p.data.addAll({'yaw': null, 'pitch': null, 'needs_review': true});
    }
    for (final c in s.connections) {
      c['needs_review'] = true;
    }
    data['start_scene_id'] ??= sceneId;
  }

  List<String> get publicationProblems {
    final issues = <String>[];
    if (scenes.isEmpty) issues.add('Agrega una posición 360°');
    if (startSceneId == null || scene(startSceneId!) == null) {
      issues.add('Elige una posición inicial');
    }
    if (scenes.any((s) => s.panoramaPath == null)) {
      issues.add('Espera a que todos los panoramas estén listos');
    }
    if (points.any((p) => p.data['needs_review'] == true)) {
      issues.add('Revisa los puntos de panoramas reemplazados');
    }
    if (scenes.any(
      (s) => s.connections.any((c) => c['needs_review'] == true),
    )) {
      issues.add('Revisa las conexiones de panoramas reemplazados');
    }
    return issues;
  }
}

class TourZone {
  TourZone(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? '';
  List<TourScene> get scenes =>
      jsonList(data['scenes']).map((s) => TourScene(jsonMap(s))).toList();
  TourScene addScene(String name) {
    final s = TourScene({
      'id': tourId(),
      'name': name,
      'initial_yaw': 0.0,
      'connections': <dynamic>[],
      'points': <dynamic>[],
    });
    (data['scenes'] as List).add(s.data);
    return s;
  }
}

class TourScene {
  TourScene(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? '';
  String? get panoramaPath => data['panorama_path'] as String?;
  String? get previewPath => data['preview_path'] as String? ?? panoramaPath;
  List<TourPoint> get points =>
      jsonList(data['points']).map((p) => TourPoint(jsonMap(p))).toList();
  List<Map<String, dynamic>> get connections =>
      jsonList(data['connections']).map(jsonMap).toList();
  TourPoint addPoint(String name, String description) {
    final p = TourPoint({
      'id': tourId(),
      'name': name,
      'description': description,
      'yaw': null,
      'pitch': null,
      'link': null,
      'ar': null,
    });
    (data['points'] as List).add(p.data);
    return p;
  }
}

class TourPoint {
  TourPoint(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? '';
  String get description => data['description'] as String? ?? '';
  double? get yaw => (data['yaw'] as num?)?.toDouble();
  double? get pitch => (data['pitch'] as num?)?.toDouble();
  Map<String, dynamic>? get link =>
      data['link'] == null ? null : jsonMap(data['link']);
  Map<String, dynamic>? get ar =>
      data['ar'] == null ? null : jsonMap(data['ar']);
}

class TourJob {
  TourJob(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get state => data['state'] as String;
  String get message =>
      data['message'] as String? ??
      switch (state) {
        'queued' => 'Esperando procesamiento',
        'running' => 'Armando tu panorama',
        'ready' => 'Panorama listo para revisar',
        'needs_recapture' => 'Necesitamos nuevas fotografías',
        'cancelled' => 'Procesamiento cancelado',
        _ => 'No pudimos procesar el panorama',
      };
  bool get terminal => !{'queued', 'running'}.contains(state);
}

class TourProgress {
  TourProgress({
    required this.revisionId,
    this.sceneId,
    Set<String>? visited,
    Set<String>? skipped,
  }) : visited = visited ?? {},
       skipped = skipped ?? {};
  final String revisionId;
  String? sceneId;
  final Set<String> visited, skipped;
  factory TourProgress.fromJson(String revision, Map<String, dynamic>? data) =>
      TourProgress(
        revisionId: data?['revision_id'] as String? ?? revision,
        sceneId: data?['scene_id'] as String?,
        visited: Set<String>.from(data?['visited'] as List? ?? []),
        skipped: Set<String>.from(data?['skipped'] as List? ?? []),
      );
  bool matches(String revision) => revisionId == revision;
  void visit(String id) {
    skipped.remove(id);
    visited.add(id);
  }

  void skip(String id) {
    if (!visited.contains(id)) skipped.add(id);
  }

  Map<String, dynamic> toJson() => {
    'revision_id': revisionId,
    'scene_id': sceneId,
    'visited': visited.toList(),
    'skipped': skipped.toList(),
  };
}
