// Test data only. No Supabase client, remote credentials or publication writes.
import 'dart:io';
import 'dart:typed_data';

import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/data/showcase_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';

import 'business_ar_reference.dart';

const businessARLocalPort = 38765;
const businessARLocalMapUrl =
    'http://127.0.0.1:$businessARLocalPort/tiles/{z}/{x}/{y}.png';
const businessARLocalOwner = 'local-qa-organizer';
const businessARLocalTour = 'local-qa-tour';
const businessARLocalPoint = 'local-qa-reference';

Never _readOnly() =>
    throw const AppFailure('Laboratorio local: los datos son de solo lectura.');

final businessARLocalProfile = CommunityProfile(
  id: businessARLocalOwner,
  fullName: 'Taller MAREA · laboratorio local',
  username: 'marea_qa_local',
  userType: UserType.business,
  bio:
      'Organizador ficticio. Cámara y reconocimiento nativos reales; '
      'datos de prueba sin conexión a producción.',
  location: 'Ciudad de México · ubicación ficticia de QA',
);

Mission businessARLocalMission({DateTime? now}) => Mission(
  id: 'local-qa-mission',
  authorId: businessARLocalOwner,
  title: 'Prueba local de realidad aumentada',
  body:
      'Selecciona esta Misión en el Mapa y pulsa Explorar en RA. '
      'Busca la lámina LAB RA 01 impresa con un ancho total de 20 cm. '
      'Esta Misión y el organizador son ficticios; no admiten escrituras.',
  category: 'arte',
  location: 'Laboratorio local MAREA · CDMX',
  startsAt: (now ?? DateTime.now()).add(const Duration(days: 3)),
  capacity: 8,
  createdAt: now ?? DateTime.now(),
  organizerName: businessARLocalProfile.fullName,
  organizerUsername: businessARLocalProfile.username,
  coordinates: const PostCoordinates(
    latitude: 19.4326,
    longitude: -99.1332,
    precision: PostLocationPrecision.approximate,
  ),
);

TourRecord businessARLocalTourRecord() => TourRecord({
  'id': businessARLocalTour,
  'owner_id': businessARLocalOwner,
  'title': 'Experiencia RA local · datos ficticios',
  'state': 'published',
  'revision_id': 'local-fixture-public-v1',
  'public_revision_id': 'local-fixture-public-v1',
  'space': {
    'name': 'Laboratorio local',
    'latitude': 19.4326,
    'longitude': -99.1332,
  },
  'document': {
    'start_scene_id': 'local-scene',
    'ar_order': [businessARLocalPoint],
    'zones': [
      {
        'id': 'local-zone',
        'name': 'Laboratorio',
        'scenes': [
          {
            'id': 'local-scene',
            'name': 'Referencia local',
            'panorama_path': 'local-reference',
            'connections': <dynamic>[],
            'points': [
              {
                'id': businessARLocalPoint,
                'name': 'Lámina LAB RA 01 · 20 cm',
                'description':
                    'Referencia de QA; reconocimiento físico pendiente.',
                'yaw': 0.0,
                'pitch': 0.0,
                'ar': {
                  'reference_path': 'local-reference',
                  'reference_version': businessARReferenceVersion,
                  // Fixture of the published contract, not a real test report.
                  'tested_version': businessARReferenceVersion,
                  'width_cm': businessARReferenceWidthCm,
                },
              },
            ],
          },
        ],
      },
    ],
  },
});

class BusinessARLocalCommunity implements CommunityRepository {
  BusinessARLocalCommunity(this.value);
  final Mission value;

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async =>
      (ids == null || ids.contains(businessARLocalOwner)) &&
          businessARLocalProfile.fullName.toLowerCase().contains(
            query.toLowerCase(),
          )
      ? [businessARLocalProfile]
      : [];

  @override
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  }) async =>
      offset == 0 &&
          (scope != 'history' || value.isExpired || value.isTerminal) &&
          (scope != 'discover' || (value.isOpen && !value.isExpired)) &&
          (authorId == null || authorId == businessARLocalOwner) &&
          value.title.toLowerCase().contains(query.toLowerCase()) &&
          (category == null || category == value.category) &&
          (targetType == null ||
              value.targetType == null ||
              targetType == value.targetType)
      ? [value]
      : [];

  @override
  Future<Mission?> mission(String id) async => id == value.id ? value : null;
  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async => [];
  @override
  Future<Set<String>> savedPostIds() async => {};
  @override
  Future<Set<String>> savedMissionIds() async => {};
  @override
  Future<List<MissionApplication>> applications({String? missionId}) async =>
      [];
  @override
  Future<List<MissionDraft>> missionDrafts() async => [];
  @override
  Future<MissionDraft?> missionDraft(String id) async => null;
  @override
  Future<CommunityPost?> post(String id) async => null;
  @override
  Future<List<Mission>> savedMissions({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) async => [];
  @override
  Future<Set<String>> missionFinalists(String missionId) async => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => _readOnly();
}

