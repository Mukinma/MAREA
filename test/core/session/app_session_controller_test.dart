import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/profile/data/profile_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart' as support;
import 'package:marea/features/legal/legal_policy.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late AppSessionController controller;

  setUp(() {
    auth = FakeAuthRepository()..user = null;
    profiles = FakeProfileRepository();
    controller = AppSessionController(
      authRepository: auth,
      profileRepository: profiles,
      legalRepository: support.FakeLegalRepository(),
    );
  });

  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  test(
    'initializes as unauthenticated when there is no persisted user',
    () async {
      await controller.initialize();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile, isNull);
    },
  );

  test('restores an authenticated user and loads their profile', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');

    await controller.initialize();

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.profile?.username, 'ana');
    expect(controller.email, 'ana@marea.app');
  });

  test('keeps a natural failure when sign in fails', () async {
    auth.signInError = const AppFailure(
      'El correo o la contraseña no son correctos.',
    );
    await controller.initialize();

    final succeeded = await controller.signIn(
      email: 'ana@marea.app',
      password: 'incorrecta',
    );

    expect(succeeded, isFalse);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(
      controller.failure?.message,
      'El correo o la contraseña no son correctos.',
    );
    expect(controller.isBusy, isFalse);
  });

  test(
    'returns confirmationRequired without authenticating the session',
    () async {
      auth.signUpOutcome = SignUpOutcome.confirmationRequired;
      await controller.initialize();

      final outcome = await controller.signUp(
        fullName: 'Ana López',
        username: 'ana',
        email: 'ana@marea.app',
        password: '12345678',
        consent: LegalConsent(
          termsVersion: 'test-1',
          privacyVersion: 'test-1',
          acceptedTerms: true,
          adultConfirmed: true,
        ),
      );

      expect(outcome, SignUpOutcome.confirmationRequired);
      expect(controller.status, AuthStatus.unauthenticated);
    },
  );

  test(
    'loads the profile when sign up creates a session immediately',
    () async {
      auth.signUpOutcome = SignUpOutcome.authenticated;
      await controller.initialize();

      final outcome = await controller.signUp(
        fullName: 'Ana López',
        username: 'ana',
        email: 'ana@marea.app',
        password: '12345678',
        consent: LegalConsent(
          termsVersion: 'test-1',
          privacyVersion: 'test-1',
          acceptedTerms: true,
          adultConfirmed: true,
        ),
      );

      expect(outcome, SignUpOutcome.authenticated);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.profile?.fullName, 'Ana López');
    },
  );

  test('replaces the in-memory profile after a successful update', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    await controller.initialize();
    final updated = controller.profile!
        .copyWith(bio: 'Una bio nueva')
        .updateInput;

    final succeeded = await controller.updateProfile(updated);

    expect(succeeded, isTrue);
    expect(controller.profile?.bio, 'Una bio nueva');
    expect(controller.successMessage, 'Perfil actualizado.');
  });

  test('automatically clears a success message after a short delay', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    await controller.initialize();
    final updated = controller.profile!
        .copyWith(bio: 'Una bio nueva')
        .updateInput;

    await controller.updateProfile(updated);
    expect(controller.successMessage, 'Perfil actualizado.');

    await Future<void>.delayed(const Duration(seconds: 4, milliseconds: 100));

    expect(controller.successMessage, isNull);
  });

  test('reacts to a signed out auth event', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    await controller.initialize();

    auth.emit(null);
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.profile, isNull);
  });

  test('clears a persisted session whose account no longer exists', () async {
    auth.user = const AuthUser(id: 'deleted-user', email: 'ana@marea.app');
    final staleController = AppSessionController(
      authRepository: auth,
      profileRepository: MissingProfileRepository(),
      legalRepository: support.FakeLegalRepository(),
    );
    addTearDown(staleController.dispose);

    await staleController.initialize();

    expect(staleController.status, AuthStatus.unauthenticated);
    expect(staleController.profile, isNull);
    expect(auth.currentUser, isNull);
  });

  test(
    'keeps a retryable session when profile loading loses network',
    () async {
      auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
      final flakyProfiles = FlakyProfileRepository();
      final retryController = AppSessionController(
        authRepository: auth,
        profileRepository: flakyProfiles,
        legalRepository: support.FakeLegalRepository(),
      );
      addTearDown(retryController.dispose);

      await retryController.initialize();

      expect(retryController.status, AuthStatus.authenticated);
      expect(retryController.profile, isNull);
      expect(auth.currentUser, isNotNull);
      expect(retryController.failure?.message, 'No pudimos conectarnos.');

      await retryController.refreshProfile();

      expect(retryController.profile?.username, 'ana');
      expect(retryController.failure, isNull);
      expect(auth.currentUser, isNotNull);
    },
  );

  test('refresh reloads the latest persisted profile', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    await controller.initialize();
    profiles.value = profiles.value.copyWith(fullName: 'Ana renovada');

    await controller.refresh();

    expect(controller.profile?.fullName, 'Ana renovada');
    expect(controller.failure, isNull);
  });

  test('refresh clears a session deleted while the app was open', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    final invalidatingProfiles = InvalidatingProfileRepository();
    final refreshController = AppSessionController(
      authRepository: auth,
      profileRepository: invalidatingProfiles,
      legalRepository: support.FakeLegalRepository(),
    );
    addTearDown(refreshController.dispose);
    await refreshController.initialize();
    invalidatingProfiles.invalid = true;

    await refreshController.refresh();

    expect(refreshController.status, AuthStatus.unauthenticated);
    expect(refreshController.profile, isNull);
    expect(auth.currentUser, isNull);
  });

  test('a stale refresh cannot overwrite a profile saved afterwards', () async {
    auth.user = const AuthUser(id: 'user-1', email: 'ana@marea.app');
    final concurrentProfiles = ConcurrentProfileRepository();
    final concurrentController = AppSessionController(
      authRepository: auth,
      profileRepository: concurrentProfiles,
      legalRepository: support.FakeLegalRepository(),
    );
    addTearDown(concurrentController.dispose);
    await concurrentController.initialize();
    concurrentProfiles.blockNextRead();

    final refreshing = concurrentController.refresh();
    await concurrentProfiles.readStarted;
    final saved = await concurrentController.updateProfile(
      concurrentController.profile!
          .copyWith(bio: 'La bio más reciente')
          .updateInput,
    );
    concurrentProfiles.completeBlockedRead();
    await refreshing;

    expect(saved, isTrue);
    expect(concurrentController.profile?.bio, 'La bio más reciente');
  });
}

