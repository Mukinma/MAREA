import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class TourLocalStore {
  final _files = <String, Uint8List>{};
  Future<Map<String, dynamic>?> read(String account, String key) async {
    final value = (await SharedPreferences.getInstance()).getString(
      'tours:$account:$key',
    );
    return value == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    await (await SharedPreferences.getInstance()).setString(
      'tours:$account:$key',
      jsonEncode(data),
    );
  }

  Future<String> saveBytes(String account, String id, Uint8List bytes) async {
    final key = '$account/$id';
    _files[key] = bytes;
    return key;
  }

  Future<void> removeAccount(String account) async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (k) => k.startsWith('tours:$account:'),
    )) {
      await preferences.remove(key);
    }
    _files.removeWhere((key, _) => key.startsWith('$account/'));
  }

  Future<Uint8List> readBytes(String path) async {
    final b = _files[path];
    if (b == null) {
      throw StateError('Vuelve a elegir el archivo para continuar la carga.');
    }
    return b;
  }
}
