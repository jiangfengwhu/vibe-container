import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_manifest.dart';

class WebAppDocumentBuilder {
  WebAppDocumentBuilder({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  final AssetBundle assetBundle;

  /// Cached `app_runtime.js` — identical for all mini apps; avoids re-reading the asset.
  String? _runtimeJsTemplate;

  Future<String> _loadRuntimeJsTemplate() async {
    final cached = _runtimeJsTemplate;
    if (cached != null) {
      return cached;
    }
    final loaded = await assetBundle.loadString('assets/runtime/app_runtime.js');
    _runtimeJsTemplate = loaded;
    return loaded;
  }

  Future<File> buildRuntimeFile({
    required Directory bundleDirectory,
    required AppManifest manifest,
  }) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    final runtimeFile = File(
      '${entryFile.parent.path}/.iprod_runtime_${entryFile.uri.pathSegments.last}',
    );
    final fingerprintFile = File('${runtimeFile.path}.fp');

    final template = await _loadRuntimeJsTemplate();
    final entryStat = await entryFile.stat();
    final fingerprint =
        '${manifest.id}|${manifest.runtimeVersion}|'
        '${entryStat.modified.millisecondsSinceEpoch}|'
        '${entryStat.size}|'
        '${template.hashCode}';

    if (await runtimeFile.exists() && await fingerprintFile.exists()) {
      try {
        final existing = await fingerprintFile.readAsString();
        if (existing == fingerprint) {
          return runtimeFile;
        }
      } on FileSystemException {
        // Fall through and regenerate.
      }
    }

    final html = await build(
      bundleDirectory: bundleDirectory,
      manifest: manifest,
      runtimeTemplate: template,
    );
    await runtimeFile.writeAsString(html, flush: true);
    await fingerprintFile.writeAsString(fingerprint, flush: true);
    return runtimeFile;
  }

  Future<String> build({
    required Directory bundleDirectory,
    required AppManifest manifest,
    String? runtimeTemplate,
  }) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    final runtime =
        runtimeTemplate ?? await _loadRuntimeJsTemplate();

    final index = _removeViewportMeta(await entryFile.readAsString());
    final runtimeForApp = runtime
        .replaceAll('__APP_ID__', _jsString(manifest.id))
        .replaceAll('__RUNTIME_VERSION__', _jsString(manifest.runtimeVersion));

    final securityHead =
        '''
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, viewport-fit=cover">
<style id="iprod-container-style">
html,
body {
  width: 100%;
  min-height: 100%;
  margin: 0;
  overscroll-behavior: none;
  -webkit-text-size-adjust: 100%;
  scrollbar-width: none;
}
* {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
*::-webkit-scrollbar {
  width: 0 !important;
  height: 0 !important;
  display: none !important;
}
</style>
<script>
$runtimeForApp
</script>
''';

    return _injectHead(index, securityHead);
  }

  static String _removeViewportMeta(String html) {
    return html.replaceAll(
      RegExp(
        r'''<meta\s+[^>]*name=["']viewport["'][^>]*>''',
        caseSensitive: false,
      ),
      '',
    );
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
