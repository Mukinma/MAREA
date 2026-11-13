import 'dart:math' as math;

import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

import '../models/proximity_models.dart';
import 'proximity_services.dart';

/// Only explicit exact locations are eligible; approximate map points are not.
class AppProximityTargets implements ProximityTargetSource {
  AppProximityTargets(this.session);
  final AppSessionController session;
  @override
  Future<List<ProximityTarget>> load(ProximityFix fix) async {
    final account = session.profile?.id;
    if (account == null) return [];
    void check() {
      if (session.profile?.id != account) throw StateError('La sesión cambió.');
    }

    final targets = <ProximityTarget>[];
    final maps = session.missionMapRepository;
    if (maps != null) {
      final page = await maps.fetch(
        bounds: MapBounds(
          south: math.max(-90, fix.latitude - .5),
          north: math.min(90, fix.latitude + .5),
          west: MapBounds.normalizeLongitude(fix.longitude - .5),
          east: MapBounds.normalizeLongitude(fix.longitude + .5),
        ),
        filters: const MissionMapFilters(),
        query: '',
        now: DateTime.now(),
      );
      check();
      for (final mission in page.missions) {
        final point = mission.coordinates;
        if (!mission.isOpen ||
            mission.isExpired ||
            point == null ||
            !point.isValid ||
            point.isApproximate) {
          continue;
        }
        targets.add(
          ProximityTarget(
            id: mission.id,
            title: mission.title,
            route: '/missions/${mission.id}',
            latitude: point.latitude,
            longitude: point.longitude,
            exact: true,
            kind: ProximityTargetKind.mission,
            expiresAt: mission.startsAt,
          ),
        );
      }
    }
    final markers = session.markerRepository;
    if (markers != null) {
      final owned = await markers.listOwned(account);
      check();
      final published = await markers.nearbyPublic(
        latitude: fix.latitude,
        longitude: fix.longitude,
      );
      check();
      final seen = <String>{};
      for (final marker in [...owned, ...published]) {
        if (!marker.active ||
            !marker.isTested ||
            !marker.locationExact ||
            marker.latitude == null ||
            marker.longitude == null ||
            !seen.add(marker.id)) {
          continue;
        }
        targets.add(
          ProximityTarget(
            id: marker.id,
            title: marker.name,
            route: '/ar-markers/${marker.id}/scan',
            latitude: marker.latitude!,
            longitude: marker.longitude!,
            exact: true,
            kind: ProximityTargetKind.marker,
          ),
        );
      }
    }
    check();
    return targets.where((target) => target.isValid).toList();
  }
}
