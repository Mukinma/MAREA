import 'package:marea/features/profile/models/profile.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/legal/legal_policy.dart';
import '../../support/fakes.dart';

void main() {
  final consent = LegalConsent(
    termsVersion: 'test-1',
    privacyVersion: 'test-1',
    acceptedTerms: true,
    adultConfirmed: true,
  );
  test(
    'signup is locked during the username check, not just the auth request',
    () async {
      final auth = CountingAuth()..user = null;
      final profiles = WaitingProfiles();
      final c = AppSessionController(
        authRepository: auth,
        profileRepository: profiles,
        legalRepository: FakeLegalRepository(),
      );
      addTearDown(c.dispose);
      await c.initialize();
      final first = c.signUp(
        fullName: 'Ana',
        username: 'ana',
        email: 'ana@example.com',
        password: 'password123',
        consent: consent,
      );
      expect(c.isBusy, isTrue);
      expect(
        await c.signUp(
          fullName: 'Ana',
          username: 'ana',
          email: 'ana@example.com',
          password: 'password123',
          consent: consent,
        ),
        isNull,
      );
      profiles.available.complete(true);
      await first;
      expect(auth.registrations, 1);
      expect(auth.lastConsent?.privacyVersion, 'test-1');
    },
  );
  test(
    'an unavailable username service is not reported as an occupied name',
    () async {
      final profiles = WaitingProfiles();
      final c = AppSessionController(
        authRepository: CountingAuth()..user = null,
        profileRepository: profiles,
        legalRepository: FakeLegalRepository(),
      );
      addTearDown(c.dispose);
      await c.initialize();
      final signup = c.signUp(
        fullName: 'Ana',
        username: 'ana',
        email: 'ana@example.com',
        password: 'password123',
        consent: consent,
      );
      profiles.available.completeError(Exception('network unavailable'));
      await signup;
      expect(c.failure!.message, contains('conectarnos'));
      expect(c.failure!.message, isNot(contains('ocupado')));
    },
  );
  test('missing legal policy prevents sending signup data to Auth', () async {
    final auth = CountingAuth()..user = null;
    final c = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.signUp(
      fullName: 'Ana',
      username: 'ana',
      email: 'ana@example.com',
      password: 'password123',
      consent: consent,
    );
    expect(auth.registrations, 0);
    expect(c.failure, isNotNull);
  });
  test('resending a recovery email has a cooldown', () async {
    final auth = CountingAuth()..user = null;
    final c = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    expect(await c.sendCode('ana@example.com', recovery: true), isTrue);
    expect(await c.sendCode('ana@example.com', recovery: true), isFalse);
    expect(auth.recoveryEmails, 1);
  });
  test(
    'verification keeps recovery active until password update succeeds',
    () async {
      final c = AppSessionController(
        authRepository: FakeAuthRepository()..user = null,
        profileRepository: FakeProfileRepository(),
      );
      addTearDown(c.dispose);
      await c.initialize();
      expect(
        await c.verifyCode('ana@example.com', '123456', recovery: true),
        isTrue,
      );
      expect(c.isRecovering, isTrue);
      expect(await c.changePassword('a-new-password'), isTrue);
      expect(c.isRecovering, isFalse);
    },
  );
}

class WaitingProfiles extends FakeProfileRepository {
  final available = Completer<bool>();
  @override
  Future<bool> isUsernameAvailable(String username) => available.future;
}

class CountingAuth extends FakeAuthRepository {
  int registrations = 0, recoveryEmails = 0;
  LegalConsent? lastConsent;
  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    UserType userType = UserType.general,
    LegalConsent? consent,
  }) async {
    registrations++;
    lastConsent = consent;
    return SignUpOutcome.confirmationRequired;
  }

  @override
  Future<void> requestRecovery(String email) async {
    recoveryEmails++;
  }
}
