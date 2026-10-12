import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MobileIntroStore {
  Future<bool> hasSeenIntro();
  Future<void> markSeenIntro();
}

/// Installation-local state, independent of accounts and profile setup.
class SharedPreferencesMobileIntroStore implements MobileIntroStore {
  static const _key = 'marea.mobile_intro.seen';
  bool _completedThisRun = false;

  @override
  Future<bool> hasSeenIntro() async =>
      _completedThisRun ||
      (await SharedPreferences.getInstance()).getBool(_key) == true;

  @override
  Future<void> markSeenIntro() async {
    // Even if disk storage fails, don't interrupt access or repeat this run.
    _completedThisRun = true;
    await (await SharedPreferences.getInstance()).setBool(_key, true);
  }
}
