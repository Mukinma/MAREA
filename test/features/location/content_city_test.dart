import 'package:marea/features/location/models/location_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/community_models.dart';

void main() {
  test('post city is structured independently of its full address', () {
    final dynamic post = CommunityPost.fromJson({
      'id': 'p',
      'author_id': 'a',
      'kind': 'event',
      'title': 'Event',
      'body': 'Body',
      'category': 'otros',
      'location': 'Street, Centro, Puebla',
      'location_latitude': 19.0,
      'location_longitude': -98.0,
      'location_precision': 'exact',
      'location_city': {
        'name': 'Puebla',
        'region': 'Puebla',
        'countryCode': 'mx',
      },
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    expect(post.city.name, 'Puebla');
    expect(post.location, 'Street, Centro, Puebla');
    expect(post.coordinates.latitude, 19);
  });
  test('legacy posts retain a missing city', () {
    final dynamic post = CommunityPost.fromJson({
      'id': 'p',
      'author_id': 'a',
      'kind': 'event',
      'title': 'Event',
      'body': 'Body',
      'category': 'otros',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    expect(post.city, isNull);
  });
  test(
    'malformed optional city fields cannot break legacy content rendering',
    () {
      expect(
        LocationCity.fromJson({'name': 'Puebla', 'region': 123})?.name,
        'Puebla',
      );
    },
  );
  test(
    'post and mission payloads preserve full point and optional structured city',
    () {
      const city = LocationCity(name: 'Puebla', countryCode: 'mx');
      const point = PostCoordinates(
        latitude: 19,
        longitude: -98,
        precision: PostLocationPrecision.exact,
      );
      final post = PostInput(
        kind: PostKind.event,
        title: 'Event',
        body: 'Body',
        category: 'otros',
        location: 'Street, Puebla',
        coordinates: point,
        city: city,
      ).toJson();
      expect(post['location_city'], {
        'name': 'Puebla',
        'countryCode': 'mx',
        'point': {'latitude': 19.0, 'longitude': -98.0},
      });
      expect(post['location'], 'Street, Puebla');
      expect(post['location_latitude'], 19);
      final mission = MissionInput(
        title: 'Mission',
        body: 'Body',
        category: 'otros',
        location: 'Street, Puebla',
        startsAt: DateTime(2027),
        capacity: 5,
        coordinates: point,
        city: city,
      ).toJson();
      expect(mission['location_city'], {
        'name': 'Puebla',
        'countryCode': 'mx',
        'point': {'latitude': 19.0, 'longitude': -98.0},
      });
      expect(mission['location_longitude'], -98);
      expect(
        const PostInput(
          kind: PostKind.event,
          title: 'Event',
          body: 'Body',
          category: 'otros',
          city: city,
        ).toJson()['location_city'],
        isNull,
      );
    },
  );
  test('legacy text-only post inputs omit absent city metadata', () {
    final json = const PostInput(
      kind: PostKind.community,
      title: 'Post',
      body: 'Body',
      category: 'otros',
      location: 'Full address',
    ).toJson();
    expect(json.containsKey('location_city'), isFalse);
    expect(json['location'], 'Full address');
  });
  test(
    'a selected point with unknown city sends an explicit null to clear stale city',
    () {
      final json = const PostInput(
        kind: PostKind.community,
        title: 'Post',
        body: 'Body',
        category: 'otros',
        location: 'Full address',
        coordinates: PostCoordinates(
          latitude: 20,
          longitude: -99,
          precision: PostLocationPrecision.exact,
        ),
      ).toJson();
      expect(json.containsKey('location_city'), isTrue);
      expect(json['location_city'], isNull);
      expect(json['location_latitude'], 20);
    },
  );
  test(
    'same-city post moves carry the exact newly resolved point in their payload',
    () {
      const city = LocationCity(name: 'Puebla');
      final json = const PostInput(
        kind: PostKind.community,
        title: 'Post',
        body: 'Body',
        category: 'otros',
        location: 'Full address',
        coordinates: PostCoordinates(
          latitude: 19.2,
          longitude: -98.2,
          precision: PostLocationPrecision.exact,
        ),
        city: city,
      ).toJson();
      expect((json['location_city'] as Map)['point'], {
        'latitude': 19.2,
        'longitude': -98.2,
      });
    },
  );
}
