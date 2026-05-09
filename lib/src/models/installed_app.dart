import 'app_manifest.dart';

class InstalledApp {
  const InstalledApp({
    required this.manifest,
    required this.bundlePath,
    required this.importedAt,
    required this.grantedPermissions,
    this.lastUsedAt,
    this.immersiveOverride,
    this.remoteSource,
  });

  final AppManifest manifest;
  final String bundlePath;
  final DateTime importedAt;
  final DateTime? lastUsedAt;
  final Map<AppCapability, bool> grantedPermissions;

  /// 用户在管理页里覆盖的沉浸式配置。`null` 表示沿用 manifest 默认。
  final AppImmersiveConfig? immersiveOverride;

  /// 第一次远程导入时使用的 bundle key 或下载 URL，用于"更新"时按原始包名重新下载。
  /// 本地文件导入时为 `null`。
  final String? remoteSource;

  /// 当前生效的沉浸式配置：override > manifest。
  AppImmersiveConfig get effectiveImmersive {
    return immersiveOverride ?? manifest.immersive;
  }

  InstalledApp copyWith({
    AppManifest? manifest,
    String? bundlePath,
    DateTime? importedAt,
    DateTime? lastUsedAt,
    Map<AppCapability, bool>? grantedPermissions,
    AppImmersiveConfig? immersiveOverride,
    bool clearImmersiveOverride = false,
    String? remoteSource,
    bool clearRemoteSource = false,
  }) {
    return InstalledApp(
      manifest: manifest ?? this.manifest,
      bundlePath: bundlePath ?? this.bundlePath,
      importedAt: importedAt ?? this.importedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      immersiveOverride: clearImmersiveOverride
          ? null
          : (immersiveOverride ?? this.immersiveOverride),
      remoteSource: clearRemoteSource
          ? null
          : (remoteSource ?? this.remoteSource),
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

    final overrideJson = json['immersiveOverride'];
    AppImmersiveConfig? override;
    if (overrideJson != null) {
      override = AppImmersiveConfig.fromJson(overrideJson);
    }

    return InstalledApp(
      manifest: AppManifest.fromJson(manifestJson),
      bundlePath: _string(json, 'bundlePath'),
      importedAt: DateTime.parse(_string(json, 'importedAt')),
      lastUsedAt: json['lastUsedAt'] is String
          ? DateTime.parse(json['lastUsedAt']! as String)
          : null,
      grantedPermissions: granted,
      immersiveOverride: override,
      remoteSource: json['remoteSource'] is String
          ? json['remoteSource']! as String
          : null,
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
    'immersiveOverride': immersiveOverride?.toJson(),
    'remoteSource': remoteSource,
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
