import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Each platform is built with its own public Firebase app registration.
class PushConfiguration {
  const PushConfiguration({required this.options, required this.vapidKey});

  final FirebaseOptions options;
  final String vapidKey;

  static PushConfiguration? forBuild({
    required bool development,
    required bool pilot,
    required bool web,
    required TargetPlatform platform,
    String apiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
    String appId = const String.fromEnvironment('FIREBASE_APP_ID'),
    String sender = const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    String project = const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    String vapidKey = const String.fromEnvironment('FIREBASE_WEB_VAPID_KEY'),
    String testProject = const String.fromEnvironment(
      'MAREA_TEST_FIREBASE_PROJECT_ID',
    ),
    String productionProject = const String.fromEnvironment(
      'MAREA_PRODUCTION_FIREBASE_PROJECT_ID',
    ),
  }) {
    if (pilot || [apiKey, appId, sender, project].any((v) => v.isEmpty)) {
      return null;
    }
    if (development &&
        (!kDebugMode ||
            testProject != project ||
            productionProject.isEmpty ||
            project == productionProject ||
            project == 'marea-f6a92')) {
      return null;
    }
    final transport = web
        ? 'web'
        : switch (platform) {
            TargetPlatform.android => 'android',
            TargetPlatform.iOS => 'ios',
            _ => null,
          };
    if (transport == null ||
        !appId.startsWith('1:$sender:$transport:') ||
        web && vapidKey.isEmpty) {
      return null;
    }
    return PushConfiguration(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: sender,
        projectId: project,
      ),
      vapidKey: vapidKey,
    );
  }
}
