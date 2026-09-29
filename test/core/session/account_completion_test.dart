import 'dart:async';
import 'package:marea/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';

void main() {
  test('initial confirmation is mandatory and cannot be repeated', () async {
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(initialProfileCompletedAt: null);
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: profiles,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.needsOnboarding, isTrue);
    expect(
      await controller.completeInitialProfile(
        const InitialProfileInput(
          userType: UserType.creator,
          interests: [],
          goals: [],
        ),
      ),
      isTrue,
    );
    expect(controller.needsOnboarding, isFalse);
    expect(
      await controller.completeInitialProfile(
        const InitialProfileInput(
          userType: UserType.business,
          interests: ['arte'],
          goals: ['colaborar'],
        ),
      ),
      isFalse,
    );
    expect(controller.profile!.userType, UserType.creator);
  });
  test(
    'lost initial confirmation response recovers the persisted selection',
    () async {
      final profiles = LostConfirmationResponse()
        ..value = sampleProfile.copyWith(initialProfileCompletedAt: null);
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: profiles,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(
        await controller.completeInitialProfile(
          const InitialProfileInput(
            userType: UserType.business,
            interests: ['arte'],
            goals: ['colaborar'],
          ),
        ),
        isTrue,
      );
      expect(controller.needsOnboarding, isFalse);
      expect(controller.profile!.userType, UserType.business);
    },
  );
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

class LostConfirmationResponse extends FakeProfileRepository {
  @override
  Future<Profile> completeInitialProfile(InitialProfileInput input) async {
    await super.completeInitialProfile(input);
    throw const AppFailure('No pudimos conectarnos.');
  }
}
