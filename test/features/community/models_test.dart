import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Profile capabilities', () {
    test('all account types can participate in community', () {
      for (final type in UserType.values) {
        expect(type.postKinds, contains(PostKind.community));
        expect(type.headline, isNotEmpty);
        expect(type.description, isNotEmpty);
      }
    });

    test('account types have distinct publishing capabilities', () {
      expect(UserType.general.postKinds, [PostKind.community]);
      expect(UserType.creator.postKinds, [
        PostKind.community,
        PostKind.project,
      ]);
      expect(UserType.entrepreneur.postKinds, [
        PostKind.community,
        PostKind.product,
        PostKind.service,
      ]);
      expect(UserType.business.postKinds, [
        PostKind.community,
        PostKind.space,
        PostKind.event,
      ]);
      expect(UserType.creator.showcaseLabel, 'Portafolio');
      expect(
        () => UserType.general.postKinds.add(PostKind.product),
        throwsUnsupportedError,
      );
    });
  });

  group('Post input', () {
    PostInput input({
      PostKind kind = PostKind.community,
      String title = 'Mi proyecto',
      String body = 'Una descripción.',
      String category = 'arte',
      double? price,
      String? location,
      PostCoordinates? coordinates,
    }) => PostInput(
      kind: kind,
      title: title,
      body: body,
      category: category,
      price: price,
      location: location,
      coordinates: coordinates,
    );

    test('validates the capability against the account type', () {
      final project = input(kind: PostKind.project);
      expect(project.validate(userType: UserType.creator), isNull);
      expect(project.validate(userType: UserType.general), isNotNull);
      expect(project.validate(userType: UserType.business), isNotNull);
    });

    test('validates trimmed SQL text boundaries and categories', () {
      expect(input(title: ' a ').validate(), isNotNull);
      expect(input(title: 'a' * 100, body: 'b').validate(), isNull);
      expect(input(title: 'a' * 101).validate(), isNotNull);
      expect(input(body: ' ').validate(), isNotNull);
      expect(input(body: 'b' * 3000).validate(), isNull);
      expect(input(body: 'b' * 3001).validate(), isNotNull);
      expect(input(category: 'otros').validate(), isNull);
      expect(input(category: 'unknown').validate(), isNotNull);
      expect(input(location: 'a' * 180).validate(), isNull);
      expect(input(location: 'a' * 181).validate(), isNotNull);
    });

    test(
      'spaces and events require location and only commercial posts accept price',
      () {
        for (final kind in [PostKind.space, PostKind.event]) {
          expect(input(kind: kind).validate(), isNotNull);
          expect(input(kind: kind, location: ' ').validate(), isNotNull);
          expect(input(kind: kind, location: 'Centro').validate(), isNull);
        }
        expect(input(price: 100).validate(), isNotNull);
        expect(input(kind: PostKind.project, price: 100).validate(), isNotNull);
        expect(input(kind: PostKind.service, price: 100).validate(), isNull);
      },
    );

    test('rejects negative, nonfinite and excessive prices', () {
      for (final price in [-1.0, double.nan, double.infinity, 100000000.0]) {
        expect(
          input(kind: PostKind.product, price: price).validate(),
          isNotNull,
        );
      }
      expect(input(kind: PostKind.product, price: 0).validate(), isNull);
      expect(input(kind: PostKind.product, price: 99999999).validate(), isNull);
    });

    test(
      'JSON normalizes text without allowing author or moderation changes',
      () {
        final json = input(
          title: ' Mi proyecto ',
          body: ' descripción ',
          location: ' ',
        ).toJson();
        expect(json['title'], 'Mi proyecto');
        expect(json['body'], 'descripción');
        expect(json['location'], isNull);
        expect(
          json.keys,
          unorderedEquals([
            'kind',
            'title',
            'body',
            'category',
            'location',
            'location_latitude',
            'location_longitude',
            'location_precision',
            'price',
            'image_path',
          ]),
        );
      },
    );

    test('serializes valid exact and approximate coordinates', () {
      const coordinates = PostCoordinates(
        latitude: 19.4326,
        longitude: -99.1332,
        precision: PostLocationPrecision.exact,
      );
      final json = input(location: 'Centro', coordinates: coordinates).toJson();
      expect(json['location_latitude'], 19.4326);
      expect(json['location_longitude'], -99.1332);
      expect(json['location_precision'], 'exact');
      expect(
        input(location: 'Centro', coordinates: coordinates).validate(),
        isNull,
      );
      expect(
        input(
          location: 'Centro',
          coordinates: const PostCoordinates(
            latitude: 91,
            longitude: 0,
            precision: PostLocationPrecision.approximate,
          ),
        ).validate(),
        isNotNull,
      );
    });
  });

  group('Mission input', () {
    final now = DateTime.utc(2030, 1, 1);
    MissionInput input({
      int capacity = 2,
      DateTime? start,
      String location = 'Centro',
      UserType? target,
    }) => MissionInput(
      title: 'Una colaboración',
      body: 'Descripción',
      category: 'musica',
      location: location,
      startsAt: start ?? now.add(const Duration(days: 1)),
      capacity: capacity,
      targetType: target,
    );

    test('requires future start, location, and bounded capacity', () {
      expect(input().validate(now: now), isNull);
      expect(input(start: now).validate(now: now), isNotNull);
      expect(
        input(
          start: now.subtract(const Duration(seconds: 1)),
        ).validate(now: now),
        isNotNull,
      );
      expect(input(location: ' ').validate(now: now), isNotNull);
      expect(input(capacity: 0).validate(now: now), isNotNull);
      expect(input(capacity: 101).validate(now: now), isNotNull);
      expect(input(capacity: 100).validate(now: now), isNull);
    });

    test('sends database target type and UTC timestamp', () {
      final json = input(target: UserType.creator).toJson();
      expect(json['target_type'], 'Artista / creador');
      expect(json['starts_at'], '2030-01-02T00:00:00.000Z');
      expect(input().toJson()['target_type'], isNull);
      expect(json.containsKey('author_id'), isFalse);
    });
  });

  group('Parsing database rows', () {
    const date = '2030-01-01T00:00:00Z';
    test('public profiles do not depend on private profile fields', () {
      final profile = CommunityProfile.fromJson({
        'id': 'p',
        'full_name': '  Ana María Sol ',
        'username': 'ana',
        'user_type': 'Negocio',
        'bio': null,
        'website': null,
      });
      expect(profile.initials, 'AS');
      expect(profile.userType, UserType.business);
      expect(profile.bio, isNull);
      expect(
        const CommunityProfile(
          id: 'a',
          fullName: ' ',
          username: 'u',
          userType: UserType.general,
        ).initials,
        'M',
      );
    });

    test('post accepts integer or fractional numeric prices', () {
      final json = <String, dynamic>{
        'id': 'p',
        'author_id': 'a',
        'kind': 'product',
        'title': 'Producto',
        'body': 'Descripción',
        'category': 'arte',
        'price': 50,
        'created_at': date,
        'updated_at': date,
      };
      expect(CommunityPost.fromJson(json).price, 50.0);
      expect(CommunityPost.fromJson({...json, 'price': 20.5}).price, 20.5);
      expect(CommunityPost.fromJson({...json, 'price': null}).price, isNull);
      expect(CommunityPost.fromJson(json).createdAt.isUtc, isTrue);
      expect(
        () => CommunityPost.fromJson({...json, 'kind': 'admin'}),
        throwsStateError,
      );
    });

    test('mission parses optional audience and availability', () {
      final json = <String, dynamic>{
        'id': 'm',
        'author_id': 'a',
        'title': 'Misión',
        'body': 'Texto',
        'category': 'arte',
        'location': 'Centro',
        'starts_at': date,
        'capacity': 3,
        'target_type': null,
        'status': 'open',
        'hidden': false,
        'created_at': date,
      };
      expect(Mission.fromJson(json).isOpen, isTrue);
      expect(Mission.fromJson(json).targetType, isNull);
      expect(Mission.fromJson({...json, 'hidden': true}).isOpen, isFalse);
      expect(Mission.fromJson({...json, 'status': 'closed'}).isOpen, isFalse);
    });

    test(
      'applications and reports preserve ownership and moderation state',
      () {
        final application = MissionApplication.fromJson({
          'id': 'a',
          'mission_id': 'm',
          'applicant_id': 'u',
          'message': 'Quiero participar',
          'status': 'accepted',
          'created_at': date,
        });
        expect(application.applicantId, 'u');
        expect(application.status, 'accepted');
        final report = ContentReport.fromJson({
          'id': 'r',
          'reporter_id': 'u',
          'post_id': null,
          'mission_id': 'm',
          'reason': 'Contenido engañoso',
          'state': 'open',
          'created_at': date,
        });
        expect(report.missionId, 'm');
        expect(report.postId, isNull);
      },
    );
  });

  group('Repository failures', () {
    test('backend errors become actionable messages', () {
      expect(communityFailure('mission_full').message, contains('cupo'));
      expect(
        communityFailure('mission_unavailable').message,
        contains('no está disponible'),
      );
      expect(
        communityFailure('mission_owner_required').message,
        contains('permiso'),
      );
      expect(communityFailure('admin_required').message, contains('permiso'));
      expect(
        communityFailure('authentication_required').kind,
        AppFailureKind.invalidSession,
      );
      expect(communityFailure('mission_closed').message, contains('no recibe'));
      expect(
        communityFailure('PGRST205 schema cache').message,
        contains('migración'),
      );
      expect(communityFailure('42501').message, contains('permiso'));
      expect(communityFailure('kind_not_allowed').message, contains('perfil'));
    });

    test(
      'invalid actions and oversized images fail before network access',
      () async {
        final repository = SupabaseCommunityRepository(
          SupabaseClient('https://example.invalid', 'test-key'),
        );
        expect(
          repository.uploadImage(Uint8List(4 * 1024 * 1024 + 1)),
          throwsA(isA<AppFailure>()),
        );
        expect(
          repository.uploadImage(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<AppFailure>()),
        );
        expect(
          repository.report(reason: 'Reporte válido'),
          throwsA(isA<AppFailure>()),
        );
        expect(repository.review('a', 'pending'), throwsA(isA<AppFailure>()));
        expect(
          repository.setMissionStatus('m', 'deleted'),
          throwsA(isA<AppFailure>()),
        );
      },
    );
  });
}
