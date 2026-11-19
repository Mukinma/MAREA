import 'dart:js_interop';

@JS('mareaPush.listen')
external void _listen(JSFunction? callback);

@JS('mareaPush.absoluteWorkerUrl')
external String absoluteWorkerUrl(String path);

@JS('mareaPush.show')
external JSPromise<JSAny?> _show(
  String title,
  String body,
  String payload,
  bool quiet,
);

@JS('mareaPush.clear')
external JSPromise<JSAny?> _clear();

void listen(void Function(String) opened) => _listen(opened.toJS);
void stopListening() => _listen(null);
Future<void> show(String title, String body, String payload, bool quiet) async {
  await _show(title, body, payload, quiet).toDart;
}

Future<void> clear() async {
  await _clear().toDart;
}
