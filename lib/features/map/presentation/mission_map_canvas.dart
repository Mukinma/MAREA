import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/maps/mapbox_surface.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/presentation/mission_map_marker.dart';

class MissionMapCanvas extends StatelessWidget {
  const MissionMapCanvas({
    required this.controller,
    required this.initialCenter,
    required this.onReady,
    required this.onIdle,
    required this.onGesture,
    required this.onMapTap,
    required this.onClusterTap,
    required this.missions,
    required this.selectedId,
    required this.onMissionTap,
    required this.position,
    this.tourMarkers = const [],
    this.ornamentBottom = 12,
    super.key,
  });
  final MapSurfaceController controller;
  final LatLng initialCenter;
  final VoidCallback onReady, onIdle, onGesture, onMapTap;
  final VoidCallback onClusterTap;
  final ValueChanged<String> onMissionTap;
  final List<Mission> missions;
  final List<MapSurfacePoint> tourMarkers;
  final String? selectedId;
  final DevicePosition? position;
  final double ornamentBottom;

  @override
  Widget build(BuildContext context) => MareaMapSurface(
    options: MapSurfaceOptions(
      controller: controller,
      initialCenter: initialCenter,
      pitch: 45,
      preset: MapVisualPreset.discovery,
      onReady: onReady,
      onIdle: onIdle,
      onGesture: onGesture,
      onTap: (_) => onMapTap(),
      onClusterTap: onClusterTap,
      ornamentBottom: ornamentBottom,
      points: [
        for (final mission in missions)
          if (mission.coordinates?.isValid ?? false)
            MapSurfacePoint(
              id: mission.id,
              position: LatLng(
                mission.coordinates!.latitude,
                mission.coordinates!.longitude,
              ),
              label: mission.title,
              semanticsLabel:
                  '${communityCategories[mission.category] ?? 'Otros'}: ${mission.title}',
              icon: CategoryVisuals.forCategory(mission.category).icon,
              color: CategoryVisuals.forCategory(mission.category).color,
              selected: mission.id == selectedId,
              onTap: () => onMissionTap(mission.id),
              expandedBuilder: (_) => MissionMapMarker(
                mission: mission,
                selected: mission.id == selectedId,
                onTap: () => onMissionTap(mission.id),
              ),
            ),
        ...tourMarkers,
        if (position != null)
          MapSurfacePoint(
            id: '__device_location',
            position: LatLng(position!.latitude, position!.longitude),
            label: 'Tu ubicación',
            color: const Color(0xFF2EC4B6),
            icon: Icons.my_location,
            clusterable: false,
          ),
      ],
    ),
  );
}
