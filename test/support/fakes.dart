import 'dart:async';

import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/profile/data/profile_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/legal/legal_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _events = StreamController.broadcast();
  AuthUser? user = const AuthUser(id: 'user-1', email: 'ana@marea.app');

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
  }) async => SignUpOutcome.confirmationRequired;

  @override
  Future<void> signIn({required String email, required String password}) async {
    user = AuthUser(id: 'user-1', email: email);
    _events.add(user);
  }

  @override
  Future<void> signOut() async {
    user = null;
    _events.add(null);
  }

  @override
  Future<void> clearLocalSession() async {
    user = null;
    _events.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    user = null;
    _events.add(null);
  }

  Future<void> close() => _events.close();
  @override
  Future<void> resendConfirmation(String email) async {}
  @override
  Future<void> requestRecovery(String email) async {}
  @override
  Future<void> verifyCode({
    required String email,
    required String code,
    required bool recovery,
  }) async {
    user = AuthUser(id: 'user-1', email: email, recovery: recovery);
  }

  @override
  Future<void> changePassword(
    String password, {
    String? currentPassword,
    String? nonce,
  }) async {}
  @override
  Future<void> changeEmail(String email, String currentPassword) async {}
  @override
  Future<void> requestReauthentication() async {}
}

class FakeProfileRepository implements ProfileRepository {
  Profile value = sampleProfile;

  @override
  Future<Profile> getCurrentProfile() async => value;

  @override
  Future<bool> isUsernameAvailable(String username) async =>
      username != 'taken';

  @override
  Future<Profile> completeInitialProfile(InitialProfileInput input) async {
    if (value.initialProfileCompletedAt != null) {
      throw StateError('initial_profile_already_confirmed');
    }
    value = value.copyWith(
      userType: input.userType,
      interests: input.interests.toSet().toList(),
      goals: input.goals.toSet().toList(),
      onboardingStatus: OnboardingStatus.completed,
      initialProfileCompletedAt: DateTime.now().toUtc(),
    );
    return value;
  }

  @override
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input) async {
    value = Profile.fromJson({...value.toJson(), ...input.toJson()});
    return value;
  }
}

Future<AppSessionController> authenticatedController() async {
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    legalRepository: FakeLegalRepository(),
  );
  await controller.initialize();
  return controller;
}

final sampleProfile = Profile(
  id: '3dd684f0-b55f-4d4f-b4cf-a0df3fd8b246',
  fullName: 'Ana López',
  username: 'ana',
  bio: 'Creo experiencias que conectan la ciudad.',
  userType: UserType.creator,
  role: ProfileRole.user,
  onboardingStatus: OnboardingStatus.completed,
  initialProfileCompletedAt: DateTime.utc(2026, 9, 11),
  createdAt: DateTime.utc(2026, 9, 11),
  updatedAt: DateTime.utc(2026, 9, 11),
);

class FakeLegalRepository implements LegalRepository {
  bool accepted = true;
  final policy = const LegalPolicy(
    signupEnabled: true,
    terms: LegalDocument(
      version: 'test-1',
      title: 'Términos de prueba',
      body: 'Solo pruebas. No son términos legales.',
    ),
    privacy: LegalDocument(
      version: 'test-1',
      title: 'Privacidad de prueba',
      body: 'Solo pruebas. No es un aviso legal.',
    ),
  );
  @override
  Future<LegalPolicy> loadPolicy() async => policy;
  @override
  Future<bool> hasAccepted(LegalPolicy policy) async => accepted;
  @override
  Future<void> accept(LegalConsent consent) async {
    accepted = true;
  }
}
