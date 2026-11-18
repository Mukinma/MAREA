import 'dart:convert';
import 'dart:js_interop';

@JS('mareaLocalTranslationSupported')
external JSBoolean _mareaLocalTranslationSupported();

@JS('mareaTranslateLocally')
external JSPromise<JSString> _mareaTranslateLocally(
  JSString text,
  JSString targetLanguage,
);

bool get isSupported => _mareaLocalTranslationSupported().toDart;

Future<String> translate({
  required String text,
  required String targetLanguage,
}) async {
  final encoded = await _mareaTranslateLocally(
    text.toJS,
    targetLanguage.toJS,
  ).toDart;
  final response = jsonDecode(encoded.toDart);
  if (response is! Map<String, dynamic>) {
    throw StateError('model_unavailable');
  }
  final error = response['error'];
  if (error is String) throw StateError(error);
  final translated = response['text'];
  if (translated is! String) throw StateError('model_unavailable');
  return translated;
}
