import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/config/map_tile_configuration.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/presentation/mission_map_marker.dart';

/// Owns tile loading and marker layers; discovery requests live in the controller.
class MissionMapCanvas extends StatefulWidget {
  const MissionMapCanvas({
    required this.controller,
    required this.initialCenter,
    required this.onReady,
    required this.onPositionChanged,
    required this.onMapTap,
    required this.missions,
    required this.selectedId,
    required this.onMissionTap,
    required this.position,
    required this.tiles,
    required this.onClusterTap,
    required this.tileRevision,
    required this.onTileError,
    super.key,
  });
  final MapController controller;
  final LatLng initialCenter;
  final VoidCallback onReady, onMapTap, onClusterTap, onTileError;
  final void Function(MapCamera, bool) onPositionChanged;
  final ValueChanged<String> onMissionTap;
  final List<Mission> missions;
  final String? selectedId;
  final DevicePosition? position;
  final MapTileConfiguration tiles;
  final int tileRevision;
  @override
  State<MissionMapCanvas> createState() => _MissionMapCanvasState();
}

class _MissionMapCanvasState extends State<MissionMapCanvas> {
  late NetworkTileProvider _tiles = NetworkTileProvider();
  List<Marker> _markers = [];
  @override
  void initState() {
    super.initState();
    _rebuildMarkers();
  }

  @override
  void didUpdateWidget(MissionMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.missions != oldWidget.missions ||
        widget.selectedId != oldWidget.selectedId) {
      _rebuildMarkers();
    }
    if (widget.tileRevision != oldWidget.tileRevision) {
      _tiles = NetworkTileProvider();
    }
  }

  void _rebuildMarkers() {
    _markers = [
      for (final mission in widget.missions)
        if (mission.coordinates != null)
          Marker(
            key: ValueKey(mission.id),
            width: 48,
            height: 48,
            point: LatLng(
              mission.coordinates!.latitude,
              mission.coordinates!.longitude,
            ),
            child: MissionMapMarker(
              mission: mission,
              selected: mission.id == widget.selectedId,
              onTap: () => widget.onMissionTap(mission.id),
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: widget.onReady,
        onPositionChanged: widget.onPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, _) => widget.onMapTap(),
      ),
      children: [
        TileLayer(
          key: ValueKey(widget.tileRevision),
          urlTemplate: widget.tiles.urlTemplate,
          userAgentPackageName: 'com.marea.app',
          tileProvider: _tiles,
          maxNativeZoom: 19,
          errorTileCallback: (_, _, _) => widget.onTileError(),
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            markers: _markers,
            markerChildBehavior: true,
            maxClusterRadius: 48,
            size: const Size(48, 48),
            maxZoom: 19,
            disableClusteringAtZoom: 20,
            centerMarkerOnClick: false,
            showPolygon: false,
            spiderfyCluster: true,
            padding: const EdgeInsets.fromLTRB(60, 160, 60, 120),
            onClusterTap: (_) => widget.onClusterTap(),
            animationsOptions: const AnimationsOptions(
              zoom: Duration(milliseconds: 250),
              fitBound: Duration(milliseconds: 250),
              spiderfy: Duration(milliseconds: 180),
            ),
            builder: (_, group) => MissionMapCluster(count: group.length),
          ),
        ),
        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position.latitude, position.longitude),
                width: 28,
                height: 28,
                child: Semantics(
                  label: 'Tu ubicación',
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.actionBlue,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x550D4397), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
