import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_app_workbench/src/bridge/bridge_error.dart';
import 'package:local_app_workbench/src/bridge/bridge_payload.dart';
import 'package:local_app_workbench/src/bridge/runtime_bridge.dart';
import 'package:local_app_workbench/src/models/app_manifest.dart';
import 'package:local_app_workbench/src/models/installed_app.dart';
import 'package:local_app_workbench/src/services/app_library.dart';
import 'package:local_app_workbench/src/services/app_storage.dart';
import 'package:local_app_workbench/src/services/bundle_manager.dart';
import 'package:local_app_workbench/src/services/network_service.dart';
import 'package:local_app_workbench/src/services/notification_service.dart';

void main() {
  group('AppManifest', () {
    test('parses the MVP schema', () {
      final manifest = AppManifest.fromJson(_manifestJson());

      expect(manifest.id, 'local.bookkeeping');
      expect(manifest.entry, 'index.html');
      expect(manifest.permissions, contains(AppCapability.storage));
      expect(manifest.signature, isNull);
    });

    test('rejects remote entry paths', () {
      expect(
        () => AppManifest.fromJson(
          _manifestJson(entry: 'https://example.com/index.html'),
        ),
        throwsA(isA<ManifestException>()),
      );
    });

    test('accepts custom local html entry', () {
      final manifest = AppManifest.fromJson(_manifestJson(entry: 'main.html'));

      expect(manifest.entry, 'main.html');
    });

    test('requires network permission for allowlist', () {
      final json = _manifestJson(
        permissions: <String>['storage'],
        networkAllowlist: <String>['api.example.com'],
      );

      expect(
        () => AppManifest.fromJson(json),
        throwsA(isA<ManifestException>()),
      );
    });

    test('parses native runtime permissions', () {
      final manifest = AppManifest.fromJson(
        _manifestJson(
          permissions: <String>[
            'storage',
            'secureStorage',
            'device',
            'ui',
            'clipboard',
            'share',
            'open',
            'file',
            'media',
            'location',
            'haptics',
            'barcode',
            'audio',
            'biometric',
            'contacts',
            'calendar',
            'download',
            'events',
          ],
        ),
      );

      expect(manifest.permissions, contains(AppCapability.secureStorage));
      expect(manifest.permissions, contains(AppCapability.location));
      expect(AppCapability.device.requiresRuntimeGrant, isFalse);
      expect(AppCapability.location.needsSystemPermission, isTrue);
    });
  });

  group('BridgeRequest', () {
    test('validates namespace and method', () {
      final request = BridgeRequest.fromJson(<String, Object?>{
        'requestId': '1',
        'appId': 'local.bookkeeping',
        'namespace': 'storage',
        'method': 'set',
        'params': <String, Object?>{'key': 'records', 'value': <Object?>[]},
      });

      expect(request.namespace, BridgeNamespace.storage);
      expect(request.method, 'set');
    });

    test('rejects unsupported methods', () {
      expect(
        () => BridgeRequest.fromJson(<String, Object?>{
          'requestId': '1',
          'appId': 'local.bookkeeping',
          'namespace': 'storage',
          'method': 'fetch',
          'params': <String, Object?>{},
        }),
        throwsA(isA<BridgeException>()),
      );
    });

    test('accepts native namespace methods', () {
      final request = BridgeRequest.fromJson(<String, Object?>{
        'requestId': '1',
        'appId': 'local.bookkeeping',
        'namespace': 'device',
        'method': 'getInfo',
        'params': <String, Object?>{},
      });

      expect(request.namespace, BridgeNamespace.device);
      expect(request.method, 'getInfo');
    });

    test('accepts header visibility bridge method', () {
      final request = BridgeRequest.fromJson(<String, Object?>{
        'requestId': '1',
        'appId': 'local.bookkeeping',
        'namespace': 'ui',
        'method': 'setHeaderVisible',
        'params': <String, Object?>{'visible': false},
      });

      expect(request.namespace, BridgeNamespace.ui);
      expect(request.method, 'setHeaderVisible');
    });
  });

  group('AppStorage', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workbench_storage_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('isolates values by appId', () async {
      final storage = AppStorage(tempDir);

      await storage.set('local.one', 'profile', <String, Object?>{
        'name': 'One',
      });
      await storage.set('local.two', 'profile', <String, Object?>{
        'name': 'Two',
      });

      expect(await storage.get('local.one', 'profile'), <String, Object?>{
        'name': 'One',
      });
      expect(await storage.get('local.two', 'profile'), <String, Object?>{
        'name': 'Two',
      });
    });
  });

  group('AppLibrary', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workbench_library_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('removes app record and bundle directory', () async {
      final bundleDirectory = Directory('${tempDir.path}/bundle')..createSync();
      File('${bundleDirectory.path}/app.json').writeAsStringSync('{}');
      final library = AppLibrary(Directory('${tempDir.path}/library'));
      final app = _installedApp(
        bundlePath: bundleDirectory.path,
        grantedPermissions: <AppCapability, bool>{},
      );

      await library.load();
      await library.upsert(app);
      await library.remove(app.manifest.id);

      expect(library.findById(app.manifest.id), isNull);
      expect(bundleDirectory.existsSync(), isFalse);
    });
  });

  group('RuntimeBridge', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workbench_bridge_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('denies storage when user permission is not granted', () async {
      final app = _installedApp(
        grantedPermissions: <AppCapability, bool>{AppCapability.storage: false},
      );
      final bridge = _bridge(
        app: app,
        storage: AppStorage(tempDir),
        permissionGrant: false,
      );

      final response = await bridge.handle(
        BridgeRequest.fromJson(<String, Object?>{
          'requestId': '1',
          'appId': 'local.bookkeeping',
          'namespace': 'storage',
          'method': 'get',
          'params': <String, Object?>{'key': 'entries'},
        }),
      );

      expect(response.ok, isFalse);
      expect(response.error?.code, BridgeErrorCode.permissionDenied);
    });

    test('stores data when manifest and user permissions allow it', () async {
      final app = _installedApp(
        grantedPermissions: <AppCapability, bool>{AppCapability.storage: true},
      );
      final storage = AppStorage(tempDir);
      final bridge = _bridge(app: app, storage: storage, permissionGrant: true);

      final setResponse = await bridge.handle(
        BridgeRequest.fromJson(<String, Object?>{
          'requestId': '1',
          'appId': 'local.bookkeeping',
          'namespace': 'storage',
          'method': 'set',
          'params': <String, Object?>{
            'key': 'entries',
            'value': <Object?>[
              <String, Object?>{'amount': 12},
            ],
          },
        }),
      );

      final getResponse = await bridge.handle(
        BridgeRequest.fromJson(<String, Object?>{
          'requestId': '2',
          'appId': 'local.bookkeeping',
          'namespace': 'storage',
          'method': 'get',
          'params': <String, Object?>{'key': 'entries'},
        }),
      );

      expect(setResponse.ok, isTrue);
      expect(getResponse.ok, isTrue);
      expect(getResponse.result, <String, Object?>{
        'value': <Object?>[
          <String, Object?>{'amount': 12},
        ],
      });
    });

    test(
      'returns not supported when native services are unavailable',
      () async {
        final app = InstalledApp(
          manifest: AppManifest.fromJson(
            _manifestJson(permissions: <String>['ui']),
          ),
          bundlePath: '/tmp/local.bookkeeping',
          importedAt: DateTime.utc(2026, 5, 7),
          grantedPermissions: const <AppCapability, bool>{},
        );
        final bridge = _bridge(
          app: app,
          storage: AppStorage(tempDir),
          permissionGrant: true,
        );

        final response = await bridge.handle(
          BridgeRequest.fromJson(<String, Object?>{
            'requestId': 'native-1',
            'appId': 'local.bookkeeping',
            'namespace': 'ui',
            'method': 'toast',
            'params': <String, Object?>{'message': 'hello'},
          }),
        );

        expect(response.ok, isFalse);
        expect(response.error?.code, BridgeErrorCode.notSupported);
      },
    );
  });

  group('BundleManager', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workbench_bundle_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('imports a generated iprod zip archive', () async {
      final source = Directory('${tempDir.path}/source')..createSync();
      File(
        '${source.path}/app.json',
      ).writeAsStringSync(jsonForTest(_manifestJson()));
      File('${source.path}/index.html').writeAsStringSync(
        '<!doctype html><html><head></head><body></body></html>',
      );
      File('${source.path}/bundle.css').writeAsStringSync('body{}');
      File(
        '${source.path}/bundle.js',
      ).writeAsStringSync('AppRuntime.storage.get("items");');

      final archive = Archive();
      for (final file in source.listSync().whereType<File>()) {
        archive.addFile(
          ArchiveFile.bytes(file.uri.pathSegments.last, file.readAsBytesSync()),
        );
      }
      final zipPath = '${tempDir.path}/app.iprod.zip';
      File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));

      final manager = BundleManager(
        bundleRoot: Directory('${tempDir.path}/bundles'),
      );
      final installed = await manager.importArchive(zipPath);

      expect(installed.manifest.id, 'local.bookkeeping');
      expect(File('${installed.bundlePath}/app.json').existsSync(), isTrue);
    });

    test('imports archive using manifest entry', () async {
      final source = Directory('${tempDir.path}/custom_entry')..createSync();
      File(
        '${source.path}/app.json',
      ).writeAsStringSync(jsonForTest(_manifestJson(entry: 'main.html')));
      File('${source.path}/main.html').writeAsStringSync(
        '<!doctype html><html><head></head><body><h1>Hello</h1></body></html>',
      );

      final archive = Archive();
      for (final file in source.listSync().whereType<File>()) {
        archive.addFile(
          ArchiveFile.bytes(file.uri.pathSegments.last, file.readAsBytesSync()),
        );
      }
      final zipPath = '${tempDir.path}/custom-entry.iprod.zip';
      File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));

      final manager = BundleManager(
        bundleRoot: Directory('${tempDir.path}/bundles'),
      );
      final installed = await manager.importArchive(zipPath);

      expect(installed.manifest.id, 'local.bookkeeping');
      expect(installed.manifest.entry, 'main.html');
      expect(File('${installed.bundlePath}/main.html').existsSync(), isTrue);
    });

    test('downloads and imports archive from Cloudflare object key', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            'app.json',
            utf8.encode(jsonForTest(_manifestJson())),
          ),
        )
        ..addFile(
          ArchiveFile.bytes(
            'index.html',
            utf8.encode(
              '<!doctype html><html><head></head><body>Remote</body></html>',
            ),
          ),
        );
      final bytes = ZipEncoder().encode(archive);

      final manager = BundleManager(
        bundleRoot: Directory('${tempDir.path}/bundles'),
        httpClient: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://infra.308893.xyz/api/r2/objects/remote.iprod.zip',
          );
          expect(request.headers['X-Sanyi-INFRA'], 'sanyi');
          return http.Response.bytes(bytes, 200);
        }),
      );

      final installed = await manager.importRemoteArchive('remote.iprod.zip');

      expect(installed.manifest.id, 'local.bookkeeping');
      expect(File('${installed.bundlePath}/index.html').existsSync(), isTrue);
    });
  });
}

