import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';

void main() {
  final json = <String, dynamic>{
    'id': '3dd684f0-b55f-4d4f-b4cf-a0df3fd8b246',
    'full_name': 'Christopher Aguilar',
    'username': 'cris',
    'bio': 'Creo experiencias urbanas.',
    'user_type': 'Artista / creador',
    'role': 'user',
    'avatar_url': null,
    'created_at': '2026-09-11T12:00:00.000Z',
    'updated_at': '2026-09-11T13:00:00.000Z',
  };

  test('deserializes the complete database representation', () {
    final profile = Profile.fromJson(json);

    expect(profile.id, json['id']);
    expect(profile.fullName, 'Christopher Aguilar');
    expect(profile.userType, UserType.creator);
    expect(profile.role, ProfileRole.user);
    expect(profile.initials, 'CA');
  });

  test('serializes only editable columns for an update', () {
    final payload = Profile.fromJson(json).toUpdateJson();

    expect(payload, {
      'full_name': 'Christopher Aguilar',
      'username': 'cris',
      'bio': 'Creo experiencias urbanas.',
      'user_type': 'Artista / creador',
      'avatar_path': null,
      'cover_path': null,
      'cover_preset': 'marea',
      'website': null,
      'interests': <String>[],
      'goals': <String>[],
      'onboarding_status': 'pending',
    });
    expect(payload, isNot(contains('role')));
    expect(payload, isNot(contains('id')));
  });

  test('copyWith updates public fields without changing protected fields', () {
    final original = Profile.fromJson(json);
    final updated = original.copyWith(bio: 'Nueva bio', username: 'cris.mx');

    expect(updated.bio, 'Nueva bio');
    expect(updated.username, 'cris.mx');
    expect(updated.id, original.id);
    expect(updated.role, original.role);
    expect(updated.createdAt, original.createdAt);
  });

  test('initials handle one name and ignore repeated spaces', () {
    expect(Profile.fromJson({...json, 'full_name': 'Ana'}).initials, 'A');
    expect(
      Profile.fromJson({...json, 'full_name': 'Ana   López'}).initials,
      'AL',
    );
  });

  test('profile update input contains only normalized public fields', () {
    const input = ProfileUpdateInput(
      fullName: 'Ana López',
      username: 'ana.mx',
      bio: '',
      userType: UserType.creator,
      avatarUrl: null,
    );

    expect(input.toJson(), {
      'full_name': 'Ana López',
      'username': 'ana.mx',
      'bio': null,
      'user_type': 'Artista / creador',
      'avatar_path': null,
      'cover_path': null,
      'cover_preset': 'marea',
      'website': null,
      'interests': <String>[],
      'goals': <String>[],
      'onboarding_status': 'pending',
    });
  });
}
