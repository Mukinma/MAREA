import 'package:supabase_flutter/supabase_flutter.dart';

class ContentTranslationService {
  ContentTranslationService(this._client);

  final SupabaseClient _client;
  final Map<String, Future<String>> _pending = {};
  final Map<String, String> _cache = {};

  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'es',
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty || targetLanguage == sourceLanguage) {
      return Future.value(text);
    }

    final key = '$sourceLanguage:$targetLanguage:$normalized';
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    return _pending.putIfAbsent(key, () async {
      try {
        final response = await _client.functions.invoke(
          'translate-content',
          body: {
            'text': normalized,
            'sourceLanguage': sourceLanguage,
            'targetLanguage': targetLanguage,
          },
        );
        if (response.status != 200 || response.data is! Map) {
          throw StateError('translation_unavailable');
        }
        final translated = (response.data as Map)['text'];
        if (translated is! String || translated.trim().isEmpty) {
          throw StateError('translation_invalid_response');
        }
        _cache[key] = translated;
        return translated;
      } finally {
        _pending.remove(key);
      }
    });
  }
}
