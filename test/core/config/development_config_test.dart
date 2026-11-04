import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/config/app_config.dart';

const _key = 'sb_publishable_abcdefghijklmnopqrstuvwx';
AppConfig config({
  String target = 'https://aaaaaaaaaaaaaaaaaaaa.supabase.co',
  String production = 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co',
  String key = _key,
  String links = 'http://localhost:7358/',
}) => AppConfig.fromValues(
  supabaseUrl: target,
  supabaseAnonKey: key,
  environment: 'development',
  productionSupabaseUrl: production,
  publicUrl: links,
);

void main() {
  test(
    'development fails before initialization when production is selected',
    () {
      final value = config(target: 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co');
      expect(value.isValid, false);
      expect(value.validationMessage, contains('separado'));
      expect(config(production: '').isValid, false);
      expect(
        config(
          target: 'https://user:password@aaaaaaaaaaaaaaaaaaaa.supabase.co',
        ).isValid,
        false,
      );
    },
  );
  test(
    'development permits its own project and a device-accessible local backend',
    () {
      expect(config().isValid, true);
      expect(config(target: 'http://127.0.0.1:54321').isValid, true);
      expect(config(target: 'http://192.168.1.20:54321').isValid, true);
      expect(config(target: 'http://public.example.com').isValid, false);
      expect(config(links: 'https://marea-azul.netlify.app/').isValid, false);
    },
  );
  test(
    'development rejects server credentials without including them in errors',
    () {
      for (final key in [
        'sb_secret_backend-secret',
        'header.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
      ]) {
        final value = config(key: key);
        expect(value.isValid, false);
        expect(value.validationMessage, isNot(contains(key)));
      }
    },
  );
  test('development separates callbacks and session keys by backend', () {
    final value = config();
    expect(value.mobileOAuthRedirect, 'com.marea.app.dev://login-callback');
    expect(
      value.developmentSessionKey,
      isNot(config(target: 'http://localhost:54321').developmentSessionKey),
    );
    expect(
      config(target: 'http://localhost:54321').developmentSessionKey,
      isNot(config(target: 'http://localhost:54322').developmentSessionKey),
    );
    for (final callback in [
      'com.marea.app.dev://login-callback?code=one',
      'com.marea.app.dev://login-callback#error=denied',
      'http://localhost:7358/?code=one',
    ]) {
      expect(value.acceptsDevelopmentAuthCallback(Uri.parse(callback)), true);
    }
    for (final callback in [
      'com.marea.app://login-callback?code=one',
      'com.marea.app.dev://login-callback.evil.test?code=one',
      'com.marea.app.dev://login-callback/other?code=one',
      'https://marea-azul.netlify.app/?code=one',
      'http://localhost:7359/?code=one',
      'http://localhost:7358/posts/p?code=one',
      'com.marea.app.dev://login-callback',
    ]) {
      expect(
        value.acceptsDevelopmentAuthCallback(Uri.parse(callback)),
        false,
        reason: callback,
      );
    }
  });
  test('normal configuration keeps its existing callback and validation', () {
    final value = AppConfig.fromValues(
      supabaseUrl: 'url',
      supabaseAnonKey: 'key',
    );
    expect(value.isValid, true);
    expect(value.isDevelopment, false);
    expect(value.mobileOAuthRedirect, 'com.marea.app://login-callback');
    expect(
      value.acceptsDevelopmentAuthCallback(
        Uri.parse('com.marea.app.dev://login-callback?code=one'),
      ),
      false,
    );
  });
}
