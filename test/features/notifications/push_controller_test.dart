import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/notifications/data/push_controller.dart';
import 'package:marea/features/notifications/data/push_gateway.dart';
import 'package:marea/features/notifications/data/notification_preferences_repository.dart';
import 'package:marea/features/notifications/models/notification_preferences.dart';
import 'package:marea/features/notifications/models/notification_destination.dart';

class Gateway implements PushGateway {
  final taps = StreamController<PushNotice>.broadcast();
  final tokens = StreamController<String>.broadcast();
  final messages = StreamController<ForegroundNotice>.broadcast();
  int presentations = 0, prompts = 0, resets = 0;
  bool failPrompt = false;
  Completer<void>? pendingReset;
  @override
  Stream<PushNotice> get opened => taps.stream;
  @override
  Stream<String> get tokenChanges => tokens.stream;
  @override
  Stream<ForegroundNotice> get received => messages.stream;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<PushPermission> permission() async => PushPermission.granted;
  @override
  Future<PushPermission> promptOnce() async {
    prompts++;
    if (failPrompt) throw StateError('permission_temporarily_unavailable');
    return PushPermission.granted;
  }

  @override
  Future<PushPermission> requestPermission() async => PushPermission.granted;
  @override
  Future<void> openSettings() async {}
  @override
  Future<String?> token() async => 'token';
  @override
  Future<String> installationId() async => 'installation';
  @override
  Future<String> timezone() async => 'America/Mexico_City';
  @override
  Future<void> present(ForegroundNotice message) async {
    presentations++;
  }

  @override
  Future<void> reset() async {
    resets++;
    await pendingReset?.future;
  }

  @override
  Future<void> dispose() async {
    await taps.close();
    await tokens.close();
    await messages.close();
  }
}

class InboxGateway extends Gateway {
  @override
  Future<bool> initialize() async => false;
}

class Preferences implements NotificationPreferencesRepository {
  NotificationPreferences value = const NotificationPreferences();
  Completer<NotificationPreferences>? pending;
  String? registered;
  bool failUnregister = false;
  bool failLoad = false;
  Completer<void>? pendingRegistration;
  int activities = 0;
  @override
  Future<NotificationPreferences> load() async {
    if (failLoad) throw StateError('offline');
    return pending == null ? value : pending!.future;
  }

  @override
  Future<void> save(NotificationPreferences p) async {
    value = p;
  }

  @override
  Future<void> recordActivity(String timezone) async {
    activities++;
  }

  @override
  Future<void> registerDevice(
    String installationId,
    String token,
    bool enabled,
  ) async {
    await pendingRegistration?.future;
    registered = token;
  }

  @override
  Future<void> unregisterDevice(String installationId) async {
    if (failUnregister) throw StateError('offline');
    registered = null;
  }

  @override
  Future<SocialNotification?> notification(String id) async => null;
}

