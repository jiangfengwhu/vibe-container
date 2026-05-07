import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/bridge_error.dart';
import '../bridge/bridge_payload.dart';
import '../bridge/runtime_bridge.dart';
import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import '../services/native_bridge_services.dart';
import '../webview/web_app_document_builder.dart';
import 'permission_screen.dart';

class RuntimeScreen extends StatefulWidget {
  const RuntimeScreen({
    required this.environment,
    required this.appId,
    super.key,
  });

  final AppEnvironment environment;
  final String appId;

  @override
  State<RuntimeScreen> createState() => _RuntimeScreenState();
}

class _RuntimeScreenState extends State<RuntimeScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final RuntimeBridge _bridge;
  late final NativeBridgeServices _nativeServices;
  final WebAppDocumentBuilder _documentBuilder = WebAppDocumentBuilder();
  String? _error;
  bool _loading = true;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nativeServices = NativeBridgeServices(
      rootDirectory: widget.environment.rootDirectory,
      notifications: widget.environment.notifications,
      contextProvider: () => context,
      emitEvent: _emitRuntimeEvent,
    );
    _bridge = RuntimeBridge(
      currentApp: _currentApp,
      storage: widget.environment.storage,
      network: widget.environment.network,
      notifications: widget.environment.notifications,
      nativeServices: _nativeServices,
      requestPermission: _requestPermission,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF6F7F4))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _loading = false;
                _error = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }
            final safeLocalNavigation =
                uri.scheme == 'about' ||
                uri.scheme == 'data' ||
                uri.scheme == 'file' ||
                request.url.startsWith('about:blank');
            return safeLocalNavigation
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'AppRuntimeNative',
        onMessageReceived: _handleBridgeMessage,
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emitRuntimeEvent(state.name, <String, Object?>{'state': state.name});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.environment.library.findById(widget.appId);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(app?.manifest.name ?? l10n.runtimeTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.permissionsTooltip,
            icon: const Icon(Icons.shield_outlined),
            onPressed: app == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PermissionScreen(
                        environment: widget.environment,
                        appId: widget.appId,
                      ),
                    ),
                  ),
          ),
          IconButton(
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) _RuntimeError(message: _error!, onRetry: _load),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    final app = widget.environment.library.findById(widget.appId);
    if (app == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.appNotFound;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final runtimeFile = await _documentBuilder.buildRuntimeFile(
        bundleDirectory: Directory(app.bundlePath),
        manifest: app.manifest,
      );
      await _controller.loadFile(runtimeFile.path);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<InstalledApp> _currentApp() async {
    final app = widget.environment.library.findById(widget.appId);
    if (app == null) {
      throw const BridgeException(
        BridgeErrorCode.notFound,
        'current app is not installed',
      );
    }
    return app;
  }

  Future<void> _handleBridgeMessage(JavaScriptMessage message) async {
    final response = await _bridgeResponseForMessage(message.message);
    final encoded = jsonEncode(response.toJson());
    await _controller.runJavaScript('window.__AppRuntimeResolve($encoded);');
  }

  Future<void> _emitRuntimeEvent(
    String type,
    Map<String, Object?> payload,
  ) async {
    final encoded = jsonEncode(<String, Object?>{
      'type': type,
      'payload': payload,
    });
    await _controller.runJavaScript('window.__AppRuntimeEmit($encoded);');
  }

  Future<BridgeResponse> _bridgeResponseForMessage(String source) async {
    String requestId = 'unknown';
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'bridge payload must be an object',
        );
      }
      final rawRequestId = decoded['requestId'];
      if (rawRequestId is String) {
        requestId = rawRequestId;
      }
      final request = BridgeRequest.fromJson(decoded);
      return _bridge.handle(request);
    } on BridgeException catch (error) {
      return BridgeResponse(requestId: requestId, ok: false, error: error);
    } catch (error) {
      return BridgeResponse(
        requestId: requestId,
        ok: false,
        error: BridgeException(BridgeErrorCode.invalidParams, error.toString()),
      );
    }
  }

  Future<bool> _requestPermission(AppCapability capability) async {
    final app = widget.environment.library.findById(widget.appId);
    if (app == null || !app.manifest.declares(capability) || !mounted) {
      return false;
    }
    final granted = app.grantedPermissions[capability] ?? false;
    if (granted) {
      return true;
    }
    final l10n = context.l10n;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.permissionRequestTitle(
            app.manifest.name,
            l10n.capabilityTitle(capability),
          ),
        ),
        content: Text(l10n.permissionReason(capability)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.deny),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.allow),
          ),
        ],
      ),
    );

    final shouldGrant = accepted ?? false;
    if (shouldGrant) {
      await widget.environment.library.setPermission(
        widget.appId,
        capability,
        true,
      );
    }
    return shouldGrant;
  }
}

class _RuntimeError extends StatelessWidget {
  const _RuntimeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.runtimeErrorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.reload),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
