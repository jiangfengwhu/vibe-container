import 'dart:convert';
import 'dart:io';

import '../bridge/bridge_error.dart';
import '../bridge/bridge_payload.dart';

class AppStorage {
  AppStorage(this.rootDirectory);

  final Directory rootDirectory;
  final Map<String, Map<String, Object?>> _cache =
      <String, Map<String, Object?>>{};

  Future<Object?> get(String appId, String key) async {
    _validateKey(key);
    final data = await _readAppData(appId);
    return data[key];
  }

  Future<void> set(String appId, String key, Object? value) async {
    _validateKey(key);
    if (!isJsonSafeValue(value)) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'storage value must be JSON-safe',
      );
    }
    final data = await _readAppData(appId);
    data[key] = value;
    await _writeAppData(appId, data);
  }

  Future<void> remove(String appId, String key) async {
    _validateKey(key);
    final data = await _readAppData(appId);
    data.remove(key);
    await _writeAppData(appId, data);
  }

  Future<void> clear(String appId) async {
    await _writeAppData(appId, <String, Object?>{});
  }

  Future<void> delete(String appId) async {
    final safeAppId = _safeAppId(appId);
    _cache.remove(safeAppId);
    final file = File('${rootDirectory.path}/$safeAppId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Map<String, Object?>> _readAppData(String appId) async {
    final safeAppId = _safeAppId(appId);
    final cached = _cache[safeAppId];
    if (cached != null) {
      return cached;
    }

    await rootDirectory.create(recursive: true);
    final file = File('${rootDirectory.path}/$safeAppId.json');
    if (!await file.exists()) {
      final empty = <String, Object?>{};
      _cache[safeAppId] = empty;
      return empty;
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?> || !isJsonSafeValue(decoded)) {
      throw const BridgeException(
        BridgeErrorCode.internalError,
        'stored data is corrupted',
      );
    }
    _cache[safeAppId] = decoded;
    return decoded;
  }

  Future<void> _writeAppData(String appId, Map<String, Object?> data) async {
    final safeAppId = _safeAppId(appId);
    await rootDirectory.create(recursive: true);
    final file = File('${rootDirectory.path}/$safeAppId.json');
    await file.writeAsString(jsonEncode(data), flush: true);
    _cache[safeAppId] = Map<String, Object?>.from(data);
  }

  static String _safeAppId(String appId) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{2,63}$').hasMatch(appId)) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'invalid appId',
      );
    }
    return appId;
  }

  static void _validateKey(String key) {
    if (key.isEmpty || key.length > 128 || key.contains('/')) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'storage key must be 1-128 chars and cannot contain slash',
      );
    }
  }
}
