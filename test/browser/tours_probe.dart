// Isolated visual harness: real routes/widgets, no cloud writes or AR simulation.
// flutter run -d web-server -t test/browser/tours_probe.dart --web-port 7368
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image/image.dart' as image;
import 'package:http/http.dart' as http;
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';

const pilotOrigin = String.fromEnvironment('TOUR_PILOT_ORIGIN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final tours = _Tours();
  // Optional OFFLINE snapshot of a real hosted publication produced by Docker.
  // Remote permissions are separately tested by check_live.py; no physical AR.
  if (pilotOrigin.isNotEmpty) {
    final response = await http.get(
      Uri.parse('$pilotOrigin/published-view.json'),
    );
    if (response.statusCode != 200) {
      throw StateError('Pilot snapshot unavailable');
    }
    tours.record = TourRecord(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    tours.url = '$pilotOrigin/remote-panorama.jpg';
  }
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    legalRepository: FakeLegalRepository(),
    communityRepository: MissionRepositoryFake(),
    tourRepository: tours,
  );
  await controller.initialize();
  final router = AppRouter.create(controller)..go('/tours/${tours.record.id}');
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}

class _Tours implements TourRepository {
  _Tours() {
    final texture = image.Image(width: 1024, height: 512);
    for (var y = 0; y < 512; y++) {
      for (var x = 0; x < 1024; x++) {
        texture.setPixelRgb(
          x,
          y,
          20 + (x ~/ 64 % 2) * 35,
          90 + (y ~/ 64 % 2) * 45,
          160,
        );
      }
    }
    url = 'data:image/jpeg;base64,${base64Encode(image.encodeJpg(texture))}';
  }
  late String url;
  var record = TourRecord({
    'id': 'demo',
    'owner_id': sampleProfile.id,
    'title': 'Visita 360° · prueba visual',
    'state': 'published',
    'revision_id': 'v1',
    'public_revision_id': 'v1',
    'space': {
      'name': 'Café Marea · ejemplo ficticio',
      'context': 'Entorno aislado de QA',
      'verified': true,
    },
    'document': {
      'start_scene_id': 'entrada',
      'zones': [
        for (final name in ['Entrada', 'Barra', 'Mural', 'Terraza'])
          {
            'id': name.toLowerCase(),
            'name': name,
            'scenes': [
              {
                'id': name.toLowerCase(),
                'name': 'Posición de $name',
                'panorama_path': 'fixture',
                'preview_path': 'fixture',
                'thumbnail_path': 'fixture',
                'initial_yaw': 0,
                'connections': [
                  {
                    'id': 'to-barra',
                    'label': name == 'Barra' ? 'Entrada' : 'Barra',
                    'instruction': name == 'Barra'
                        ? 'Vuelve hacia la entrada.'
                        : 'Avanza hacia la barra central.',
                    'target_scene_id': name == 'Barra' ? 'entrada' : 'barra',
                    'yaw': 50,
                    'pitch': 0,
                  },
                ],
                'points': [
                  {
                    'id': 'p-${name.toLowerCase()}',
                    'name': 'Historia de $name',
                    'description':
                        'Contenido de ejemplo solo para revisar la interfaz.',
                    'yaw': 0,
                    'pitch': 0,
                  },
                ],
              },
            ],
          },
      ],
      'ar_order': [],
    },
  });
  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async => [record];
  @override
  Future<List<TourRecord>> publicList(String owner) async => [record];
  @override
  Future<TourRecord?> get(String id, {bool edit = false}) async => record;
  @override
  Future<String> assetUrl(String path) async => url;
  @override
  Future<TourProgress> progress(
    String tour,
    String version, {
    TourProgress? save,
  }) async => save ?? TourProgress(revisionId: version);
  @override
  Future<List<Map<String, dynamic>>> requests() async => [];
  @override
  Future<TourRecord> save(
    String? id,
    String title,
    Map<String, dynamic> space,
    TourDocument document,
  ) async {
    record = TourRecord({
      ...record.data,
      'title': title,
      'space': space,
      'document': document.data,
      'state': 'draft',
    });
    return record;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
