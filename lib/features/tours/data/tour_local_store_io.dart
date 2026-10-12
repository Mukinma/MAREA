import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class TourLocalStore {
  Future<Directory> _directory(String account) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(account)) {
      throw ArgumentError('Cuenta inválida');
    }
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/tours/$account',
    );
    await dir.create(recursive: true);
    return dir;
  }

  String _key(String key) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw ArgumentError('Clave inválida');
    }
    return key;
  }

  Future<Map<String, dynamic>?> read(String account, String key) async {
    final f = File('${(await _directory(account)).path}/${_key(key)}.json');
    if (!await f.exists()) return null;
    return Map<String, dynamic>.from(jsonDecode(await f.readAsString()) as Map);
  }

  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    final f = File('${(await _directory(account)).path}/${_key(key)}.json');
    final temp = File('${f.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    await temp.rename(f.path);
  }

  Future<String> saveBytes(String account, String id, Uint8List bytes) async {
    final f = File('${(await _directory(account)).path}/${_key(id)}.jpg');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  Future<void> removeAccount(String account) async {
    final directory = await _directory(account);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<Uint8List> readBytes(String path) => File(path).readAsBytes();
}
