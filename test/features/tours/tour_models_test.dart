import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

void main() {
  test('la distancia angular cruza 359/0 sin un salto de vuelta completa', () {
    expect(normalizeYaw(359), closeTo(-1, .001));
    expect(angularDistance(359, 0, 1, 0), closeTo(2, .001));
    expect(angularDistance(0, 90, 180, 90), closeTo(0, .001));
  });
  test('captura cubre cenit, nadir y horizontal con solapamiento', () {
    final plan = CapturePlan.create(hfov: 65, vfov: 50);
    expect(plan.targets.length, lessThanOrEqualTo(96));
    expect(plan.targets.any((t) => t.pitch == 90), isTrue);
    expect(plan.targets.any((t) => t.pitch == -90), isTrue);
    for (var pitch = -90; pitch <= 90; pitch += 5) {
      for (var yaw = -180; yaw < 180; yaw += 5) {
        expect(
          plan.targets.any(
            (t) =>
                angularDistance(
                  yaw.toDouble(),
                  pitch.toDouble(),
                  t.yaw,
                  t.pitch,
                ) <
                25,
          ),
          isTrue,
        );
      }
    }
  });
  test('una posición reemplazada requiere revisar sus puntos', () {
    final doc = TourDocument.empty();
    final zone = doc.addZone('Barra');
    final scene = zone.addScene('Junto a la barra');
    final point = scene.addPoint('Cata', 'Nuestro servicio');
    point.data['yaw'] = 40.0;
    doc.attachResult(scene.id, 'job1', {'panorama_path': 'owner/new.jpg'});
    expect(point.data['yaw'], isNull);
    expect(point.data['needs_review'], isTrue);
    expect(doc.startSceneId, scene.id);
  });
  test('retomar conserva la lente y rechaza otro campo de visión', () {
    final plan = CapturePlan.create(hfov: 65, vfov: 50);
    expect(() => plan.checkLens(hfov: 65.2, vfov: 49.9), returnsNormally);
    expect(() => plan.checkLens(hfov: 90, vfov: 70), throwsStateError);
    expect(() => plan.checkLens(hfov: double.nan, vfov: 50), throwsStateError);
  });
  test('progreso pertenece a una versión y saltar no equivale a visitar', () {
    final progress = TourProgress(revisionId: 'v1');
    progress.skip('mural');
    expect(progress.visited, isEmpty);
    expect(progress.skipped, contains('mural'));
    progress.visit('mural');
    expect(progress.visited, contains('mural'));
    expect(progress.skipped, isEmpty);
    expect(progress.matches('v2'), isFalse);
  });
}
