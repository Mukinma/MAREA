import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:marea/core/localization/content_translation_service.dart';

class TranslatedPostContent {
  const TranslatedPostContent({
    required this.title,
    required this.body,
    required this.alreadyInTargetLanguage,
  });

  final String title;
  final String body;
  final bool alreadyInTargetLanguage;
}

enum PostTranslationFailure {
  languageUndetermined,
  unsupportedLanguage,
  modelUnavailable,
}

class PostTranslationException implements Exception {
  const PostTranslationException(this.failure);

  final PostTranslationFailure failure;
}

abstract interface class PostContentTranslator {
  bool get isSupported;

  Future<TranslatedPostContent> translate({
    required String title,
    required String body,
    required String targetLanguage,
  });
}

class CrossPlatformPostContentTranslator implements PostContentTranslator {
  const CrossPlatformPostContentTranslator({
    required this.onDevice,
    required this.cloud,
  });

  final PostContentTranslator onDevice;
  final ContentTranslationService cloud;

  @override
  bool get isSupported => true;

  @override
  Future<TranslatedPostContent> translate({
    required String title,
    required String body,
    required String targetLanguage,
  }) async {
    if (onDevice.isSupported) {
      return onDevice.translate(
        title: title,
        body: body,
        targetLanguage: targetLanguage,
      );
    }

    try {
      final translated = await Future.wait([
        cloud.translate(text: title, targetLanguage: targetLanguage),
        body.isEmpty
            ? Future<String>.value(body)
            : cloud.translate(text: body, targetLanguage: targetLanguage),
      ]);
      return TranslatedPostContent(
        title: translated[0],
        body: translated[1],
        alreadyInTargetLanguage:
            translated[0] == title && translated[1] == body,
      );
    } on StateError {
      throw const PostTranslationException(
        PostTranslationFailure.modelUnavailable,
      );
    }
  }
}

class MlKitPostContentTranslator implements PostContentTranslator {
  final _cache = <String, TranslatedPostContent>{};
  final _pending = <String, Future<TranslatedPostContent>>{};

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<TranslatedPostContent> translate({
    required String title,
    required String body,
    required String targetLanguage,
  }) {
    if (!isSupported) {
      throw UnsupportedError('On-device translation is not supported here.');
    }

    final target = BCP47Code.fromRawValue(targetLanguage);
    if (target == null) {
      throw const PostTranslationException(
        PostTranslationFailure.unsupportedLanguage,
      );
    }

    final key = '$targetLanguage\u0000$title\u0000$body';
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    return _pending.putIfAbsent(key, () async {
      try {
        final translated = await _translate(title, body, target);
        _cache[key] = translated;
        return translated;
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<TranslatedPostContent> _translate(
    String title,
    String body,
    TranslateLanguage target,
  ) async {
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    late final String sourceCode;
    try {
      sourceCode = await identifier.identifyLanguage('$title\n$body');
    } on PlatformException {
      throw const PostTranslationException(
        PostTranslationFailure.modelUnavailable,
      );
    } on MissingPluginException {
      throw const PostTranslationException(
        PostTranslationFailure.modelUnavailable,
      );
    } finally {
      await identifier.close();
    }

    if (sourceCode == 'und') {
      throw const PostTranslationException(
        PostTranslationFailure.languageUndetermined,
      );
    }
    final source = BCP47Code.fromRawValue(sourceCode);
    if (source == null) {
      throw const PostTranslationException(
        PostTranslationFailure.unsupportedLanguage,
      );
    }
    if (source == target) {
      return TranslatedPostContent(
        title: title,
        body: body,
        alreadyInTargetLanguage: true,
      );
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return TranslatedPostContent(
        title: await translator.translateText(title),
        body: body.isEmpty ? body : await translator.translateText(body),
        alreadyInTargetLanguage: false,
      );
    } on PlatformException {
      throw const PostTranslationException(
        PostTranslationFailure.modelUnavailable,
      );
    } on MissingPluginException {
      throw const PostTranslationException(
        PostTranslationFailure.modelUnavailable,
      );
    } finally {
      await translator.close();
    }
  }
}
