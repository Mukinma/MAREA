import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:marea/features/community/models/community_models.dart';

class MapBounds {
  const MapBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
  final double south, west, north, east;
  bool get isValid =>
      [south, west, north, east].every((v) => v.isFinite) &&
      south >= -90 &&
      north <= 90 &&
      south < north &&
      west >= -180 &&
      west <= 180 &&
      east >= -180 &&
      east <= 180 &&
      longitudeSpan > 0;
  double get latitudeSpan => north - south;
  double get longitudeSpan => east >= west ? east - west : 360 - west + east;
  LatLng get center =>
      LatLng((south + north) / 2, normalizeLongitude(west + longitudeSpan / 2));
  static double normalizeLongitude(double value) => (value + 180) % 360 - 180;

  bool changedSignificantly(MapBounds next) {
    final latitudeShift = (center.latitude - next.center.latitude).abs();
    final raw = (center.longitude - next.center.longitude).abs();
    final longitudeShift = math.min(raw, 360 - raw);
    return latitudeShift >= latitudeSpan * .25 ||
        longitudeShift >= longitudeSpan * .25 ||
        (latitudeSpan - next.latitudeSpan).abs() >= latitudeSpan * .25 ||
        (longitudeSpan - next.longitudeSpan).abs() >= longitudeSpan * .25;
  }

  @override
  bool operator ==(Object other) =>
      other is MapBounds &&
      south == other.south &&
      west == other.west &&
      north == other.north &&
      east == other.east;
  @override
  int get hashCode => Object.hash(south, west, north, east);
}

enum MissionMapDate { any, today, next7Days }

class MissionMapFilters {
  const MissionMapFilters({
    this.category,
    this.radiusKm,
    this.date = MissionMapDate.any,
  });
  final String? category;
  final double? radiusKm;
  final MissionMapDate date;
  bool get isActive =>
      category != null || radiusKm != null || date != MissionMapDate.any;
  (DateTime?, DateTime?) dateRange(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    return switch (date) {
      MissionMapDate.any => (null, null),
      MissionMapDate.today => (
        start,
        DateTime(now.year, now.month, now.day + 1),
      ),
      MissionMapDate.next7Days => (
        start,
        DateTime(now.year, now.month, now.day + 7),
      ),
    };
  }

  MissionMapFilters withCategory(String? value) =>
      MissionMapFilters(category: value, radiusKm: radiusKm, date: date);
  MissionMapFilters withDate(MissionMapDate value) =>
      MissionMapFilters(category: category, radiusKm: radiusKm, date: value);
  @override
  bool operator ==(Object other) =>
      other is MissionMapFilters &&
      category == other.category &&
      radiusKm == other.radiusKm &&
      date == other.date;
  @override
  int get hashCode => Object.hash(category, radiusKm, date);
}

class MissionMapPage {
  const MissionMapPage({required this.missions, required this.total});
  final List<Mission> missions;
  final int total;
  bool get isTruncated => total > missions.length;
  factory MissionMapPage.fromJson(Map<String, dynamic> json) => MissionMapPage(
    missions: List.unmodifiable(
      (json['missions'] as List).map(
        (row) => Mission.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    ),
    total: (json['total'] as num).toInt(),
  );
}
