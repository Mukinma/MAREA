import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/chat/presentation/chat_privacy_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('changes chat requests and unblocks in a narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await authenticatedController();
    addTearDown(controller.dispose);
    final repo = _PrivacyRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ChatPrivacyScreen(controller: controller, repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Privacidad y bloqueos'), findsOneWidget);
    expect(find.text('Crear'), findsNothing);

    final following = find.text('Solo las cuentas que sigo');
    await tester.ensureVisible(following);
    await tester.pumpAndSettle();
    await tester.tap(following);
    await tester.pumpAndSettle();
    expect(repo.audience, ChatRequestAudience.following);

    repo.failWriting = true;
    final nobody = find.text('Nadie');
    await tester.ensureVisible(nobody);
    await tester.pumpAndSettle();
    await tester.tap(nobody);
    await tester.pumpAndSettle();
    expect(repo.audience, ChatRequestAudience.following);
    expect(find.text('Sin conexión'), findsOneWidget);

    repo.failWriting = false;
    final unblock = find.text('Desbloquear');
    await tester.ensureVisible(unblock);
    await tester.pumpAndSettle();
    await tester.tap(unblock);
    await tester.pumpAndSettle();
    expect(repo.blocks, isEmpty);
    expect(
      find.text('Tu lista de cuentas bloqueadas está vacía.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _PrivacyRepository implements ChatPrivacyRepository {
  var audience = ChatRequestAudience.everyone;
  var failWriting = false;
  final blocks = [
    const BlockedChatAccount(id: '1', fullName: 'Ana Ramos', username: 'ana'),
  ];

  @override
  Future<ChatPrivacySettings> privacySettings() async => ChatPrivacySettings(
    requestAudience: audience,
    blockedAccounts: List.of(blocks),
  );

  @override
  Future<void> setRequestAudience(ChatRequestAudience audience) async {
    if (failWriting) throw const AppFailure('Sin conexión');
    this.audience = audience;
  }

  @override
  Future<void> block(String targetId, bool blocked) async {
    expect(blocked, isFalse);
    blocks.removeWhere((account) => account.id == targetId);
  }
}
