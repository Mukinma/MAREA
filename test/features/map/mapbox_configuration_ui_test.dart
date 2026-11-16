import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/maps/mapbox_surface.dart';

void main() {
  testWidgets(
    'missing token stays local to the map and never creates an SDK view',
    (tester) async {
      final controller = MapSurfaceController();
      var ready = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Contenido de MAREA'),
                Expanded(
                  child: MareaMapSurface(
                    options: MapSurfaceOptions(
                      controller: controller,
                      initialCenter: const LatLng(19.4326, -99.1332),
                      onReady: () => ready = true,
                      onIdle: () {},
                      onGesture: () {},
                      onTap: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.textContaining('El mapa necesita configurar Mapbox'),
        findsOneWidget,
      );
      expect(find.text('Contenido de MAREA'), findsOneWidget);
      expect(find.byType(mb.MapWidget), findsNothing);
      expect(ready, isFalse);
      expect(controller.isAttached, isFalse);
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );
}
