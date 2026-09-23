import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';

void main() {
  Map<String, dynamic> row() => {
    'id': 'mission',
    'author_id': 'author',
    'title': 'Misión',
    'body': 'Descripción',
    'category': 'arte',
    'location': 'Centro',
    'starts_at': '2100-01-01T00:00:00Z',
    'capacity': 3,
    'status': 'open',
    'created_at': '2026-01-01T00:00:00Z',
  };

  MissionInput input({
    String? requirements,
    String? conditions,
    PostCoordinates? coordinates,
    DateTime? startsAt,
  }) => MissionInput(
    title: 'Misión',
    body: 'Descripción',
    category: 'arte',
    location: 'Centro',
    startsAt: startsAt ?? DateTime.utc(2100),
    capacity: 3,
    requirements: requirements,
    conditions: conditions,
    coordinates: coordinates,
  );

  test(
    'mission lifecycle distinguishes status, expiry, capacity and locked terms',
    () {
      final mission = Mission.fromJson(row());
      expect(mission.isOpen, isTrue);
      expect(mission.isExpired, isFalse);
      expect(mission.isFull, isFalse);
      expect(mission.isTerminal, isFalse);
      expect(mission.conditionsLocked, isFalse);
      expect(mission.availableSeats, 3);
      final full = Mission.fromJson({...row(), 'accepted_count': 4});
      expect(full.isFull, isTrue);
      expect(full.availableSeats, 0);
      expect(full.isOpen, isTrue);
      expect(
        Mission.fromJson({
          ...row(),
          'starts_at': '2000-01-01T00:00:00Z',
        }).isExpired,
        isTrue,
      );
      expect(
        Mission.fromJson({...row(), 'status': 'closed'}).isTerminal,
        isFalse,
      );
      for (final status in ['cancelled', 'completed']) {
        final terminal = Mission.fromJson({...row(), 'status': status});
        expect(terminal.isTerminal, isTrue);
        expect(terminal.isOpen, isFalse);
        expect(
          terminal.statusLabel,
          status == 'cancelled' ? 'Cancelada' : 'Finalizada',
        );
      }
      final locked = Mission.fromJson({
        ...row(),
        'conditions_locked_at': '2026-09-01T00:00:00Z',
        'accepted_count': 0,
        'requirements': 'Material propio',
        'conditions': 'Gratis',
        'image_path': 'author/photo.png',
        'cancellation_reason': 'Mal clima',
      });
      expect(locked.conditionsLocked, isTrue);
      expect(locked.requirements, 'Material propio');
      expect(locked.conditions, 'Gratis');
      expect(locked.imagePath, 'author/photo.png');
      expect(locked.cancellationReason, 'Mal clima');
    },
  );

  test('optional mission text is trimmed, bounded and cleared explicitly', () {
    expect(
      input(requirements: 'a' * 3000, conditions: 'b' * 3000).validate(),
      isNull,
    );
    expect(input(requirements: 'a' * 3001).validate(), isNotNull);
    expect(input(conditions: 'b' * 3001).validate(), isNotNull);
    final json = input(requirements: ' Material ', conditions: ' ').toJson();
    expect(json['requirements'], 'Material');
    expect(json['conditions'], isNull);
    expect(json['location_latitude'], isNull);
    expect(json['location_longitude'], isNull);
    expect(json['location_precision'], isNull);
    final past = input(startsAt: DateTime.utc(2000));
    expect(past.validate(), isNotNull);
    expect(past.validate(allowPast: true), isNull);
  });

  test(
    'coordinate parsing rejects partial, nonnumeric, nonfinite and invalid tuples',
    () {
      final valid = {
        'location_latitude': 19.4,
        'location_longitude': -99.1,
        'location_precision': 'approximate',
      };
      expect(PostCoordinates.fromJson(valid)?.isApproximate, isTrue);
      for (final invalid in <Map<String, dynamic>>[
        {},
        {...valid}..remove('location_latitude'),
        {...valid}..remove('location_longitude'),
        {...valid}..remove('location_precision'),
        {...valid, 'location_latitude': double.nan},
        {...valid, 'location_longitude': double.infinity},
        {...valid, 'location_latitude': '19.4'},
        {...valid, 'location_longitude': -181},
        {...valid, 'location_latitude': 91},
        {...valid, 'location_precision': 'unknown'},
      ]) {
        expect(PostCoordinates.fromJson(invalid), isNull);
        expect(Mission.fromJson({...row(), ...invalid}).coordinates, isNull);
      }
      final mission = Mission.fromJson({...row(), ...valid});
      expect(mission.coordinates?.latitude, 19.4);
    },
  );

  test('both input types reject nonfinite coordinates', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final coordinates in [
        PostCoordinates(
          latitude: value,
          longitude: 0,
          precision: PostLocationPrecision.exact,
        ),
        PostCoordinates(
          latitude: 0,
          longitude: value,
          precision: PostLocationPrecision.exact,
        ),
      ]) {
        expect(input(coordinates: coordinates).validate(), isNotNull);
        expect(
          PostInput(
            kind: PostKind.community,
            title: 'Título',
            body: 'Descripción',
            category: 'arte',
            coordinates: coordinates,
          ).validate(),
          isNotNull,
        );
      }
    }
  });

  test('lifecycle errors explain the applicable restriction', () {
    for (final entry in {
      'mission_conditions_locked': 'aceptadas',
      'mission_capacity_cannot_decrease': 'aumentar',
      'mission_terminal': 'cancelada o completada',
      'mission_not_started': 'fecha de inicio',
      'mission_must_be_future': 'futuras',
      'invalid_mission_image': 'imagen',
      'mission_image_in_use': 'vinculada',
      'application_withdrawn': 'retirada',
    }.entries) {
      expect(communityFailure(entry.key).message, contains(entry.value));
    }
  });
}
