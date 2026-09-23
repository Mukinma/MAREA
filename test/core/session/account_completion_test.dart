import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';

void main() {
  test('skip onboarding persists status without inventing interests', () async {
    final profiles = FakeProfileRepository();
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: profiles,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(
      await controller.finishOnboarding(skip: true, interests: [], goals: []),
      isTrue,
    );
    expect(controller.profile!.onboardingStatus, OnboardingStatus.skipped);
    expect(controller.profile!.interests, isEmpty);
  });
  test(
    'an in-flight profile refresh cannot restore a signed-out account',
    () async {
      final auth = FakeAuthRepository();
      final profiles = DelayedProfiles();
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: profiles,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      profiles.delay = Completer<Profile>();
      final refresh = controller.refreshProfile();
      await controller.signOut();
      profiles.delay!.complete(sampleProfile);
      await refresh;
      expect(controller.profile, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
    },
  );
}

class DelayedProfiles extends FakeProfileRepository {
  Completer<Profile>? delay;
  @override
  Future<Profile> getCurrentProfile() =>
      delay?.future ?? super.getCurrentProfile();
}
