import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'the isolated production pilot cannot open Google auth for the normal app',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'test-public-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests++;
          return http.Response('{}', 500);
        }),
      );
      final repository = SupabaseAuthRepository(
        client,
        allowGoogleOAuth: false,
      );
      await expectLater(
        repository.signInWithGoogle(
          redirectTo: 'com.marea.app://login-callback',
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(requests, 0);
      await client.dispose();
    },
  );
}
