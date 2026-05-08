import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../models/app_manifest.dart';
import '../models/installed_app.dart';

class BundleSecurityException implements Exception {
  const BundleSecurityException(this.message);

  final String message;

  @override
  String toString() => 'BundleSecurityException: $message';
}

class BundleManager {
  BundleManager({
    required this.bundleRoot,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  static const remoteBundleBaseUrl = 'https://infra.308893.xyz';

  final Directory bundleRoot;
  final http.Client httpClient;

  Future<InstalledApp> importArchive(String archivePath) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw const BundleSecurityException('archive file does not exist');
    }

    final incomingRoot = Directory(
      '${bundleRoot.path}/.incoming/${DateTime.now().microsecondsSinceEpoch}',
    );
    await incomingRoot.create(recursive: true);
    try {
      final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
      for (final entry in archive) {
        final safeName = _safeArchiveEntryName(entry.name);
        final targetPath = '${incomingRoot.path}/$safeName';
        if (entry.isDirectory) {
          await Directory(targetPath).create(recursive: true);
          continue;
        }
        final parent = File(targetPath).parent;
        await parent.create(recursive: true);
        final bytes = entry.readBytes();
        if (bytes == null) {
          throw BundleSecurityException('cannot read archive entry $safeName');
        }
        await File(targetPath).writeAsBytes(bytes, flush: true);
      }

      final sourceBundle = await _resolveExtractedBundleRoot(incomingRoot);
      final manifest = await readManifest(sourceBundle);
      await validateBundle(sourceBundle, manifest);

      final target = Directory('${bundleRoot.path}/${manifest.id}');
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await _copyDirectory(sourceBundle, target);

      return InstalledApp(
        manifest: manifest,
        bundlePath: target.path,
        importedAt: DateTime.now().toUtc(),
        grantedPermissions: <AppCapability, bool>{
          for (final permission in manifest.permissions) permission: false,
        },
      );
    } finally {
      if (await incomingRoot.exists()) {
        await incomingRoot.delete(recursive: true);
      }
    }
  }

  Future<InstalledApp> importRemoteArchive(String source) async {
    final uri = _remoteArchiveUri(source);
    final response = await httpClient.get(
      uri,
      headers: const <String, String>{'X-Sanyi-INFRA': 'sanyi'},
    );
    if (response.statusCode != 200) {
      throw BundleSecurityException(
        'download failed: HTTP ${response.statusCode}',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw const BundleSecurityException('downloaded archive is empty');
    }

    final downloads = Directory('${bundleRoot.path}/.downloads');
    await downloads.create(recursive: true);
    final archiveFile = File(
      '${downloads.path}/${DateTime.now().microsecondsSinceEpoch}.ipd',
    );
    try {
      await archiveFile.writeAsBytes(response.bodyBytes, flush: true);
      return await importArchive(archiveFile.path);
    } finally {
      if (await archiveFile.exists()) {
        await archiveFile.delete();
      }
    }
  }

  Future<AppManifest> readManifest(Directory bundleDirectory) async {
    final manifestFile = File('${bundleDirectory.path}/app.json');
    if (!await manifestFile.exists()) {
      throw const ManifestException('bundle is missing app.json');
    }
    return AppManifest.fromJsonString(await manifestFile.readAsString());
  }

  Future<void> validateBundle(
    Directory bundleDirectory,
    AppManifest manifest,
  ) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    if (!await entryFile.exists()) {
      throw ManifestException('bundle is missing entry ${manifest.entry}');
    }
    final index = await entryFile.readAsString();
    if (index.trim().isEmpty) {
      throw ManifestException('bundle entry ${manifest.entry} is empty');
    }
  }

  Future<Directory> _resolveExtractedBundleRoot(Directory incomingRoot) async {
    if (await File('${incomingRoot.path}/app.json').exists()) {
      return incomingRoot;
    }

    final children = await incomingRoot.list().toList();
    final directories = children.whereType<Directory>().toList();
    if (directories.length == 1 &&
        await File('${directories.single.path}/app.json').exists()) {
      return directories.single;
    }

    throw const BundleSecurityException(
      'archive root must contain app.json or a single bundle directory',
    );
  }

  static String _safeArchiveEntryName(String name) {
    final normalized = name.replaceAll('\\', '/');
    if (normalized.startsWith('/') ||
        normalized.startsWith('../') ||
        normalized.contains('/../') ||
        normalized == '..' ||
        normalized.isEmpty) {
      throw BundleSecurityException('unsafe archive entry: $name');
    }
    return normalized;
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = entity.path.substring(source.path.length + 1);
      final targetPath = '${target.path}/$relative';
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  static Uri _remoteArchiveUri(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      throw const BundleSecurityException('remote bundle key is empty');
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme != 'https' || parsed.host != 'infra.308893.xyz') {
        throw const BundleSecurityException(
          'remote bundle URL must use https://infra.308893.xyz/',
        );
      }
      if (!parsed.path.startsWith('/api/r2/objects/')) {
        throw const BundleSecurityException(
          'remote bundle URL must point to /api/r2/objects/<key>',
        );
      }
      return parsed;
    }

    final key = trimmed.replaceAll(RegExp(r'^/+'), '');
    if (key.isEmpty || key.contains('..') || key.contains('/')) {
      throw const BundleSecurityException(
        'remote bundle key must be a single safe object name',
      );
    }
    return Uri.parse(
      '$remoteBundleBaseUrl/api/r2/objects/${Uri.encodeComponent(key)}',
    );
  }
}
