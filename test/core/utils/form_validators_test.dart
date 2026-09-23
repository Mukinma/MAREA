import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/utils/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('normalizes username by trimming, removing @ and lowercasing', () {
      expect(FormValidators.normalizeUsername('  @Cris.MX  '), 'cris.mx');
    });

    test('accepts valid usernames and rejects unsupported characters', () {
      expect(FormValidators.username('cris_24'), isNull);
      expect(FormValidators.username('cr'), isNotNull);
      expect(FormValidators.username('cris-mx'), isNotNull);
      expect(FormValidators.username('cris mx'), isNotNull);
    });

    test('validates required names and their maximum length', () {
      expect(FormValidators.fullName('  '), isNotNull);
      expect(FormValidators.fullName('Ana'), isNull);
      expect(FormValidators.fullName('a' * 81), isNotNull);
    });

    test('validates email shape without accepting surrounding spaces', () {
      expect(FormValidators.email('ana@marea.app'), isNull);
      expect(FormValidators.email('ana@'), isNotNull);
      expect(FormValidators.email(' ana@marea.app '), isNotNull);
    });

    test('requires an eight character password and matching confirmation', () {
      expect(FormValidators.password('1234567'), isNotNull);
      expect(FormValidators.password('12345678'), isNull);
      expect(
        FormValidators.confirmPassword('different', '12345678'),
        isNotNull,
      );
      expect(FormValidators.confirmPassword('12345678', '12345678'), isNull);
    });

    test('limits bio to 160 characters while allowing it to be empty', () {
      expect(FormValidators.bio(''), isNull);
      expect(FormValidators.bio('a' * 160), isNull);
      expect(FormValidators.bio('a' * 161), isNotNull);
    });
  });
}
