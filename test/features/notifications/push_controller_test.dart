import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/notifications/data/push_controller.dart';
import 'package:marea/features/notifications/data/push_gateway.dart';
import 'package:marea/features/notifications/data/notification_preferences_repository.dart';
import 'package:marea/features/notifications/models/notification_preferences.dart';
import 'package:marea/features/notifications/models/notification_destination.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class Gateway implements PushGateway {
  final taps = StreamController<PushNotice>.broadcast();
  final tokens = StreamController<String>.broadcast();
  final messages = StreamController<ForegroundNotice>.broadcast();
  int presentations = 0, prompts = 0, resets = 0, settingsOpened = 0;
  PushPermission permissionValue = PushPermission.granted;
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
  Future<PushPermission> permission() async => permissionValue;
  @override
  Future<PushPermission> promptOnce() async {
    prompts++;
    if (failPrompt) throw StateError('permission_temporarily_unavailable');
    return permissionValue;
  }

  @override
  Future<PushPermission> requestPermission() async => permissionValue;
  @override
  Future<void> openSettings() async {
    settingsOpened++;
  }

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
  bool failSave = false;
  SocialNotification? notificationValue;
  Completer<void>? pendingRegistration;
  int activities = 0;
  @override
  Future<NotificationPreferences> load() async {
    if (failLoad) throw StateError('offline');
    return pending == null ? value : pending!.future;
  }

  @override
  Future<NotificationPreferences> setCategory(
    NotificationCategory category,
    bool enabled,
  ) async {
    if (failSave) throw StateError('offline');
    return value = value.withCategory(category, enabled);
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
  Future<SocialNotification?> notification(String id) async =>
      notificationValue;
}

void main() {
  test('stored categories override the effective legacy preferences', () {
    final preferences = NotificationPreferences.fromJson({
      'activity_enabled': false,
      'marea_enabled': false,
      'chat_enabled': true,
      'missions_enabled': true,
    });
    expect(preferences.isEnabled(NotificationCategory.chat), isTrue);
    expect(preferences.isEnabled(NotificationCategory.missions), isTrue);
    expect(preferences.isEnabled(NotificationCategory.reactions), isFalse);
    expect(preferences.isEnabled(NotificationCategory.reminders), isFalse);
  });
  testWidgets(
    'notification settings expose real controls at 320 dp and 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final gateway = Gateway()..permissionValue = PushPermission.denied;
      final repository = Preferences()..failLoad = true;
      final push = PushController(repository, gateway);
      final auth = FakeAuthRepository();
      final session = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        push: push,
      );
      addTearDown(auth.close);
      addTearDown(session.dispose);
      await push.setSession('user', ready: true);
      await tester.pumpWidget(
        testApp(AccountNotificationsScreen(controller: session)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      Future<void> tap(String label) async {
        final target = find.text(label);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      repository.failLoad = false;
      await tap('Reintentar');
      expect(find.text('Reintentar'), findsNothing);
      await tap('Abrir ajustes del dispositivo');
      expect(gateway.settingsOpened, 1);
      await tap('Mensajes y solicitudes de chat');
      await tap('Recordatorios de MAREA');
      expect(repository.value.isEnabled(NotificationCategory.chat), isFalse);
      expect(
        repository.value.isEnabled(NotificationCategory.reminders),
        isFalse,
      );
      expect(repository.value.isEnabled(NotificationCategory.missions), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await push.endSession();
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

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
      await c.setCategory(NotificationCategory.reminders, false);
      expect(repo.value.isEnabled(NotificationCategory.reminders), isFalse);
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
    repo.pending!.complete(
      const NotificationPreferences().withCategory(
        NotificationCategory.comments,
        false,
      ),
    );
    await old;
    expect(c.preferences.isEnabled(NotificationCategory.comments), isTrue);
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
  test('muted categories filter foreground banners independently', () async {
    final gateway = Gateway(), repo = Preferences();
    final controller = PushController(repo, gateway);
    addTearDown(controller.dispose);
    await controller.setSession('user', ready: true);
    await controller.setCategory(NotificationCategory.reminders, false);
    await controller.setCategory(NotificationCategory.reactions, false);
    for (final category in [
      NotificationCategory.chat,
      NotificationCategory.reminders,
      NotificationCategory.reactions,
    ]) {
      gateway.messages.add(
        ForegroundNotice(
          notice: PushNotice(
            notificationId: category.name,
            recipientId: 'user',
          ),
          version: '1',
          kind: 'marea_message',
          category: category,
          title: 'MAREA',
          body: 'Una prueba',
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);
    expect(gateway.presentations, 1);
  });

  test('legacy ambiguous foreground notices use their event key', () async {
    final gateway = Gateway(), repo = Preferences();
    final controller = PushController(repo, gateway);
    addTearDown(controller.dispose);
    await controller.setSession('user', ready: true);
    await controller.setCategory(NotificationCategory.reminders, false);
    final createdAt = DateTime.utc(2026, 11, 18);
    repo.notificationValue = SocialNotification(
      id: 'chat',
      recipientId: 'user',
      actorId: 'author',
      postId: null,
      kind: NotificationKind.mareaMessage,
      postTitle: 'Un mensaje',
      createdAt: createdAt,
      eventKey: 'chat_message:conversation',
    );
    gateway.messages.add(
      ForegroundNotice(
        notice: const PushNotice(notificationId: 'chat', recipientId: 'user'),
        version: createdAt.toIso8601String(),
        kind: 'marea_message',
        title: 'MAREA',
        body: 'Un mensaje',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.presentations, 1);
  });

  test('a failed save restores the category preference', () async {
    final gateway = Gateway(), repo = Preferences()..failSave = true;
    final controller = PushController(repo, gateway);
    addTearDown(controller.dispose);
    await controller.setSession('user', ready: true);
    await controller.setCategory(NotificationCategory.chat, false);
    expect(controller.preferences.isEnabled(NotificationCategory.chat), isTrue);
    expect(controller.error, isNotNull);
  });
}
