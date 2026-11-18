bool get isSupported => false;

Future<String> translate({
  required String text,
  required String targetLanguage,
}) async {
  throw UnsupportedError('Local browser translation is not supported.');
}
