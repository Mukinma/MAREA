import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/config/app_config.dart';

void main() {
  test('shared links use configured origin and a post destination', () {
    final config = AppConfig.fromValues(supabaseUrl: 'url', supabaseAnonKey: 'key', publicUrl: 'https://example.com/');
    expect(config.postUrl('post-1').toString(), 'https://example.com/posts/post-1');
  });
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