class FakeAuthRepository extends support.FakeAuthRepository {
  final StreamController<AuthUser?> _events = StreamController.broadcast();

  AppFailure? signInError;
  SignUpOutcome signUpOutcome = SignUpOutcome.confirmationRequired;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get authStateChanges => _events.stream;

  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    UserType userType = UserType.general,
    LegalConsent? consent,
  }) async {
    if (signUpOutcome == SignUpOutcome.authenticated) {
      user = AuthUser(id: 'user-1', email: email);
    }
    return signUpOutcome;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError case final error?) throw error;
    user = AuthUser(id: 'user-1', email: email);
  }

  @override
  Future<void> signOut() async {
    user = null;
    _events.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    user = null;
  }

  void emit(AuthUser? nextUser) {
    user = nextUser;
    _events.add(nextUser);
  }

  @override
  Future<void> close() => _events.close();
}

class FakeProfileRepository implements ProfileRepository {
  Profile value = _profile();

  @override
  Future<Profile> getCurrentProfile() async => value;

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> completeInitialProfile(InitialProfileInput input) async {
    value = value.copyWith(
      userType: input.userType,
      interests: input.interests,
      goals: input.goals,
      initialProfileCompletedAt: DateTime.now(),
    );
    return value;
  }

  @override
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input) async {
    value = Profile.fromJson({...value.toJson(), ...input.toJson()});
    return value;
  }
}

class MissingProfileRepository extends FakeProfileRepository {
  @override
  Future<Profile> getCurrentProfile() async {
    throw const AppFailure(
      'Tu sesión ya no es válida. Inicia sesión nuevamente.',
      kind: AppFailureKind.invalidSession,
    );
  }
}

class FlakyProfileRepository extends FakeProfileRepository {
  var calls = 0;

  @override
  Future<Profile> getCurrentProfile() async {
    if (calls++ == 0) {
      throw const AppFailure('No pudimos conectarnos.');
    }
    return super.getCurrentProfile();
  }
}

class InvalidatingProfileRepository extends FakeProfileRepository {
  bool invalid = false;

  @override
  Future<Profile> getCurrentProfile() async {
    if (invalid) {
      throw const AppFailure(
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        kind: AppFailureKind.invalidSession,
      );
    }
    return super.getCurrentProfile();
  }
}

class ConcurrentProfileRepository extends FakeProfileRepository {
  Completer<void>? _readStarted;
  Completer<Profile>? _blockedRead;

  Future<void> get readStarted => _readStarted!.future;

  void blockNextRead() {
    _readStarted = Completer<void>();
    _blockedRead = Completer<Profile>();
  }

  void completeBlockedRead() {
    _blockedRead!.complete(_blockedSnapshot);
  }

  late Profile _blockedSnapshot;

  @override
  Future<Profile> getCurrentProfile() {
    final blockedRead = _blockedRead;
    if (blockedRead == null || blockedRead.isCompleted) {
      return super.getCurrentProfile();
    }
    _blockedSnapshot = value;
    _readStarted!.complete();
    return blockedRead.future;
  }
}

Profile _profile() => Profile(
  id: 'user-1',
  fullName: 'Ana López',
  username: 'ana',
  bio: null,
  userType: UserType.general,
  role: ProfileRole.user,
  createdAt: DateTime.utc(2026, 9, 11),
  updatedAt: DateTime.utc(2026, 9, 11),
);