// A business profile opens its Services tab by default. Represent an empty
// catalog explicitly rather than showing a missing-repository error there.
class BusinessARLocalShowcase implements ShowcaseRepository {
  @override
  Future<List<ShowcaseItem>> items({
    String? ownerId,
    String query = '',
    String? category,
    ShowcaseKind? kind,
    bool management = false,
    bool savedOnly = false,
    int offset = 0,
  }) async => [];
  @override
  Future<ShowcaseItem?> item(String id) async => null;
  @override
  Future<Set<String>> savedIds() async => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => _readOnly();
}

class BusinessARLocalMap implements MissionMapRepository {
  BusinessARLocalMap(this.value);
  final Mission value;
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    final location = value.coordinates!;
    final (from, before) = filters.dateRange(now);
    final visible =
        value.isOpen &&
        value.startsAt.isAfter(now) &&
        location.latitude >= bounds.south &&
        location.latitude <= bounds.north &&
        (bounds.west <= bounds.east
            ? location.longitude >= bounds.west &&
                  location.longitude <= bounds.east
            : location.longitude >= bounds.west ||
                  location.longitude <= bounds.east) &&
        (filters.category == null || filters.category == value.category) &&
        (from == null || !value.startsAt.isBefore(from)) &&
        (before == null || value.startsAt.isBefore(before)) &&
        value.title.toLowerCase().contains(query.trim().toLowerCase());
    return MissionMapPage(
      missions: visible ? [value] : [],
      total: visible ? 1 : 0,
    );
  }
}

class BusinessARLocalTours implements TourRepository {
  BusinessARLocalTours(this.referenceUrl);
  final String referenceUrl;
  @override
  Future<List<TourRecord>> publicList(String owner) async =>
      owner == businessARLocalOwner ? [businessARLocalTourRecord()] : [];
  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async => owner == null || owner == businessARLocalOwner
      ? [businessARLocalTourRecord()]
      : [];
  @override
  Future<TourRecord?> get(String id, {bool edit = false}) async {
    if (edit) _readOnly();
    return id == businessARLocalTour ? businessARLocalTourRecord() : null;
  }

  @override
  Future<String> assetUrl(String path) async {
    if (path != 'local-reference') {
      throw StateError('Recurso local desconocido.');
    }
    return referenceUrl;
  }

  @override
  Future<TourProgress> progress(
    String tour,
    String revision, {
    TourProgress? save,
  }) async {
    if (save != null) _readOnly();
    return TourProgress(revisionId: revision);
  }

  @override
  Future<List<Map<String, dynamic>>> requests() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => _readOnly();
}

/// Device-local HTTP only, so production image-loading code runs unchanged.
class BusinessARLocalAssets {
  BusinessARLocalAssets._(this._server, this.reference);
  final HttpServer _server;
  final Uint8List reference;
  String get referenceUrl => 'http://127.0.0.1:${_server.port}/reference.png';
  int get port => _server.port;

  static Future<BusinessARLocalAssets> start({
    int port = businessARLocalPort,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final reference = businessARReferencePng(), tile = businessARLocalTilePng();
    server.listen((request) async {
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
      } else {
        final Uint8List? bytes = request.uri.path == '/reference.png'
            ? reference
            : request.uri.path.startsWith('/tiles/')
            ? tile
            : null;
        if (bytes == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.contentLength = bytes.length;
          if (request.method == 'GET') request.response.add(bytes);
        }
      }
      await request.response.close();
    });
    return BusinessARLocalAssets._(server, reference);
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}

/// Fail closed if a test widget accidentally requests a remote HTTP resource.
class BusinessARLoopbackOnly extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (uri.host != '127.0.0.1' ||
          uri.scheme != 'http' ||
          proxyHost != null) {
        throw StateError(
          'Laboratorio RA: conexión externa bloqueada (${uri.host}).',
        );
      }
      return Socket.startConnect(InternetAddress.loopbackIPv4, uri.port);
    };
    return client;
  }
}
