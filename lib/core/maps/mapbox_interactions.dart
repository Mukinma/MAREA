import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'mapbox_style.dart';

void registerMareaPointInteractions(
  mb.MapboxMap map, {
  required ValueChanged<String?> onTap,
  required ValueChanged<String?> onLongTap,
  bool isWeb = kIsWeb,
}) {
  map.removeInteraction('marea-points-tap');
  map.addInteraction(
    mb.TapInteraction(
      mb.FeaturesetDescriptor(layerId: MareaMapboxStyle.symbols),
      (feature, _) => onTap(feature.properties['entity_id'] as String?),
      radius: 24,
    ),
    interactionID: 'marea-points-tap',
  );
  // SDK 3.34.2 throws for LongTapInteraction on Web. Hover tooltips are
  // handled by the Flutter surface; never prevent style setup for this API.
  if (isWeb) return;
  map.removeInteraction('marea-points-long-tap');
  map.addInteraction(
    mb.LongTapInteraction(
      mb.FeaturesetDescriptor(layerId: MareaMapboxStyle.symbols),
      (feature, _) => onLongTap(feature.properties['entity_id'] as String?),
    ),
    interactionID: 'marea-points-long-tap',
  );
}
