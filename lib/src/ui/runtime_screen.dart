import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../bridge/bridge_error.dart';
import '../bridge/bridge_payload.dart';
import '../bridge/runtime_bridge.dart';
import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import '../services/native_bridge_services.dart';
import '../webview/web_app_document_builder.dart';
import 'manage_screen.dart';
import 'theme.dart';

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
    _enterImmersiveMode();
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
      ..setBackgroundColor(WorkbenchPalette.cream)
      ..enableZoom(false)
      ..setVerticalScrollBarEnabled(false)
      ..setHorizontalScrollBarEnabled(false)
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

    _configureAndroidWebView();
  }

  void _configureAndroidWebView() {
    if (kIsWeb || !Platform.isAndroid) return;
    final platform = _controller.platform;
    if (platform is! AndroidWebViewController) return;
    AndroidWebViewController.enableDebugging(false);
    platform.setMediaPlaybackRequiresUserGesture(false);
    platform.setOnShowFileSelector(_androidShowFileSelector);
    platform.setOnPlatformPermissionRequest((request) async {
      var allGranted = true;
      for (final type in request.types) {
        if (type == WebViewPermissionResourceType.camera) {
          allGranted &= await _ensurePermission(ph.Permission.camera);
        } else if (type == WebViewPermissionResourceType.microphone) {
          allGranted &= await _ensurePermission(ph.Permission.microphone);
        }
      }
      if (allGranted) {
        request.grant();
      } else {
        request.deny();
      }
    });
  }

  Future<bool> _ensurePermission(ph.Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }

  Future<List<String>> _androidShowFileSelector(
    FileSelectorParams params,
  ) async {
    final acceptTypes = params.acceptTypes;
    final wantsImage = acceptTypes.any(
      (t) => t.startsWith('image/') || t == '.jpg' || t == '.jpeg' || t == '.png',
    );
    final wantsVideo = acceptTypes.any(
      (t) => t.startsWith('video/') || t == '.mp4' || t == '.mov',
    );

    try {
      if (params.isCaptureEnabled) {
        if (!await _ensurePermission(ph.Permission.camera)) {
          return const <String>[];
        }
        final picker = ImagePicker();
        final XFile? file = wantsVideo && !wantsImage
            ? await picker.pickVideo(source: ImageSource.camera)
            : await picker.pickImage(source: ImageSource.camera);
        if (file == null) return const <String>[];
        return <String>[Uri.file(file.path).toString()];
      }

      if (wantsImage || wantsVideo) {
        final picker = ImagePicker();
        if (params.mode == FileSelectorMode.openMultiple && wantsImage) {
          final files = await picker.pickMultiImage();
          return files.map((f) => Uri.file(f.path).toString()).toList();
        }
        final XFile? file = wantsVideo && !wantsImage
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.gallery);
        if (file == null) return const <String>[];
        return <String>[Uri.file(file.path).toString()];
      }

      final result = await FilePicker.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        withData: false,
      );
      if (result == null) return const <String>[];
      return result.files
          .where((f) => f.path != null)
          .map((f) => Uri.file(f.path!).toString())
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exitImmersiveMode();
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
    final immersive = app?.effectiveImmersive ?? AppImmersiveConfig.defaults;
    final showHeader = immersive.showHeader;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: showHeader
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: !immersive.bottomInset,
        extendBodyBehindAppBar: !showHeader,
        backgroundColor: Colors.black,
        appBar: showHeader
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _RuntimeHeader(
                  title: app?.manifest.name ?? l10n.runtimeTitle,
                  icon: app?.manifest.icon ?? '·',
                  onManage: app == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ManageScreen(
                              environment: widget.environment,
                              appId: widget.appId,
                            ),
                          ),
                        ),
                  onRefresh: _load,
                  onBack: () => Navigator.of(context).maybePop(),
                  manageTooltip: l10n.manageTitle,
                  refreshTooltip: l10n.refreshTooltip,
                ),
              )
            : null,
        body: SafeArea(
          top: !showHeader && immersive.topInset,
          bottom: immersive.bottomInset,
          left: false,
          right: false,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              RepaintBoundary(
                child: WebViewWidget(controller: _controller),
              ),
              if (_loading)
                const Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                    color: WorkbenchPalette.coral,
                  ),
                ),
              if (_error != null)
                _RuntimeError(message: _error!, onRetry: _load),
            ],
          ),
        ),
      ),
    );
  }

  static void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _setDefaultTopSystemUi();
  }

  static void _setDefaultTopSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
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

class _RuntimeHeader extends StatelessWidget {
  const _RuntimeHeader({
    required this.title,
    required this.icon,
    required this.onRefresh,
    required this.onBack,
    required this.manageTooltip,
    required this.refreshTooltip,
    this.onManage,
  });

  final String title;
  final String icon;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback? onManage;
  final String manageTooltip;
  final String refreshTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WorkbenchPalette.cream,
        border: Border(
          bottom: BorderSide(color: WorkbenchPalette.sandLine, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            children: <Widget>[
              _HeaderIconButton(
                tooltip: '',
                icon: Icons.arrow_back_rounded,
                onPressed: onBack,
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: WorkbenchPalette.coralGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: WorkbenchPalette.inkPrimary,
                  ),
                ),
              ),
              _HeaderIconButton(
                tooltip: manageTooltip,
                icon: Icons.tune_rounded,
                onPressed: onManage,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: refreshTooltip,
                icon: Icons.refresh_rounded,
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WorkbenchPalette.paper,
            shape: BoxShape.circle,
            border: Border.all(color: WorkbenchPalette.sand),
          ),
          child: Icon(
            icon,
            size: 17,
            color: disabled
                ? WorkbenchPalette.inkSoft
                : WorkbenchPalette.inkPrimary,
          ),
        ),
      ),
    );
    return tooltip.isEmpty ? button : Tooltip(message: tooltip, child: button);
  }
}

class _RuntimeError extends StatelessWidget {
  const _RuntimeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: WorkbenchPalette.cream,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WorkbenchPalette.coralWash,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: WorkbenchPalette.coral.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 38,
                      color: WorkbenchPalette.coral,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.runtimeErrorTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: WorkbenchPalette.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: WorkbenchPalette.inkSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
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
