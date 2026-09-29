import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import '../../support/fakes.dart';
import 'package:marea/features/profile/models/profile.dart';

void main() {
  test('ordinary profile edits never send initial choices', () {
    final payload = sampleProfile.toUpdateJson();
    for (final key in [
      'user_type',
      'interests',
      'goals',
      'onboarding_status',
    ]) {
      expect(payload.containsKey(key), false, reason: key);
    }
  });
  test('confirmed accounts cannot reopen onboarding', () {
    expect(
      AppRouter.redirectFor(AuthStatus.authenticated, '/onboarding'),
      '/profile',
    );
  });
  test('business can offer services without receiving artist tools', () {
    expect(UserType.business.postKinds, contains(PostKind.service));
    expect(UserType.business.postKinds, isNot(contains(PostKind.project)));
  });
}
