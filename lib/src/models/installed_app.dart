import 'app_manifest.dart';

class InstalledApp {
  const InstalledApp({
    required this.manifest,
    required this.bundlePath,
    required this.importedAt,
    required this.grantedPermissions,
    this.lastUsedAt,
  });

  final AppManifest manifest;
  final String bundlePath;
  final DateTime importedAt;
  final DateTime? lastUsedAt;
  final Map<AppCapability, bool> grantedPermissions;

  InstalledApp copyWith({
    AppManifest? manifest,
    String? bundlePath,
    DateTime? importedAt,
    DateTime? lastUsedAt,
    Map<AppCapability, bool>? grantedPermissions,
  }) {
    return InstalledApp(
      manifest: manifest ?? this.manifest,
      bundlePath: bundlePath ?? this.bundlePath,
      importedAt: importedAt ?? this.importedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
    );
  }

  factory InstalledApp.fromJson(Map<String, Object?> json) {
    final manifestJson = json['manifest'];
    if (manifestJson is! Map<String, Object?>) {
      throw const ManifestException('installed app manifest must be an object');
    }
    final permissionsJson = json['grantedPermissions'];
    if (permissionsJson is! Map<String, Object?>) {
      throw const ManifestException(
        'installed app grantedPermissions must be an object',
      );
    }
    final granted = <AppCapability, bool>{};
    for (final entry in permissionsJson.entries) {
      final capability = AppCapability.tryParse(entry.key);
      if (capability != null && entry.value is bool) {
        granted[capability] = entry.value! as bool;
      }
    }

    return InstalledApp(
      manifest: AppManifest.fromJson(manifestJson),
      bundlePath: _string(json, 'bundlePath'),
      importedAt: DateTime.parse(_string(json, 'importedAt')),
      lastUsedAt: json['lastUsedAt'] is String
          ? DateTime.parse(json['lastUsedAt']! as String)
          : null,
      grantedPermissions: granted,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'manifest': manifest.toJson(),
    'bundlePath': bundlePath,
    'importedAt': importedAt.toUtc().toIso8601String(),
    'lastUsedAt': lastUsedAt?.toUtc().toIso8601String(),
    'grantedPermissions': <String, bool>{
      for (final entry in grantedPermissions.entries)
        entry.key.key: entry.value,
    },
  };

  bool hasPermission(AppCapability capability) {
    return manifest.declares(capability) &&
        (grantedPermissions[capability] ?? false);
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw ManifestException('$key must be a non-empty string');
    }
    return value;
  }
}
