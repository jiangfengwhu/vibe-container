import 'dart:convert';

enum AppCapability {
  storage('storage'),
  secureStorage('secureStorage'),
  notification('notification'),
  network('network'),
  device('device'),
  ui('ui'),
  clipboard('clipboard'),
  share('share'),
  open('open'),
  file('file'),
  media('media'),
  location('location'),
  haptics('haptics'),
  barcode('barcode'),
  audio('audio'),
  biometric('biometric'),
  contacts('contacts'),
  calendar('calendar'),
  download('download'),
  events('events');

  const AppCapability(this.key);

  final String key;

  static AppCapability? tryParse(String value) {
    for (final capability in values) {
      if (capability.key == value) {
        return capability;
      }
    }
    return null;
  }

  bool get requiresRuntimeGrant {
    return switch (this) {
      AppCapability.storage ||
      AppCapability.secureStorage ||
      AppCapability.notification ||
      AppCapability.network ||
      AppCapability.file ||
      AppCapability.media ||
      AppCapability.location ||
      AppCapability.barcode ||
      AppCapability.audio ||
      AppCapability.biometric ||
      AppCapability.contacts ||
      AppCapability.calendar ||
      AppCapability.download => true,
      AppCapability.device ||
      AppCapability.ui ||
      AppCapability.clipboard ||
      AppCapability.share ||
      AppCapability.open ||
      AppCapability.haptics ||
      AppCapability.events => false,
    };
  }

  bool get needsSystemPermission {
    return switch (this) {
      AppCapability.notification ||
      AppCapability.media ||
      AppCapability.location ||
      AppCapability.barcode ||
      AppCapability.audio ||
      AppCapability.biometric ||
      AppCapability.contacts ||
      AppCapability.calendar => true,
      _ => false,
    };
  }
}

class ManifestException implements Exception {
  const ManifestException(this.message);

  final String message;

  @override
  String toString() => 'ManifestException: $message';
}

class AppManifest {
  const AppManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.icon,
    required this.entry,
    required this.permissions,
    required this.createdAt,
    required this.runtimeVersion,
    this.networkAllowlist = const <String>[],
    this.signature,
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String icon;
  final String entry;
  final Set<AppCapability> permissions;
  final DateTime createdAt;
  final String runtimeVersion;
  final List<String> networkAllowlist;
  final String? signature;

  factory AppManifest.fromJson(Map<String, Object?> json) {
    final id = _string(json, 'id');
    final name = _string(json, 'name');
    final version = _string(json, 'version');
    final description = _string(json, 'description');
    final icon = _string(json, 'icon');
    final entry = _string(json, 'entry');
    final runtimeVersion = _string(json, 'runtimeVersion');
    final createdAtValue = _string(json, 'createdAt');
    final permissionsValue = json['permissions'];
    final networkAllowlistValue = json['networkAllowlist'];

    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{2,63}$').hasMatch(id)) {
      throw const ManifestException('id must be 3-64 safe characters');
    }
    if (name.trim().isEmpty || name.length > 80) {
      throw const ManifestException('name must be non-empty and <= 80 chars');
    }
    if (description.length > 240) {
      throw const ManifestException('description must be <= 240 chars');
    }
    if (entry.startsWith('/') ||
        entry.contains('..') ||
        entry.startsWith('http://') ||
        entry.startsWith('https://') ||
        !entry.toLowerCase().endsWith('.html')) {
      throw const ManifestException('entry must be a relative local html path');
    }

    final parsedCreatedAt = DateTime.tryParse(createdAtValue);
    if (parsedCreatedAt == null) {
      throw const ManifestException('createdAt must be an ISO-8601 string');
    }

    if (permissionsValue is! List) {
      throw const ManifestException('permissions must be a string array');
    }
    final permissions = <AppCapability>{};
    for (final value in permissionsValue) {
      if (value is! String) {
        throw const ManifestException('permissions must only contain strings');
      }
      final capability = AppCapability.tryParse(value);
      if (capability == null) {
        throw ManifestException('unsupported permission: $value');
      }
      permissions.add(capability);
    }

    final allowlist = <String>[];
    if (networkAllowlistValue != null) {
      if (networkAllowlistValue is! List) {
        throw const ManifestException(
          'networkAllowlist must be a string array',
        );
      }
      for (final value in networkAllowlistValue) {
        if (value is! String || !_isSafeHost(value)) {
          throw const ManifestException(
            'networkAllowlist must contain host names only',
          );
        }
        allowlist.add(value.toLowerCase());
      }
    }

    if (allowlist.isNotEmpty && !permissions.contains(AppCapability.network)) {
      throw const ManifestException(
        'networkAllowlist requires network permission',
      );
    }

    return AppManifest(
      id: id,
      name: name,
      version: version,
      description: description,
      icon: icon,
      entry: entry,
      permissions: permissions,
      createdAt: parsedCreatedAt,
      runtimeVersion: runtimeVersion,
      networkAllowlist: allowlist,
      signature: json['signature'] as String?,
    );
  }

  factory AppManifest.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const ManifestException('app.json root must be an object');
    }
    return AppManifest.fromJson(decoded);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'icon': icon,
    'entry': entry,
    'permissions': permissions.map((permission) => permission.key).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'runtimeVersion': runtimeVersion,
    'networkAllowlist': networkAllowlist,
    'signature': signature,
  };

  bool declares(AppCapability capability) => permissions.contains(capability);

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw ManifestException('$key must be a non-empty string');
    }
    return value;
  }

  static bool _isSafeHost(String host) {
    if (host.startsWith('.') || host.endsWith('.') || host.contains('/')) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(host);
  }
}
