import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/auth/data/mobile_intro_store.dart';
import 'package:marea/features/auth/presentation/mobile_intro_screen.dart';
import 'package:marea/features/auth/presentation/splash_screen.dart';
import 'package:marea/features/auth/presentation/welcome_screen.dart';
import 'package:marea/core/session/app_session_controller.dart';

/// Lives inside /welcome, so auth, deep links and profile guards stay intact.
class WelcomeEntryScreen extends StatefulWidget {
  const WelcomeEntryScreen({
    required this.store,
    required this.controller,
    super.key,
  });
  final MobileIntroStore store;
  final AppSessionController controller;

  @override
  State<WelcomeEntryScreen> createState() => _WelcomeEntryScreenState();
}

class _WelcomeEntryScreenState extends State<WelcomeEntryScreen> {
  static const _storageTimeout = Duration(seconds: 2);
  bool? _seen;
  bool _finishing = false;
  bool _completedThisVisit = false;

  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_mobile) _load();
  }

  Future<void> _load() async {
    var seen = false;
    try {
      seen = await widget.store.hasSeenIntro().timeout(_storageTimeout);
    } catch (_) {
      // A missing preference is safe: the intro never blocks account access.
    }
    if (mounted) setState(() => _seen = seen);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await widget.store.markSeenIntro().timeout(_storageTimeout);
    } catch (_) {
      // Continue to access even on devices with unavailable local storage.
    }
    if (mounted) setState(() => _completedThisVisit = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_mobile || _seen == true || _completedThisVisit) {
      return WelcomeScreen(controller: widget.controller);
    }
    if (_seen == null) return const SplashScreen();
    return MobileIntroScreen(onComplete: _finish);
  }
}