void main() {
  test(
    'recovering initial data asks for the permission that was not shown',
    () async {
      final gateway = Gateway(), repo = Preferences()..failLoad = true;
      final c = PushController(repo, gateway);
      addTearDown(c.dispose);
      await c.setSession('user', ready: true);
      expect(gateway.prompts, 0);
      expect(c.error, isNotNull);
      repo.failLoad = false;
      await c.refresh();
      expect(gateway.prompts, 1);
      expect(repo.registered, 'token');
      expect(c.error, isNull);
    },
  );
  test('a failed permission request can be retried during recovery', () async {
    final gateway = Gateway()..failPrompt = true;
    final repo = Preferences();
    final c = PushController(repo, gateway);
    addTearDown(c.dispose);
    await c.setSession('user', ready: true);
    expect(gateway.prompts, 1);
    expect(repo.registered, isNull);
    gateway.failPrompt = false;
    await c.refresh();
    expect(gateway.prompts, 2);
    expect(repo.registered, 'token');
  });
  test(
    'inbox-only clients record activity and preferences without a transport',
    () async {
      final gateway = InboxGateway(), repo = Preferences();
      final c = PushController(repo, gateway);
      await c.setSession('user', ready: true);
      expect(c.configured, false);
      expect(repo.activities, 1);
      expect(gateway.prompts, 0);
      expect(repo.registered, isNull);
      await c.save(const NotificationPreferences(mareaMessages: false));
      expect(repo.value.mareaMessages, false);
      c.dispose();
    },
  );

  testWidgets('logout is bounded when registration hangs', (tester) async {
    final gateway = Gateway(), repo = Preferences();
    final c = PushController(repo, gateway);
    await c.setSession('user', ready: true);
    repo.pendingRegistration = Completer<void>();
    gateway.tokens.add('renewed');
    await tester.pump();
    var finished = false;
    final logout = c.endSession().then((_) => finished = true);
    await tester.pump(const Duration(seconds: 6));
    expect(finished, true);
    await logout;
    repo.pendingRegistration!.complete();
    await tester.pump();
    expect(gateway.resets, 1);
    c.dispose();
  });
  testWidgets(
    'new account waits for the actual native reset after logout timeout',
    (tester) async {
      final gateway = Gateway(), repo = Preferences();
      final c = PushController(repo, gateway);
      await c.setSession('old', ready: true);
      gateway.pendingReset = Completer<void>();
      final logout = c.endSession();
      await tester.pump(const Duration(seconds: 6));
      await logout;
      final newSession = c.setSession('new', ready: true);
      await tester.pump();
      expect(gateway.resets, 1);
      expect(repo.registered, isNull);
      gateway.pendingReset!.complete();
      await tester.pump();
      await newSession;
      expect(gateway.resets, 1);
      expect(repo.registered, 'token');
      c.dispose();
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'session preparation waits for access completion before prompting',
    () async {
      final gateway = Gateway(), repo = Preferences();
      final c = PushController(repo, gateway);
      addTearDown(c.dispose);
      await c.setSession('user', ready: false);
      expect(gateway.prompts, 0);
      await c.setSession('user', ready: true);
      expect(c.permissionStatus, PushPermission.granted);
      expect(repo.registered, 'token');
      expect(gateway.prompts, 1);
    },
  );
  test('a late preference response cannot revive a previous session', () async {
    final gateway = Gateway(), repo = Preferences()..pending = Completer();
    final c = PushController(repo, gateway);
    addTearDown(c.dispose);
    final old = c.setSession('old', ready: true);
    await Future<void>.delayed(Duration.zero);
    await c.setSession(null, ready: false);
    repo.pending!.complete(const NotificationPreferences(activity: false));
    await old;
    expect(c.preferences.activity, true);
    expect(repo.registered, isNull);
  });
  test('logout resets native state even when revocation is offline', () async {
    final gateway = Gateway(), repo = Preferences()..failUnregister = true;
    final c = PushController(repo, gateway);
    addTearDown(c.dispose);
    await c.setSession('user', ready: true);
    await c.endSession();
    expect(gateway.resets, 1);
  });
  test(
    'foreground notices are deduplicated and filtered by recipient',
    () async {
      final gateway = Gateway();
      final controller = PushController(Preferences(), gateway);
      addTearDown(controller.dispose);
      await controller.setSession('user', ready: true);
      const message = ForegroundNotice(
        notice: PushNotice(notificationId: 'n', recipientId: 'user'),
        version: '1',
        kind: 'comment',
        title: 'MAREA',
        body: 'Nuevo comentario',
      );
      gateway.messages.add(message);
      gateway.messages.add(message);
      gateway.messages.add(
        const ForegroundNotice(
          notice: PushNotice(notificationId: 'other', recipientId: 'other'),
          version: '1',
          kind: 'comment',
          title: 'MAREA',
          body: 'Otro usuario',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(gateway.presentations, 1);
    },
  );
}
