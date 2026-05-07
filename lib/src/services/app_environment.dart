import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_library.dart';
import 'app_storage.dart';
import 'bundle_manager.dart';
import 'network_service.dart';
import 'notification_service.dart';

class AppEnvironment {
  AppEnvironment._({
    required this.rootDirectory,
    required this.library,
    required this.bundleManager,
    required this.storage,
    required this.network,
    required this.notifications,
  });

  final Directory rootDirectory;
  final AppLibrary library;
  final BundleManager bundleManager;
  final AppStorage storage;
  final RuntimeNetworkService network;
  final NotificationService notifications;

  static Future<AppEnvironment> create() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory('${documents.path}/local_app_workbench');
    final library = AppLibrary(Directory('${root.path}/library'));
    final environment = AppEnvironment._(
      rootDirectory: root,
      library: library,
      bundleManager: BundleManager(
        bundleRoot: Directory('${root.path}/bundles'),
      ),
      storage: AppStorage(Directory('${root.path}/storage')),
      network: RuntimeNetworkService(),
      notifications: NotificationService(),
    );
    await library.load();
    return environment;
  }
}
