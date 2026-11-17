import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'map_surface.dart';

class MareaMapboxStyle {
  static const source = 'marea-points';
  static const symbols = 'marea-symbols';
  static const counts = 'marea-counts';
  static String spriteId(MapSurfacePoint p) =>
      '${p.icon.codePoint}-${p.color.toARGB32()}-${p.selected}';

  static Future<void> configure(
    mb.MapboxMap map, {
    MapVisualPreset preset = MapVisualPreset.context,
  }) async {
    final rawSchema = await map.getStyleImportSchema('basemap');
    final decoded = rawSchema is String ? jsonDecode(rawSchema) : rawSchema;
    final schema = decoded is Map
        ? (decoded['properties'] is Map
              ? decoded['properties'] as Map
              : decoded)
        : const {};
    const properties = <String, Object>{
      'theme': 'faded',
      'lightPreset': 'day',
      'colorWater': '#BFEDE8',
      'colorLand': '#F7FAFC',
      'colorRoads': '#FFFFFF',
      'colorGreenspace': '#D9E5DB',
      'show3dObjects': true,
      'show3dBuildings': true,
      'show3dLandmarks': true,
      'show3dTrees': false,
      'show3dFacades': false,
      'showPointOfInterestLabels': false,
    };
    final configuration = <String, Object>{
      ...properties,
      if (preset == MapVisualPreset.discovery) ...{
        'theme': 'default',
          'colorWater': '#2CAEB6',
          'colorGreenspace': '#6F9F78',
          'colorLand': '#F1F4EE',
        'colorRoads': '#FFFFFF',
          'colorMotorways': '#E1B66D',
          'colorTrunks': '#EDD3A7',
        'showPointOfInterestLabels': true,
      },
    };
    for (final entry in configuration.entries) {
      if (schema.containsKey(entry.key)) {
        await map.setStyleImportConfigProperty(
          'basemap',
          entry.key,
          entry.value,
        );
      }
    }
    await map.addSource(
      mb.GeoJsonSource(
        id: source,
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );
    await map.addLayer(
      mb.SymbolLayer(
        id: symbols,
        sourceId: source,
        slot: 'top',
        iconImageExpression: ['get', 'sprite'],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconPitchAlignment: mb.IconPitchAlignment.VIEWPORT,
        iconRotationAlignment: mb.IconRotationAlignment.VIEWPORT,
        iconSize: 1,
        iconEmissiveStrength: 1,
      ),
    );
    await map.addLayer(
      mb.SymbolLayer(
        id: counts,
        sourceId: source,
        slot: 'top',
        filter: ['has', 'count'],
        textFieldExpression: [
          'to-string',
          ['get', 'count'],
        ],
        textSize: 16,
        textColor: Colors.white.toARGB32(),
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textPitchAlignment: mb.TextPitchAlignment.VIEWPORT,
        textRotationAlignment: mb.TextRotationAlignment.VIEWPORT,
        textEmissiveStrength: 1,
      ),
    );
  }

  static Future<void> addSprite(
    mb.MapboxMap map,
    String id, {
    MapSurfacePoint? point,
  }) async {
    const scale = 2.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    final isDeviceLocation = point?.id == '__device_location';
    if (isDeviceLocation) {
      canvas.drawCircle(
        const Offset(24, 24),
        10,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(24, 24),
        7,
        Paint()..color = const Color(0xFF0D4397),
      );
    }
    final selected = point?.selected ?? false;
    final radius = selected ? 21.0 : 19.0;
    if (!isDeviceLocation) {
      canvas.drawCircle(
        const Offset(24, 24),
        radius + 2,
        Paint()..color = selected ? const Color(0xFF102A43) : Colors.white,
      );
      canvas.drawCircle(
        const Offset(24, 24),
        radius,
        Paint()..color = point?.color ?? const Color(0xFF102A43),
      );
    }
    if (point != null && !isDeviceLocation) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(point.icon.codePoint),
          style: TextStyle(
            fontSize: 21,
            fontFamily: point.icon.fontFamily,
            package: point.icon.fontPackage,
            color: const Color(0xFF102A43),
          ),
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(24 - painter.width / 2, 24 - painter.height / 2),
      );
      painter.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(96, 96);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      await map.addImage(
        id,
        scale,
        mb.StyleImage.rgba(
          width: 96,
          height: 96,
          pixels: bytes!.buffer.asUint8List(),
        ),
      );
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}
