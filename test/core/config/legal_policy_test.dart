import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/legal/legal_policy.dart';

void main() {
  test('registration stays closed without both published documents', () {
    final policy = LegalPolicy.fromJson({
      'signup_enabled': true,
      'terms': null,
      'privacy': null,
    });
    expect(policy.canRegister, isFalse);
    expect(const LegalPolicy.unavailable().canRegister, isFalse);
  });
  test('consent never accepts a minor or unaccepted terms', () {
    expect(
      () => LegalConsent(
        termsVersion: '1',
        privacyVersion: '1',
        acceptedTerms: true,
        adultConfirmed: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => LegalConsent(
        termsVersion: '1',
        privacyVersion: '1',
        acceptedTerms: false,
        adultConfirmed: true,
      ),
      throwsArgumentError,
    );
    final consent = LegalConsent(
      termsVersion: '1',
      privacyVersion: '2',
      acceptedTerms: true,
      adultConfirmed: true,
    );
    expect(consent.toMetadata(), {
      'terms_version': '1',
      'privacy_version': '2',
      'adult_confirmed': true,
      'accepted_terms': true,
    });
  });
}
