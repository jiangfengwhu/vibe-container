import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_manifest.dart';

class WebAppDocumentBuilder {
  WebAppDocumentBuilder({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  final AssetBundle assetBundle;

  Future<File> buildRuntimeFile({
    required Directory bundleDirectory,
    required AppManifest manifest,
  }) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    final html = await build(
      bundleDirectory: bundleDirectory,
      manifest: manifest,
    );
    final runtimeFile = File(
      '${entryFile.parent.path}/.iprod_runtime_${entryFile.uri.pathSegments.last}',
    );
    await runtimeFile.writeAsString(html, flush: true);
    return runtimeFile;
  }

  Future<String> build({
    required Directory bundleDirectory,
    required AppManifest manifest,
  }) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    final runtime = await assetBundle.loadString(
      'assets/runtime/app_runtime.js',
    );

    final index = await entryFile.readAsString();
    final runtimeForApp = runtime
        .replaceAll('__APP_ID__', _jsString(manifest.id))
        .replaceAll('__RUNTIME_VERSION__', _jsString(manifest.runtimeVersion));

    final securityHead =
        '''
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<script>
$runtimeForApp
</script>
''';

    return _injectHead(index, securityHead);
  }

  static String _injectHead(String html, String headInjection) {
    final headOpen = RegExp(r'<head[^>]*>', caseSensitive: false);
    final headClose = RegExp(r'</head>', caseSensitive: false);
    final match = headOpen.firstMatch(html);
    if (match != null) {
      return html.replaceRange(match.end, match.end, headInjection);
    }
    if (headClose.hasMatch(html)) {
      return html.replaceFirst(headClose, '$headInjection</head>');
    }
    return '$headInjection$html';
  }

  static String _jsString(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }
}
