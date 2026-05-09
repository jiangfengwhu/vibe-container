import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_manifest.dart';
import '../models/installed_app.dart';

class AppLibrary extends ChangeNotifier {
  AppLibrary(this.rootDirectory);

  final Directory rootDirectory;
  final List<InstalledApp> _apps = <InstalledApp>[];
  bool _loaded = false;

  List<InstalledApp> get apps => List<InstalledApp>.unmodifiable(_apps);

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    await rootDirectory.create(recursive: true);
    final file = _indexFile;
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) {
        _apps
          ..clear()
          ..addAll(
            decoded.whereType<Map<String, Object?>>().map(
              InstalledApp.fromJson,
            ),
          );
      }
    }
    _loaded = true;
    notifyListeners();
  }

  InstalledApp? findById(String appId) {
    for (final app in _apps) {
      if (app.manifest.id == appId) {
        return app;
      }
    }
    return null;
  }

  Future<void> upsert(InstalledApp app) async {
    final index = _apps.indexWhere(
      (candidate) => candidate.manifest.id == app.manifest.id,
    );
    if (index >= 0) {
      _apps[index] = app;
    } else {
      _apps.add(app);
    }
    _apps.sort(
      (left, right) => (right.lastUsedAt ?? right.importedAt).compareTo(
        left.lastUsedAt ?? left.importedAt,
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> remove(String appId) async {
    final index = _apps.indexWhere((app) => app.manifest.id == appId);
    if (index < 0) {
      return;
    }
    final app = _apps.removeAt(index);
    final bundleDirectory = Directory(app.bundlePath);
    if (await bundleDirectory.exists()) {
      await bundleDirectory.delete(recursive: true);
    }
    await _save();
    notifyListeners();
  }

  Future<void> setLastUsed(String appId, DateTime usedAt) async {
    final app = findById(appId);
    if (app == null) {
      return;
    }
    await upsert(app.copyWith(lastUsedAt: usedAt));
  }

  Future<void> setPermission(
    String appId,
    AppCapability capability,
    bool granted,
  ) async {
    final app = findById(appId);
    if (app == null || !app.manifest.declares(capability)) {
      return;
    }
    await upsert(
      app.copyWith(
        grantedPermissions: <AppCapability, bool>{
          ...app.grantedPermissions,
          capability: granted,
        },
      ),
    );
  }

  Future<void> setImmersive(String appId, AppImmersiveConfig override) async {
    final app = findById(appId);
    if (app == null) {
      return;
    }
    await upsert(app.copyWith(immersiveOverride: override));
  }

  Future<void> clearImmersiveOverride(String appId) async {
    final app = findById(appId);
    if (app == null) {
      return;
    }
    await upsert(app.copyWith(clearImmersiveOverride: true));
  }

  Future<void> _save() async {
    await rootDirectory.create(recursive: true);
    await _indexFile.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(_apps.map((app) => app.toJson()).toList()),
    );
  }

  File get _indexFile => File('${rootDirectory.path}/apps.json');
}
