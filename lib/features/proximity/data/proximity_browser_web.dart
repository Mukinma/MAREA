import 'dart:convert';
import 'dart:js_interop';

@JS('document.hidden')
external bool get _hidden;
@JS('isSecureContext')
external bool get _secure;
@JS('navigator.geolocation')
external JSObject? get _geolocation;
@JS('navigator.locks')
external _Locks? get _locks;
@JS('localStorage')
external _Storage get _storage;

extension type _Locks(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> request(String name, JSFunction callback);
}
extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

bool get browserLocationSupported => _secure && _geolocation != null;
bool get proximityPageVisible => !_hidden;

String _key(String account) => 'marea.proximity.recent.$account';

/// Two visible windows may receive the same GPS fix. Serialize the short
/// cooldown claim across same-origin tabs without saving a device location.
Future<bool> claimBrowserAlert(
  String account,
  String target,
  DateTime now,
) async {
  final key = _key(account);
  bool claim() {
    if (_hidden) return false;
    try {
      final raw = _storage.getItem(key);
      final previous = raw == null ? null : jsonDecode(raw);
      final cutoff = now
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      final recent = <String, int>{
        if (previous is Map<String, dynamic>)
          for (final item in previous.entries)
            if (item.value is int && (item.value as int) > cutoff)
              item.key: item.value as int,
      };
      if (recent.containsKey(target)) return false;
      recent[target] = now.millisecondsSinceEpoch;
      _storage.setItem(key, jsonEncode(recent));
    } catch (_) {
      // Private browsing can limit storage. The per-page detector still applies.
    }
    return true;
  }

  final locks = _locks;
  if (locks == null) return claim();
  try {
    return (await locks
            .request(key, ((JSObject _) => claim().toJS).toJS)
            .toDart)
        .toDart;
  } catch (_) {
    return claim();
  }
}

void clearBrowserAlerts(String account) {
  try {
    _storage.removeItem(_key(account));
  } catch (_) {}
}
