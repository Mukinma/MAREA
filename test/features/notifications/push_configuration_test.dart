import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/notifications/data/push_configuration.dart';

void main() {
  PushConfiguration? config({
    bool development = false,
    bool pilot = false,
    bool web = false,
    TargetPlatform platform = TargetPlatform.android,
    String app = '1:123:android:abc',
    String project = 'isolated',
    String designated = '',
    String production = '',
    String vapid = '',
  }) => PushConfiguration.forBuild(
    development: development,
    pilot: pilot,
    web: web,
    platform: platform,
    apiKey: 'public-test',
    appId: app,
    sender: '123',
    project: project,
    testProject: designated,
    productionProject: production,
    vapidKey: vapid,
  );

  test('each platform requires its own registration, Web also needs VAPID', () {
    expect(config(), isNotNull);
    expect(config(platform: TargetPlatform.iOS), isNull);
    expect(
      config(platform: TargetPlatform.iOS, app: '1:123:ios:abc'),
      isNotNull,
    );
    expect(config(web: true, app: '1:123:web:abc'), isNull);
    expect(config(web: true, app: '1:123:web:abc', vapid: 'public'), isNotNull);
    expect(config(platform: TargetPlatform.linux), isNull);
    expect(config(app: ''), isNull);
  });

  test('only a designated isolated project may be used in development', () {
    expect(config(development: true), isNull);
    expect(
      config(development: true, designated: 'isolated', production: 'prod'),
      isNotNull,
    );
    expect(
      config(development: true, designated: 'isolated', production: 'isolated'),
      isNull,
    );
    expect(config(development: true, designated: 'isolated'), isNull);
    expect(
      config(
        development: true,
        designated: 'marea-f6a92',
        project: 'marea-f6a92',
        production: 'other',
      ),
      isNull,
    );
    expect(config(pilot: true), isNull);
  });
}
