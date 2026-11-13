import 'dart:math' as math;
import 'package:marea/features/proximity/models/proximity_models.dart';

const accountA = '11111111-1111-4111-8111-111111111111';
const accountB = '22222222-2222-4222-8222-222222222222';
const targetId = '33333333-3333-4333-8333-333333333333';
final testTime = DateTime.utc(2026, 11, 12, 12);

ProximityTarget target({
  bool exact = true,
  ProximityTargetKind kind = ProximityTargetKind.mission,
  String id = targetId,
  String? route,
  double latitude = 0,
  double longitude = 0,
}) => ProximityTarget(
  id: id,
  title: 'Lugar de prueba',
  route:
      route ??
      (kind == ProximityTargetKind.mission
          ? '/missions/$id'
          : '/ar-markers/$id/scan'),
  latitude: latitude,
  longitude: longitude,
  exact: exact,
  kind: kind,
);

ProximityFix fix({
  double meters = 0,
  double accuracy = 5,
  DateTime? timestamp,
}) {
  return ProximityFix(
    latitude: meters / 6371000 * 180 / math.pi,
    longitude: 0,
    accuracy: accuracy,
    timestamp: timestamp ?? testTime,
  );
}

ProximityEncounter encounter({ProximityTarget? destination}) =>
    ProximityEncounter(
      target: destination ?? target(),
      distanceMeters: 5,
      occurredAt: testTime,
    );
