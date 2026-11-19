import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/chat/presentation/chat_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('opens a sent request on mobile and returns to its inbox', (
    tester,
  ) async {
    final chat = _Chat();
    await _openInbox(tester, chat, width: 390);
    await tester.tap(find.text('Los Pollos Hermanos'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatConversationScreen), findsOneWidget);
    expect(find.textContaining('Podrás escribir'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitud enviada'), findsOneWidget);

    await tester.tap(find.text('Los Pollos Hermanos'));
    await tester.pumpAndSettle();
    chat.status = 'accepted';
    await tester.tap(find.text('Actualizar estado'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a notification opens an incoming request on mobile', (
    tester,
  ) async {
    final chat = _Chat(incoming: true);
    final router = await _openInbox(
      tester,
      chat,
      width: 390,
      notification: true,
    );
    expect(router.state.uri.path, '/messages/chat-1');
    expect(find.text('Ver perfil'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(chat.status, 'accepted');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('rejects a request in the wide conversation panel', (
    tester,
  ) async {
    final chat = _Chat(incoming: true);
    final router = await _openInbox(
      tester,
      chat,
      width: 1024,
      notification: true,
    );
    expect(router.state.uri.path, '/messages');
    expect(find.byType(ChatConversationScreen), findsOneWidget);
    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(chat.status, 'rejected');
    expect(find.text('Esta solicitud de chat fue rechazada.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('keeps a failed draft and send stays above the keyboard', (
    tester,
  ) async {
    const longName = 'Colectivo de Arte y Cultura Los Pollos Hermanos';
    final chat = _Chat(status: 'accepted', otherName: longName)
      ..failSend = true;
    await _openInbox(tester, chat, width: 320, textScale: 2);
    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.enterText(find.byType(TextField), 'Hola, ¿cómo estás?');
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byTooltip('Enviar')).dy, lessThan(390));
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Hola, ¿cómo estás?',
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    chat.failSend = false;
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, ¿cómo estás?'), findsOneWidget);
  });

  testWidgets('a missing direct chat link returns to inbox and home', (
    tester,
  ) async {
    final router = await _openInbox(
      tester,
      _Chat(),
      width: 390,
      initialLocation: '/messages/missing',
    );
    expect(find.text('Este chat ya no está disponible.'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/messages');
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/home');
  });
}

Future<GoRouter> _openInbox(
  WidgetTester tester,
  _Chat chat, {
  required double width,
  bool notification = false,
  String initialLocation = '/messages',
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 650);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    legalRepository: FakeLegalRepository(),
    chatRepository: chat,
  );
  await controller.initialize();
  final router = GoRouter(
    initialLocation: notification
        ? '/messages?conversation=chat-1'
        : initialLocation,
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('Inicio')),
      GoRoute(
        path: '/messages',
        builder: (_, state) => ChatInboxScreen(
          controller: controller,
          initialConversationId: state.uri.queryParameters['conversation'],
        ),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (_, state) => ChatConversationScreen(
          controller: controller,
          conversationId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    controller.dispose();
  });
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'MX')],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _Chat implements ChatRepository {
  _Chat({
    this.status = 'pending',
    this.incoming = false,
    this.otherName = 'Los Pollos Hermanos',
  });

  String status;
  final bool incoming;
  final String otherName;
  bool failSend = false;
  final _messages = <ChatMessage>[];

  @override
  Future<List<ChatConversation>> conversations() async => [
    ChatConversation(
      id: 'chat-1',
      requesterId: incoming ? 'other' : sampleProfile.id,
      recipientId: incoming ? sampleProfile.id : 'other',
      status: status,
      createdAt: DateTime.utc(2026, 10, 1),
      otherName: otherName,
      otherUsername: 'los-pollos',
    ),
  ];

  @override
  Future<void> accept(String id) async => status = 'accepted';

  @override
  Future<void> reject(String id) async => status = 'rejected';

  @override
  Stream<void> changes(String id) => const Stream.empty();

  @override
  Future<List<ChatMessage>> messages(String id) async => List.of(_messages);

  @override
  Future<String> send(String id, String body) async {
    if (failSend) throw const AppFailure('Sin conexión');
    _messages.insert(
      0,
      ChatMessage(
        id: 'message-1',
        conversationId: id,
        senderId: sampleProfile.id,
        body: body,
        createdAt: DateTime.utc(2026, 10, 1, 10),
      ),
    );
    return 'message-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
