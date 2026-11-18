import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

/// Explores an already validated spherical import without a remote asset URL.
class LocalPanoramaViewer extends StatelessWidget {
  const LocalPanoramaViewer({
    required this.bytes,
    this.onViewChanged,
    super.key,
  });

  final Uint8List bytes;
  final void Function(double yaw, double pitch, double tilt)? onViewChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Desliza para mirar alrededor, hacia el techo y el piso.'),
      ),
      Expanded(
        child: ClipRect(
          child: PanoramaViewer(
            key: const Key('local-panorama-sphere'),
            sensorControl: SensorControl.none,
            onViewChanged: onViewChanged,
            child: Image.memory(bytes, gaplessPlayback: true),
          ),
        ),
      ),
    ],
  );
}
