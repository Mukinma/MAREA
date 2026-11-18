import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/localization/on_device_post_translator.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'mission translation uses the device translator and restores text',
    (tester) async {
      await AppLocalizations.delegate.load(const Locale('es', 'MX'));
      addTearDown(
        () => AppLocalizations.delegate.load(const Locale('es', 'MX')),
      );
      final translator = _MissionTranslator();
      Map<String, String>? translated;

      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Text(translated?['title'] ?? 'Convocatoria'),
                  Text(translated?['body'] ?? 'Descripción de la misión'),
                  MissionTranslationAction(
                    content: const {
                      'title': 'Convocatoria',
                      'body': 'Descripción de la misión',
                    },
                    translator: translator,
                    onChanged: (value) => setState(() => translated = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Traducir misión'));
      await tester.pumpAndSettle();
      expect(find.text('EN Convocatoria'), findsOneWidget);
      expect(find.text('EN Descripción de la misión'), findsOneWidget);
      expect(translator.translated, [
        'Convocatoria',
        'Descripción de la misión',
      ]);

      await tester.tap(find.text('Ver original'));
      await tester.pumpAndSettle();
      expect(find.text('Convocatoria'), findsOneWidget);
      expect(find.text('Descripción de la misión'), findsOneWidget);
    },
  );

  testWidgets('mission translation control stays hidden when unsupported', (
    tester,
  ) async {
    final translator = _MissionTranslator(supported: false);
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Column(
            children: [
              const Text('Convocatoria'),
              MissionTranslationAction(
                content: const {'title': 'Convocatoria'},
                translator: translator,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Convocatoria'), findsOneWidget);
    expect(find.text('Traducir misión'), findsNothing);
    expect(translator.translated, isEmpty);
  });
}

class _MissionTranslator implements PostContentTranslator {
  _MissionTranslator({this.supported = true});

  final bool supported;
  final translated = <String>[];

  @override
  bool get isSupported => supported;

  @override
  Future<TranslatedPostContent> translate({
    required String title,
    required String body,
    required String targetLanguage,
  }) async {
    translated.add(title);
    return TranslatedPostContent(
      title: 'EN $title',
      body: body,
      alreadyInTargetLanguage: false,
    );
  }
}
