enum ProximityTargetKind { mission, marker }

class ProximityTarget {
  const ProximityTarget({
    required this.id,
    required this.title,
    required this.route,
    required this.latitude,
    required this.longitude,
    required this.exact,
    required this.kind,
    this.expiresAt,
  });

  final String id, title, route;
  final double latitude, longitude;
  final bool exact;
  final ProximityTargetKind kind;
  final DateTime? expiresAt;

  String get key => '${kind.name}:$id';

  bool get isValid =>
      exact &&
      title.trim().isNotEmpty &&
      validProximityCoordinates(latitude, longitude) &&
      isAllowedProximityRoute(route, kind: kind, targetId: id);
}

class ProximityFix {
  const ProximityFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude, longitude, accuracy;
  final DateTime timestamp;
}

class ProximityEncounter {
  const ProximityEncounter({
    required this.target,
    required this.distanceMeters,
    required this.occurredAt,
  });

  final ProximityTarget target;
  final double distanceMeters;
  final DateTime occurredAt;
}

bool validProximityCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

final _uuid = RegExp(
  r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
);

bool isProximityUuid(String value) {
  final match = _uuid.firstMatch(value);
  return match != null && match.start == 0 && match.end == value.length;
}

/// Local notices accept only known application routes, never arbitrary URLs.
bool isAllowedProximityRoute(
  String route, {
  ProximityTargetKind? kind,
  String? targetId,
}) {
  final uri = Uri.tryParse(route);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment) {
    return false;
  }
  final segments = uri.pathSegments;
  final mission =
      segments.length == 2 &&
      segments[0] == 'missions' &&
      isProximityUuid(segments[1]);
  final marker =
      segments.length == 3 &&
      segments[0] == 'ar-markers' &&
      isProximityUuid(segments[1]) &&
      segments[2] == 'scan';
  if (!mission && !marker) return false;
  if (kind != null &&
      (kind == ProximityTargetKind.mission ? !mission : !marker)) {
    return false;
  }
  final id = segments[1];
  if (targetId != null && targetId != id) return false;
  return route == (mission ? '/missions/$id' : '/ar-markers/$id/scan');
}
