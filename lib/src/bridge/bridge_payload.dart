import 'bridge_error.dart';

enum BridgeNamespace {
  storage('storage'),
  secureStorage('secureStorage'),
  notification('notification'),
  network('network'),
  app('app'),
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

  const BridgeNamespace(this.value);

  final String value;

  static BridgeNamespace? tryParse(String value) {
    for (final namespace in values) {
      if (namespace.value == value) {
        return namespace;
      }
    }
    return null;
  }
}

class BridgeRequest {
  const BridgeRequest({
    required this.requestId,
    required this.appId,
    required this.namespace,
    required this.method,
    required this.params,
  });

  final String requestId;
  final String appId;
  final BridgeNamespace namespace;
  final String method;
  final Map<String, Object?> params;

  factory BridgeRequest.fromJson(Map<String, Object?> json) {
    final requestId = _string(json, 'requestId');
    final appId = _string(json, 'appId');
    final namespaceValue = _string(json, 'namespace');
    final method = _string(json, 'method');
    final rawParams = json['params'];

    if (requestId.length > 128) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'requestId is too long',
      );
    }

    final namespace = BridgeNamespace.tryParse(namespaceValue);
    if (namespace == null) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported namespace: $namespaceValue',
      );
    }

    if (!_allowedMethods[namespace]!.contains(method)) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported bridge method: ${namespace.value}.$method',
      );
    }

    if (rawParams is! Map) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'params must be an object',
      );
    }

    final params = <String, Object?>{};
    for (final entry in rawParams.entries) {
      if (entry.key is! String) {
        throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'params keys must be strings',
        );
      }
      params[entry.key as String] = entry.value as Object?;
    }
    if (!_isJsonSafe(params)) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'params must be JSON-safe',
      );
    }

    return BridgeRequest(
      requestId: requestId,
      appId: appId,
      namespace: namespace,
      method: method,
      params: params,
    );
  }

  static const Map<BridgeNamespace, Set<String>>
  _allowedMethods = <BridgeNamespace, Set<String>>{
    BridgeNamespace.storage: <String>{'get', 'set', 'remove', 'clear'},
    BridgeNamespace.secureStorage: <String>{'get', 'set', 'remove', 'clear'},
    BridgeNamespace.notification: <String>{
      'requestPermission',
      'getPermissionStatus',
      'schedule',
      'cancel',
      'cancelAll',
    },
    BridgeNamespace.network: <String>{'fetch'},
    BridgeNamespace.app: <String>{
      'getManifest',
      'getPermissions',
      'getCapabilities',
      'getLocale',
      'getTheme',
      'getSafeArea',
      'getLifecycleState',
    },
    BridgeNamespace.device: <String>{
      'getInfo',
      'getNetworkStatus',
      'getBatteryStatus',
    },
    BridgeNamespace.ui: <String>{
      'toast',
      'alert',
      'confirm',
      'actionSheet',
      'showLoading',
      'hideLoading',
      'setHeaderVisible',
    },
    BridgeNamespace.clipboard: <String>{'readText', 'writeText'},
    BridgeNamespace.share: <String>{'text', 'files'},
    BridgeNamespace.open: <String>{'url', 'phone', 'email', 'map', 'settings'},
    BridgeNamespace.file: <String>{
      'pick',
      'saveText',
      'saveBase64',
      'readBase64',
      'share',
    },
    BridgeNamespace.media: <String>{
      'pickImage',
      'pickVideo',
      'captureImage',
      'captureVideo',
    },
    BridgeNamespace.location: <String>{
      'getPermissionStatus',
      'requestPermission',
      'getCurrentPosition',
    },
    BridgeNamespace.haptics: <String>{
      'selection',
      'light',
      'medium',
      'heavy',
      'success',
      'warning',
      'error',
      'vibrate',
    },
    BridgeNamespace.barcode: <String>{'scan'},
    BridgeNamespace.audio: <String>{
      'requestPermission',
      'startRecording',
      'stopRecording',
      'play',
      'stop',
    },
    BridgeNamespace.biometric: <String>{'canAuthenticate', 'authenticate'},
    BridgeNamespace.contacts: <String>{'requestPermission', 'pick'},
    BridgeNamespace.calendar: <String>{'addEvent'},
    BridgeNamespace.download: <String>{'file'},
    BridgeNamespace.events: <String>{'subscribe', 'unsubscribe'},
  };

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be a non-empty string',
      );
    }
    return value;
  }
}

class BridgeResponse {
  const BridgeResponse({
    required this.requestId,
    required this.ok,
    this.result,
    this.error,
  });

  final String requestId;
  final bool ok;
  final Object? result;
  final BridgeException? error;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestId': requestId,
      'ok': ok,
      if (ok) 'result': result ?? <String, Object?>{},
      if (!ok) 'error': error?.toJson(),
    };
  }
}

bool isJsonSafeValue(Object? value) => _isJsonSafe(value);

bool _isJsonSafe(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return true;
  }
  if (value is List) {
    return value.every(_isJsonSafe);
  }
  if (value is Map) {
    return value.entries.every(
      (entry) => entry.key is String && _isJsonSafe(entry.value),
    );
  }
  return false;
}
