import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:marea/app.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:marea/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Run sequentially with one isolated local database: create, apply, select.
/// Supply the disposable account via an untracked --dart-define-from-file.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const step = String.fromEnvironment('QA_STEP');
  const title = String.fromEnvironment('QA_MISSION');
  testWidgets('mission parity $step', (tester) async {
    final config = AppConfig.fromEnvironment();
    final host = Uri.parse(config.supabaseUrl).host;
    expect(config.isDevelopment && {'localhost','127.0.0.1','10.0.2.2'}.contains(host), isTrue);
    expect({'create','apply','select','read'}.contains(step) && title.startsWith('QA '), isTrue);
    await app.main();
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 160 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
    }
    Future<void> tap(Finder finder) async {
      await waitFor(finder);
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 12));
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 350));
    }
    await waitFor(find.byType(MareaApp));
    final db = Supabase.instance.client;
    await db.auth.signInWithPassword(email: const String.fromEnvironment('QA_EMAIL'), password: const String.fromEnvironment('QA_PASSWORD'));
    await waitFor(find.byType(AppShell));
    final router = GoRouter.of(tester.element(find.byType(AppShell)));
    Future<void> go(String route) async {
      router.go(route);
      await tester.pump(const Duration(milliseconds: 350));
    }
    for (final row in {'/explore?section=saved':'/profile/saved','/explore?section=people':'/search/people','/explore':'/home'}.entries) {
      await go(row.key);
      expect(router.routeInformationProvider.value.uri.path, row.value);
    }
    final session = tester.widget<MareaApp>(find.byType(MareaApp)).controller;
    final repo = session.communityRepository!;
    if (step == 'create') {
      // Seed an incomplete private draft. Publish from the real four-step form.
      const draftId = String.fromEnvironment('QA_DRAFT_ID');
      await repo.saveMissionDraft({
        'title': title, 'body': 'Colaboración de prueba entre tres plataformas.',
        'category': 'otros', 'location': 'Centro cultural QA', 'capacity': 1,
        'starts_at': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
        'compensation_type': 'negotiable',
      }, id: draftId);
      await go('/missions/drafts/$draftId/edit');
      for (var i = 0; i < 3; i++) {
        await tap(find.text('Continuar'));
      }
      await tap(find.text('Publicar misión'));
    }
    Future<String> publishedId() async {
      for (var i = 0; i < 40; i++) {
        final rows = await db.from('missions').select('id').eq('title', title);
        if (rows.isNotEmpty) return rows.single['id'] as String;
        await tester.pump(const Duration(milliseconds: 250));
      }
      throw StateError('Missing published QA mission');
    }
    final id = await publishedId();
    if (step == 'apply') {
      await go('/missions/$id/apply');
      await tap(find.text('Continuar'));
      final form = find.byType(TextFormField).first;
      await waitFor(form);
      await tester.enterText(form, 'Puedo colaborar en la actividad de prueba.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(find.byType(CheckboxListTile));
      await tap(find.text('Revisar candidatura'));
      await tap(find.text('Enviar candidatura'));
      await waitFor(find.text('¡Tu candidatura ya está en movimiento!'));
    } else if (step == 'select') {
      await go('/missions/$id/manage');
      await tap(find.text('Marcar finalista'));
      await tap(find.textContaining('Confirmar selección (1)'));
      await tap(find.text('Confirmar participantes'));
    }
    if (step != 'create') {
      final status = step == 'apply' ? 'pending' : 'accepted';
      var persisted = false;
      for (var i = 0; i < 40 && !persisted; i++) {
        final rows = await repo.applications(missionId: id);
        persisted = rows.any((row) => row.status == status);
        if (!persisted) await tester.pump(const Duration(milliseconds: 200));
      }
      expect(persisted, isTrue, reason: 'Persisted application status $status');
    }
    await go('/missions/$id');
    await waitFor(find.text(title));
    await db.auth.signOut();
  }, timeout: const Timeout(Duration(minutes: 4)));
}
