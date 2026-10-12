import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../data/tour_repository.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';

class TourPanorama extends StatefulWidget {
  const TourPanorama({
    required this.repository,
    required this.scene,
    this.onPoint,
    this.onConnection,
    this.onViewChanged,
    super.key,
  });
  final TourRepository repository;
  final TourScene scene;
  final ValueChanged<TourPoint>? onPoint;
  final ValueChanged<Map<String, dynamic>>? onConnection;
  final void Function(double, double)? onViewChanged;
  @override
  State<TourPanorama> createState() => _TourPanoramaState();
}

class _TourPanoramaState extends State<TourPanorama> {
  late Future<String>? _url = _load();
  bool _sensors = false;
  Future<String>? _load() => widget.scene.previewPath == null
      ? null
      : widget.repository.assetUrl(widget.scene.previewPath!);
  @override
  void didUpdateWidget(TourPanorama old) {
    super.didUpdateWidget(old);
    if (old.scene.previewPath != widget.scene.previewPath) {
      _url = _load();
      _sensors = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const Center(
        child: TourNotice('Esta posición todavía no tiene un panorama listo.'),
      );
    }
    return FutureBuilder<String>(
      future: _url,
      builder: (c, s) {
        if (s.hasError) {
          return Center(
            child: TourNotice(
              tourError(s.error!),
              onRetry: () => setState(() => _url = _load()),
            ),
          );
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: PanoramaViewer(
                    key: ValueKey(
                      '${widget.scene.id}:${widget.scene.previewPath}',
                    ),
                    longitude:
                        (widget.scene.data['initial_yaw'] as num?)
                            ?.toDouble() ??
                        0,
                    sensorControl: _sensors
                        ? SensorControl.orientation
                        : SensorControl.none,
                    onViewChanged: (yaw, pitch, tilt) => widget.onViewChanged
                        ?.call(normalizeYaw(yaw), pitch.clamp(-90, 90)),
                    hotspots: [
                      for (final p in widget.scene.points)
                        if (p.yaw != null &&
                            p.pitch != null &&
                            p.data['needs_review'] != true)
                          Hotspot(
                            longitude: p.yaw!,
                            latitude: p.pitch!,
                            width: 48,
                            height: 48,
                            widget: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => widget.onPoint?.call(p),
                              child: const Icon(Icons.info_outline),
                            ),
                          ),
                      for (final connection in widget.scene.connections)
                        if (connection['yaw'] != null &&
                            connection['needs_review'] != true)
                          Hotspot(
                            longitude: (connection['yaw'] as num).toDouble(),
                            latitude:
                                (connection['pitch'] as num?)?.toDouble() ?? 0,
                            width: 48,
                            height: 48,
                            widget: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () =>
                                  widget.onConnection?.call(connection),
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ),
                    ],
                    child: Image.network(
                      s.data!,
                      errorBuilder: (_, e, st) => const Center(
                        child: Text('No pudimos abrir el panorama.'),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton.filled(
                  tooltip: _sensors
                      ? 'Mirar arrastrando'
                      : 'Mirar con el movimiento del teléfono',
                  onPressed: kIsWeb
                      ? null
                      : () => setState(() => _sensors = !_sensors),
                  icon: Icon(
                    _sensors ? Icons.touch_app : Icons.screen_rotation,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<(double, double)?> pickPanoramaPosition(
  BuildContext context,
  TourRepository repository,
  TourScene scene,
) async {
  double yaw = (scene.data['initial_yaw'] as num?)?.toDouble() ?? 0, pitch = 0;
  return Navigator.of(context).push<(double, double)>(
    MaterialPageRoute(
      builder: (c) => Scaffold(
        appBar: AppBar(title: const Text('Colocar punto')),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mira hacia el lugar del punto y pulsa Colocar aquí. También puedes dejarlo solo en la lista.',
              ),
            ),
            Expanded(
              child: TourPanorama(
                repository: repository,
                scene: scene,
                onViewChanged: (y, p) {
                  yaw = y;
                  pitch = p;
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(c, (yaw, pitch)),
                  child: const Text('Colocar aquí'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
