import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fakes.dart';

const duplicateMessage =
    'No pudimos completar este registro. Si ya tienes una cuenta, inicia sesión o recupera tu contraseña';
final consent = LegalConsent(
  termsVersion: 'test-1',
  privacyVersion: 'test-1',
  acceptedTerms: true,
  adultConfirmed: true,
);

Map<String, dynamic> signupUser({
  bool identitiesPresent = true,
  bool fake = false,
}) => {
  'id': '00000000-0000-4000-8000-000000000001',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'ana@example.com',
  'created_at': '2026-09-28T00:00:00Z',
  'confirmation_sent_at': '2026-09-28T00:00:00Z',
  'app_metadata': {
    'provider': 'email',
    'providers': ['email'],
  },
  'user_metadata': {'username': 'ana', 'full_name': 'Ana'},
  if (identitiesPresent)
    'identities': fake
        ? []
        : [
            {
              'identity_id': '00000000-0000-4000-8000-000000000002',
              'id': '00000000-0000-4000-8000-000000000001',
              'user_id': '00000000-0000-4000-8000-000000000001',
              'provider': 'email',
              'identity_data': {'email': 'ana@example.com'},
              'created_at': '2026-09-28T00:00:00Z',
              'updated_at': '2026-09-28T00:00:00Z',
            },
          ],
};

SupabaseAuthRepository repository(
  Map<String, dynamic> body, {
  int status = 200,
  WidgetTester? tester,
}) {
  final client = SupabaseClient(
    'https://example.invalid',
    'test-key',
    authOptions: AuthClientOptions(
      autoRefreshToken: false,
      pkceAsyncStorage: MemoryAuthStorage(),
    ),
    httpClient: MockClient((request) async {
      if (request.url.path == '/auth/v1/signup') {
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected request: ${request.url.path}');
    }),
  );
  addTearDown(() async {
    if (tester == null) {
      await client.dispose();
    } else {
      await tester.runAsync(client.dispose);
    }
  });
  return SupabaseAuthRepository(client);
}

Future<SignUpOutcome> signup(SupabaseAuthRepository repo) => repo.signUp(
  fullName: 'Ana',
  username: 'ana',
  email: 'ana@example.com',
  password: 'test-password-123',
  consent: consent,
);

Future<void> submitRegistration(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('register-type-general')));
  await tester.tap(find.byKey(const Key('register-type-general')));
  await tester.ensureVisible(find.text('Continuar'));
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('register-name')), 'Ana');
  await tester.enterText(find.byKey(const Key('register-username')), 'ana');
  await tester.ensureVisible(find.text('Continuar'));
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('register-email')),
    'ana@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('register-password')),
    'test-password-123',
  );
  for (final key in ['accept-terms', 'confirm-adult']) {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
  }
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('register-continue')));
  await tester.runAsync(() async {
    await tester.tap(find.byKey(const Key('register-continue')));
    // Let Supabase's JSON isolate finish before pumping the widget response.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

void main() {
  test('fake signup user produces a controlled access error', () async {
    await expectLater(
      signup(repository(signupUser(fake: true))),
      throwsA(
        isA<AppFailure>()
            .having((e) => e.kind, 'kind', AppFailureKind.emailAlreadyUsed)
            .having((e) => e.message, 'message', duplicateMessage),
      ),
    );
  });

  for (final missing in [false, true]) {
    test(
      'pending signup remains valid with identities missing=$missing',
      () async {
        expect(
          await signup(repository(signupUser(identitiesPresent: !missing))),
          SignUpOutcome.confirmationRequired,
        );
      },
    );
  }

  test(
    'a signup session is authenticated even with empty identities',
    () async {
      expect(
        await signup(
          repository({
            'access_token': 'test-token',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': signupUser(fake: true),
          }),
        ),
        SignUpOutcome.authenticated,
      );
    },
  );

  for (final error in [
    'user_already_exists',
    'smtp',
    'over_email_send_rate_limit',
  ]) {
    test('signup propagates $error as a controlled failure', () async {
      await expectLater(
        signup(
          repository({
            'code': error,
            'msg': error == 'user_already_exists'
                ? 'User already registered'
                : error,
          }, status: 400),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            error == 'user_already_exists'
                ? AppFailureKind.emailAlreadyUsed
                : AppFailureKind.general,
          ),
        ),
      );
    });
  }

  for (final action in ['Iniciar sesión', 'Recuperar contraseña', 'edit']) {
    testWidgets('duplicate signup keeps access usable through $action', (
      tester,
    ) async {
      final repo = await tester.runAsync(
        () async => repository(signupUser(fake: true), tester: tester),
      );
      final controller = AppSessionController(
        authRepository: repo!,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final router = AppRouter.create(controller)..go('/register');
      addTearDown(router.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      await submitRegistration(tester);
      expect(router.routeInformationProvider.value.uri.path, '/register');
      expect(controller.emailCooldown('ana@example.com', recovery: false), 0);
      expect(find.text(duplicateMessage), findsOneWidget);
      expect(find.byKey(const Key('email-code')), findsNothing);
      if (action == 'edit') {
        await tester.ensureVisible(find.byKey(const Key('register-email')));
        await tester.enterText(
          find.byKey(const Key('register-email')),
          'new@example.com',
        );
        await tester.pumpAndSettle();
        expect(find.text(duplicateMessage), findsNothing);
        expect(find.text('Recuperar contraseña'), findsNothing);
      } else {
        await tester.ensureVisible(find.text(action));
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        final login = action == 'Iniciar sesión';
        expect(
          router.routeInformationProvider.value.uri.path,
          login ? '/login' : '/recover-password',
        );
        expect(
          fieldText(tester, login ? 'login-email' : 'code-destination'),
          'ana@example.com',
        );
        expect(controller.failure, isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class MemoryAuthStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}
