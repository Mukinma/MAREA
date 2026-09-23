import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../../support/fakes.dart';

void main() {
  test(
    'removing optional profile fields actually clears their persisted values',
    () {
      final before = sampleProfile.copyWith(
        bio: 'Hola',
        website: 'https://example.com',
        avatarPath: 'user/a.png',
      );
      final after = before.copyWith(bio: null, website: null, avatarPath: null);
      expect(after.updateInput.toJson()['bio'], isNull);
      expect(after.updateInput.toJson()['website'], isNull);
      expect(after.updateInput.toJson()['avatar_path'], isNull);
    },
  );
  test('preference updates deduplicate and reject unknown interests', () {
    expect(ProfilePreferences.normalizeInterests(['arte', 'arte', 'musica']), [
      'arte',
      'musica',
    ]);
    expect(
      () => ProfilePreferences.normalizeInterests(['salud-secreta']),
      throwsArgumentError,
    );
  });
  test(
    'portfolio accepts https and rejects active or credential-bearing URLs',
    () {
      expect(
        ProfilePreferences.websiteError('https://example.com/ana'),
        isNull,
      );
      for (final url in [
        'javascript:alert(1)',
        'http://example.com',
        'https://user:pass@example.com',
        'https://localhost',
        'https://',
      ]) {
        expect(ProfilePreferences.websiteError(url), isNotNull, reason: url);
      }
    },
  );
  test('legacy profile decodes as pending without inventing preferences', () {
    final json = sampleProfile.toJson()
      ..remove('onboarding_status')
      ..remove('interests');
    final profile = Profile.fromJson(json);
    expect(profile.onboardingStatus, OnboardingStatus.pending);
    expect(profile.interests, isEmpty);
  });
}
