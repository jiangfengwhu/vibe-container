import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_manifest.dart';

class WebAppDocumentBuilder {
  WebAppDocumentBuilder({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  final AssetBundle assetBundle;

  /// 宿主注入逻辑（securityHead + compatHead）的版本号。
  /// 修改任意注入内容后请 bump 此值，让所有 mini app 缓存的 runtime html 重新生成。
  static const String _hostInjectionVersion =
      'host-v3-keyboard-scroll-stabilizer';

  /// Cached `app_runtime.js` — identical for all mini apps; avoids re-reading the asset.
  String? _runtimeJsTemplate;

  Future<String> _loadRuntimeJsTemplate() async {
    final cached = _runtimeJsTemplate;
    if (cached != null) {
      return cached;
    }
    final loaded = await assetBundle.loadString(
      'assets/runtime/app_runtime.js',
    );
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
        '${_stableHash(template)}|'
        '$_hostInjectionVersion';

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
    await runtimeFile.writeAsString(html);
    await fingerprintFile.writeAsString(fingerprint);
    return runtimeFile;
  }

  Future<String> build({
    required Directory bundleDirectory,
    required AppManifest manifest,
    String? runtimeTemplate,
  }) async {
    final entryFile = File('${bundleDirectory.path}/${manifest.entry}');
    final runtime = runtimeTemplate ?? await _loadRuntimeJsTemplate();

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

    // 兼容修复 Android 16 (SDK 36) 强制 edge-to-edge 后 WebView 的两类滚动问题：
    //
    // 1) mini app 习惯写 `body { overflow-x: hidden }`，根据 CSS 规范这会让
    //    `overflow-y: visible` 被升级为 `auto`，body 由此变成"Y 方向自滚容器"。
    //    Android 16 WebView 初次布局时常常算错这种容器的 scroll size，导致页面
    //    无法垂直滚动。`overflow-x: clip` 视觉等价 hidden，但不会创建滚动容器，
    //    彻底回避此规范升级。用 `!important` + `</head>` 前注入，确保覆盖
    //    mini app 自身样式表和内联 style。
    //
    // 2) 即便 body 不是自滚容器，Android 16 WebView 的初始 scroll 尺寸也偶发算错，
    //    需要一次 layout 失效才会恢复（这就是用户原本必须先弹一次键盘 / 弹窗
    //    才能滚动的原因）。在 Android UA 上 load 完后主动改一帧
    //    `documentElement.style.minHeight` 模拟 reflow，把 WebView 踢正。
    const compatHead = '''
<style id="iprod-compat-style">
html,
body {
  overflow-x: clip !important;
}
</style>
<script id="iprod-compat-script">
(function () {
  'use strict';
  if (typeof navigator === 'undefined') return;
  if (!/Android/i.test(navigator.userAgent || '')) return;
  function kickReflow() {
    var de = document.documentElement;
    if (!de) return;
    var prev = de.style.minHeight;
    de.style.minHeight = '100.001%';
    if (typeof requestAnimationFrame === 'function') {
      requestAnimationFrame(function () {
        de.style.minHeight = prev || '';
      });
    } else {
      setTimeout(function () { de.style.minHeight = prev || ''; }, 0);
    }
  }
  if (document.readyState === 'complete') {
    setTimeout(kickReflow, 0);
  } else {
    window.addEventListener('load', function () {
      setTimeout(kickReflow, 0);
    }, { once: true });
  }
})();
</script>
''';

    const keyboardHead = '''
<script id="iprod-keyboard-script">
(function () {
  'use strict';
  if (typeof navigator === 'undefined') return;
  if (!/Android/i.test(navigator.userAgent || '')) return;

  var active = null;
  var raf = 0;

  function isEditable(element) {
    if (!element || element.nodeType !== 1) return false;
    var tag = (element.tagName || '').toLowerCase();
    return tag === 'input' ||
      tag === 'textarea' ||
      tag === 'select' ||
      element.isContentEditable;
  }

  function schedule(delay) {
    if (delay) {
      setTimeout(function () { schedule(0); }, delay);
      return;
    }
    if (raf) return;
    raf = requestAnimationFrame(function () {
      raf = 0;
      revealFocusedElement();
    });
  }

  function revealFocusedElement() {
    var element = active;
    if (!element || !document.contains(element)) return;
    var rect = element.getBoundingClientRect();
    var viewport = window.visualViewport;
    var top = viewport ? viewport.offsetTop : 0;
    var height = viewport ? viewport.height : window.innerHeight;
    var bottom = top + height;
    var margin = 24;
    if (rect.top >= top + margin && rect.bottom <= bottom - margin) return;
    try {
      element.scrollIntoView({
        block: 'center',
        inline: 'nearest',
        behavior: 'auto'
      });
    } catch (_) {
      element.scrollIntoView(false);
    }
  }

  document.addEventListener('focusin', function (event) {
    if (!isEditable(event.target)) return;
    active = event.target;
    schedule(80);
  }, true);

  document.addEventListener('focusout', function (event) {
    if (event.target === active) active = null;
  }, true);

  document.addEventListener('input', function () {
    if (active) schedule(0);
  }, true);

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', function () {
      if (active) schedule(0);
    });
    window.visualViewport.addEventListener('scroll', function () {
      if (active) schedule(0);
    });
  }
})();
</script>
''';

    final withTopHead = _injectHead(index, securityHead);
    return _injectBeforeHeadClose(withTopHead, '$compatHead$keyboardHead');
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

  /// 把内容插到 `</head>` 之前，让它晚于 mini app 自己的 `<link>`/`<style>` 出现，
  /// 用于需要"覆盖" mini app 样式的场景（如 Android 16 兼容修复）。
  static String _injectBeforeHeadClose(String html, String injection) {
    final headClose = RegExp(r'</head>', caseSensitive: false);
    if (headClose.hasMatch(html)) {
      return html.replaceFirst(headClose, '$injection</head>');
    }
    final headOpen = RegExp(r'<head[^>]*>', caseSensitive: false);
    final match = headOpen.firstMatch(html);
    if (match != null) {
      return html.replaceRange(match.end, match.end, injection);
    }
    return '$injection$html';
  }

  static String _jsString(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
