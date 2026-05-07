import 'package:http/http.dart' as http;

import '../bridge/bridge_error.dart';
import '../models/app_manifest.dart';

class RuntimeNetworkService {
  RuntimeNetworkService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, Object?>> fetch({
    required AppManifest manifest,
    required String url,
    required Map<String, Object?> options,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'network.fetch only accepts https URLs',
      );
    }
    if (!_isAllowedHost(uri.host, manifest.networkAllowlist)) {
      throw BridgeException(
        BridgeErrorCode.permissionDenied,
        'host is not in networkAllowlist: ${uri.host}',
      );
    }

    final method = (options['method'] as String? ?? 'GET').toUpperCase();
    if (!const <String>{'GET', 'POST'}.contains(method)) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'network.fetch only supports GET and POST in MVP',
      );
    }

    final headers = <String, String>{};
    final rawHeaders = options['headers'];
    if (rawHeaders != null) {
      if (rawHeaders is! Map) {
        throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'headers must be an object',
        );
      }
      for (final entry in rawHeaders.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const BridgeException(
            BridgeErrorCode.invalidParams,
            'headers must be string to string',
          );
        }
        headers[entry.key as String] = entry.value as String;
      }
    }

    final body = options['body'];
    final response = method == 'POST'
        ? await _client.post(
            uri,
            headers: headers,
            body: body is String ? body : null,
          )
        : await _client.get(uri, headers: headers);

    return <String, Object?>{
      'status': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };
  }

  static bool _isAllowedHost(String host, List<String> allowlist) {
    final lowerHost = host.toLowerCase();
    return allowlist.any(
      (allowed) =>
          lowerHost == allowed ||
          lowerHost.endsWith('.${allowed.toLowerCase()}'),
    );
  }
}
