import 'dart:js_interop';

const _key = 'marea.access.returnTo';
const _lifetime = Duration(minutes: 10);

@JS('sessionStorage')
external _SessionStorage get _sessionStorage;

extension type _SessionStorage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

String? readAccessDestination() {
  try {
    final value = _sessionStorage.getItem(_key);
    if (value == null) return null;
    final separator = value.indexOf('\n');
    if (separator > 0) {
      final expires = int.tryParse(value.substring(0, separator));
      if (expires != null && expires > DateTime.now().millisecondsSinceEpoch) {
        return value.substring(separator + 1);
      }
    }
    _sessionStorage.removeItem(_key);
  } catch (_) {
    // Browsers can disable storage. In-app routing still works in memory.
  }
  return null;
}

void writeAccessDestination(String? destination) {
  try {
    if (destination == null) {
      _sessionStorage.removeItem(_key);
    } else {
      final expires = DateTime.now().add(_lifetime).millisecondsSinceEpoch;
      _sessionStorage.setItem(_key, '$expires\n$destination');
    }
  } catch (_) {
    // Browsers can disable storage. In-app routing still works in memory.
  }
}
