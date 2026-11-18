import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const picker = MethodChannel('marea/google-sign-in');
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  const callback = 'com.marea.app://login-callback';
  const clientId = 'marea-test.apps.googleusercontent.com';
  late SupabaseClient client;
  late List<http.Request> requests;
  late List<Uri> launched;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    requests = [];
    launched = [];
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-key',
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('{"message":"Test response"}', 400);
      }),
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, (
      call,
    ) async {
      launched.add(Uri.parse((call.arguments as Map)['url'] as String));
      return true;
    });
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(picker, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, null);
    await client.dispose();
  });

  test('browser fallback requests Google account selection', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(picker, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    await SupabaseAuthRepository(
      client,
      googleWebClientId: clientId,
    ).signInWithGoogle(redirectTo: callback);
    expect(
      launched.single.queryParameters,
      containsPair('prompt', 'select_account'),
    );
    expect(
      launched.single.queryParameters,
      containsPair('redirect_to', callback),
    );
  });

  test(
    'dismissing the native picker leaves the user on the same screen',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        picker,
        (_) async => null,
      );
      await SupabaseAuthRepository(
        client,
        googleWebClientId: clientId,
      ).signInWithGoogle(redirectTo: callback);
      expect(launched, isEmpty);
      expect(requests, isEmpty);
    },
  );

  test(
    'native Google exchanges the selected token with its original nonce',
    () async {
      late String nonce;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(picker, (
        call,
      ) async {
        expect(call.method, 'chooseAccount');
        expect(call.arguments, containsPair('serverClientId', clientId));
        nonce = (call.arguments as Map)['nonce'] as String;
        expect(nonce, isNotEmpty);
        return 'fake-google-id-token';
      });
      await expectLater(
        SupabaseAuthRepository(
          client,
          googleWebClientId: clientId,
        ).signInWithGoogle(redirectTo: callback),
        throwsA(isA<AppFailure>()),
      );
      expect(launched, isEmpty);
      expect(
        requests.single.url.queryParameters,
        containsPair('grant_type', 'id_token'),
      );
      expect(
        jsonDecode(requests.single.body),
        allOf(
          containsPair('provider', 'google'),
          containsPair('id_token', 'fake-google-id-token'),
          containsPair('nonce', nonce),
        ),
      );
    },
  );
}
