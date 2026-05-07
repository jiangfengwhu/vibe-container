import 'bridge_error.dart';
import 'bridge_payload.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_storage.dart';
import '../services/native_bridge_services.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';

typedef PermissionRequester = Future<bool> Function(AppCapability capability);
typedef PermissionSnapshot = Future<InstalledApp> Function();

class RuntimeBridge {
  RuntimeBridge({
    required this.currentApp,
    required this.storage,
    required this.network,
    required this.notifications,
    required this.requestPermission,
    this.nativeServices,
  });

  final PermissionSnapshot currentApp;
  final AppStorage storage;
  final RuntimeNetworkService network;
  final NotificationService notifications;
  final NativeBridgeServices? nativeServices;
  final PermissionRequester requestPermission;

  Future<BridgeResponse> handle(BridgeRequest request) async {
    try {
      final app = await currentApp();
      if (request.appId != app.manifest.id) {
        throw const BridgeException(
          BridgeErrorCode.permissionDenied,
          'request appId does not match current runtime',
        );
      }

      final result = switch (request.namespace) {
        BridgeNamespace.storage => await _handleStorage(app, request),
        BridgeNamespace.notification => await _handleNotification(app, request),
        BridgeNamespace.network => await _handleNetwork(app, request),
        BridgeNamespace.app => await _handleApp(app, request),
        _ => await _handleNative(app, request),
      };

      return BridgeResponse(
        requestId: request.requestId,
        ok: true,
        result: result,
      );
    } on BridgeException catch (error) {
      return BridgeResponse(
        requestId: request.requestId,
        ok: false,
        error: error,
      );
    } catch (error) {
      return BridgeResponse(
        requestId: request.requestId,
        ok: false,
        error: BridgeException(BridgeErrorCode.internalError, error.toString()),
      );
    }
  }