Map<String, Object?> _manifestJson({
  String entry = 'index.html',
  List<String> permissions = const <String>['storage'],
  List<String> networkAllowlist = const <String>[],
}) {
  return <String, Object?>{
    'id': 'local.bookkeeping',
    'name': 'Bookkeeping',
    'version': '1.0.0',
    'description': 'A local-first ledger.',
    'icon': r'$',
    'entry': entry,
    'permissions': permissions,
    'createdAt': '2026-05-07T00:00:00Z',
    'runtimeVersion': '1.0',
    'networkAllowlist': networkAllowlist,
    'signature': null,
  };
}

InstalledApp _installedApp({
  required Map<AppCapability, bool> grantedPermissions,
  String bundlePath = '/tmp/local.bookkeeping',
}) {
  return InstalledApp(
    manifest: AppManifest.fromJson(_manifestJson()),
    bundlePath: bundlePath,
    importedAt: DateTime.utc(2026, 5, 7),
    grantedPermissions: grantedPermissions,
  );
}

RuntimeBridge _bridge({
  required InstalledApp app,
  required AppStorage storage,
  required bool permissionGrant,
}) {
  return RuntimeBridge(
    currentApp: () async => app,
    storage: storage,
    network: RuntimeNetworkService(),
    notifications: NotificationService(),
    requestPermission: (_) async => permissionGrant,
  );
}

String jsonForTest(Map<String, Object?> value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}
