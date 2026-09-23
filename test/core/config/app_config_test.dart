import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/config/app_config.dart';

void main() {
  test('accepts a complete Supabase configuration', () {
    final config = AppConfig.fromValues(
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_publishable_example',
    );

    expect(config.isValid, isTrue);
    expect(config.validationMessage, isNull);
  });

  test('reports missing values without exposing secrets', () {
    final config = AppConfig.fromValues(
      supabaseUrl: '',
      supabaseAnonKey: 'secret-value',
    );

    expect(config.isValid, isFalse);
    expect(config.validationMessage, contains('SUPABASE_URL'));
    expect(config.validationMessage, isNot(contains('secret-value')));
  });
}