  Future<Object?> _handleStorage(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    await _ensurePermission(app, AppCapability.storage);
    return switch (request.method) {
      'get' => <String, Object?>{
        'value': await storage.get(
          app.manifest.id,
          _requiredString(request, 'key'),
        ),
      },
      'set' => await _setStorage(app, request),
      'remove' => await _removeStorage(app, request),
      'clear' => await _clearStorage(app),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported storage method',
      ),
    };
  }

  Future<Map<String, Object?>> _setStorage(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    await storage.set(
      app.manifest.id,
      _requiredString(request, 'key'),
      request.params['value'],
    );
    return <String, Object?>{'ok': true};
  }

  Future<Map<String, Object?>> _removeStorage(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    await storage.remove(app.manifest.id, _requiredString(request, 'key'));
    return <String, Object?>{'ok': true};
  }

  Future<Map<String, Object?>> _clearStorage(InstalledApp app) async {
    await storage.clear(app.manifest.id);
    return <String, Object?>{'ok': true};
  }

  Future<Object?> _handleNotification(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    return switch (request.method) {
      'requestPermission' => _requestNotificationPermission(app),
      'getPermissionStatus' => await notifications.getPermissionStatus(),
      'schedule' => await _scheduleNotification(app, request),
      'cancel' => await notifications.cancel(_requiredInt(request, 'id')),
      'cancelAll' => await notifications.cancelAll(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported notification method',
      ),
    };
  }

  Future<Map<String, Object?>> _requestNotificationPermission(
    InstalledApp app,
  ) async {
    final granted = await _ensurePermission(app, AppCapability.notification);
    if (!granted) {
      return <String, Object?>{'granted': false};
    }
    return notifications.requestPermission();
  }

  Future<Map<String, Object?>> _scheduleNotification(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    await _ensurePermission(app, AppCapability.notification);
    final title = _requiredString(request, 'title');
    final body = _requiredString(request, 'body');
    final timeValue = _requiredString(request, 'time');
    final time = DateTime.tryParse(timeValue);
    if (time == null) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'notification time must be ISO-8601',
      );
    }
    return notifications.schedule(
      id: request.params['id'] is int ? request.params['id']! as int : null,
      appId: app.manifest.id,
      title: title,
      body: body,
      time: time,
    );
  }

  Future<Object?> _handleNetwork(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    await _ensurePermission(app, AppCapability.network);
    final url = _requiredString(request, 'url');
    final options = request.params['options'];
    final networkOptions = <String, Object?>{};
    if (options != null) {
      if (options is! Map) {
        throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'network options must be an object',
        );
      }
      for (final entry in options.entries) {
        if (entry.key is! String) {
          throw const BridgeException(
            BridgeErrorCode.invalidParams,
            'network options keys must be strings',
          );
        }
        networkOptions[entry.key as String] = entry.value as Object?;
      }
    }
    return network.fetch(
      manifest: app.manifest,
      url: url,
      options: networkOptions,
    );
  }

  Future<Object?> _handleApp(InstalledApp app, BridgeRequest request) async {
    return switch (request.method) {
      'getManifest' => app.manifest.toJson(),
      'getPermissions' => <String, Object?>{
        for (final capability in app.manifest.permissions)
          capability.key: app.grantedPermissions[capability] ?? false,
      },
      'getCapabilities' ||
      'getLocale' ||
      'getTheme' ||
      'getLifecycleState' => await _requiredNativeServices().appInfo(
        app,
        request.method,
      ),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported app method',
      ),
    };
  }

  Future<Object?> _handleNative(InstalledApp app, BridgeRequest request) async {
    final capability = _capabilityForNamespace(request.namespace);
    await _ensurePermission(app, capability);
    return _requiredNativeServices().handle(app, request);
  }

  NativeBridgeServices _requiredNativeServices() {
    final services = nativeServices;
    if (services == null) {
      throw const BridgeException(
        BridgeErrorCode.notSupported,
        'native services are not available in this runtime',
      );
    }
    return services;
  }

  Future<bool> _ensurePermission(
    InstalledApp app,
    AppCapability capability,
  ) async {
    if (!app.manifest.declares(capability)) {
      throw BridgeException(
        BridgeErrorCode.permissionDenied,
        '${capability.key} is not declared in manifest',
      );
    }
    if (!capability.requiresRuntimeGrant) {
      return true;
    }
    if (app.hasPermission(capability)) {
      return true;
    }
    final granted = await requestPermission(capability);
    if (!granted) {
      throw BridgeException(
        BridgeErrorCode.permissionDenied,
        '${capability.key} permission denied',
      );
    }
    return true;
  }

  static String _requiredString(BridgeRequest request, String key) {
    final value = request.params[key];
    if (value is! String || value.isEmpty) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be a non-empty string',
      );
    }
    return value;
  }

  static int _requiredInt(BridgeRequest request, String key) {
    final value = request.params[key];
    if (value is! int) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be an integer',
      );
    }
    return value;
  }

  static AppCapability _capabilityForNamespace(BridgeNamespace namespace) {
    return switch (namespace) {
      BridgeNamespace.storage => AppCapability.storage,
      BridgeNamespace.secureStorage => AppCapability.secureStorage,
      BridgeNamespace.notification => AppCapability.notification,
      BridgeNamespace.network => AppCapability.network,
      BridgeNamespace.device => AppCapability.device,
      BridgeNamespace.ui => AppCapability.ui,
      BridgeNamespace.clipboard => AppCapability.clipboard,
      BridgeNamespace.share => AppCapability.share,
      BridgeNamespace.open => AppCapability.open,
      BridgeNamespace.file => AppCapability.file,
      BridgeNamespace.media => AppCapability.media,
      BridgeNamespace.location => AppCapability.location,
      BridgeNamespace.haptics => AppCapability.haptics,
      BridgeNamespace.barcode => AppCapability.barcode,
      BridgeNamespace.audio => AppCapability.audio,
      BridgeNamespace.biometric => AppCapability.biometric,
      BridgeNamespace.contacts => AppCapability.contacts,
      BridgeNamespace.calendar => AppCapability.calendar,
      BridgeNamespace.download => AppCapability.download,
      BridgeNamespace.events => AppCapability.events,
      BridgeNamespace.app => AppCapability.ui,
    };
  }
}
