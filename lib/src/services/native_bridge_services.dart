import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bridge/bridge_error.dart';
import '../bridge/bridge_payload.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../ui/barcode_scanner_screen.dart';
import 'notification_service.dart';

typedef RuntimeContextProvider = BuildContext Function();
typedef RuntimeEventEmitter =
    Future<void> Function(String type, Map<String, Object?> payload);

class NativeBridgeServices {
  NativeBridgeServices({
    required this.rootDirectory,
    required this.notifications,
    required this.contextProvider,
    required this.emitEvent,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
    AudioRecorder? recorder,
    AudioPlayer? audioPlayer,
  }) : _httpClient = httpClient ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _recorder = recorder ?? AudioRecorder(),
       _audioPlayer = audioPlayer ?? AudioPlayer();

  final Directory rootDirectory;
  final NotificationService notifications;
  final RuntimeContextProvider contextProvider;
  final RuntimeEventEmitter emitEvent;
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  final AudioRecorder _recorder;
  final AudioPlayer _audioPlayer;
  final ImagePicker _imagePicker = ImagePicker();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Set<String> _grantedFilePaths = <String>{};
  bool _loadingVisible = false;

  Future<Object?> handle(InstalledApp app, BridgeRequest request) {
    return _guard(() async {
      return switch (request.namespace) {
        BridgeNamespace.secureStorage => _handleSecureStorage(app, request),
        BridgeNamespace.device => _handleDevice(request),
        BridgeNamespace.ui => _handleUi(request),
        BridgeNamespace.clipboard => _handleClipboard(request),
        BridgeNamespace.share => _handleShare(request),
        BridgeNamespace.open => _handleOpen(request),
        BridgeNamespace.file => _handleFile(request),
        BridgeNamespace.media => _handleMedia(request),
        BridgeNamespace.location => _handleLocation(request),
        BridgeNamespace.haptics => _handleHaptics(request),
        BridgeNamespace.barcode => _handleBarcode(request),
        BridgeNamespace.audio => _handleAudio(app, request),
        BridgeNamespace.biometric => _handleBiometric(request),
        BridgeNamespace.contacts => _handleContacts(request),
        BridgeNamespace.calendar => _handleCalendar(request),
        BridgeNamespace.download => _handleDownload(app, request),
        BridgeNamespace.events => _handleEvents(request),
        BridgeNamespace.app ||
        BridgeNamespace.storage ||
        BridgeNamespace.notification ||
        BridgeNamespace.network => throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'namespace is handled by RuntimeBridge',
        ),
      };
    });
  }

  Future<Map<String, Object?>> appInfo(InstalledApp app, String method) async {
    return switch (method) {
      'getCapabilities' => <String, Object?>{
        'capabilities': <String, Object?>{
          for (final capability in AppCapability.values)
            capability.key: <String, Object?>{
              'declared': app.manifest.declares(capability),
              'granted': app.hasPermission(capability),
              'requiresRuntimeGrant': capability.requiresRuntimeGrant,
              'needsSystemPermission': capability.needsSystemPermission,
            },
        },
      },
      'getLocale' => <String, Object?>{
        'locale': Localizations.localeOf(contextProvider()).toLanguageTag(),
      },
      'getTheme' => <String, Object?>{
        'brightness': Theme.of(contextProvider()).brightness.name,
      },
      'getLifecycleState' => <String, Object?>{
        'state': WidgetsBinding.instance.lifecycleState?.name ?? 'detached',
      },
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported app method',
      ),
    };
  }

  Future<Object?> _handleSecureStorage(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    final key = '${app.manifest.id}:${_requiredString(request, 'key')}';
    return switch (request.method) {
      'get' => <String, Object?>{'value': await _secureStorage.read(key: key)},
      'set' => _setSecureStorage(key, request),
      'remove' => _removeSecureStorage(key),
      'clear' => _clearSecureStorage(app),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported secureStorage method',
      ),
    };
  }

  Future<Map<String, Object?>> _setSecureStorage(
    String key,
    BridgeRequest request,
  ) async {
    await _secureStorage.write(
      key: key,
      value: _requiredString(request, 'value'),
    );
    return _ok();
  }

  Future<Map<String, Object?>> _removeSecureStorage(String key) async {
    await _secureStorage.delete(key: key);
    return _ok();
  }

  Future<Map<String, Object?>> _clearSecureStorage(InstalledApp app) async {
    final all = await _secureStorage.readAll();
    final prefix = '${app.manifest.id}:';
    for (final key in all.keys.where((key) => key.startsWith(prefix))) {
      await _secureStorage.delete(key: key);
    }
    return _ok();
  }

  Future<Object?> _handleDevice(BridgeRequest request) async {
    return switch (request.method) {
      'getInfo' => _deviceInfo(),
      'getNetworkStatus' => _networkStatus(),
      'getBatteryStatus' => _batteryStatus(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported device method',
      ),
    };
  }

  Future<Map<String, Object?>> _deviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    return <String, Object?>{
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'app': <String, Object?>{
        'name': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      },
      'device': _jsonSafeMap(deviceInfo.data),
    };
  }

  Future<Map<String, Object?>> _networkStatus() async {
    final values = await Connectivity().checkConnectivity();
    return <String, Object?>{
      'types': values.map((value) => value.name).toList(),
      'connected': !values.contains(ConnectivityResult.none),
    };
  }

  Future<Map<String, Object?>> _batteryStatus() async {
    final battery = Battery();
    return <String, Object?>{
      'level': await battery.batteryLevel,
      'state': (await battery.batteryState).name,
      'saveMode': await battery.isInBatterySaveMode,
    };
  }

  Future<Object?> _handleUi(BridgeRequest request) async {
    return switch (request.method) {
      'toast' => _toast(request),
      'alert' => _alert(request),
      'confirm' => _confirm(request),
      'actionSheet' => _actionSheet(request),
      'showLoading' => _showLoading(request),
      'hideLoading' => _hideLoading(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported ui method',
      ),
    };
  }

  Map<String, Object?> _toast(BridgeRequest request) {
    ScaffoldMessenger.of(contextProvider()).showSnackBar(
      SnackBar(content: Text(_requiredString(request, 'message'))),
    );
    return _ok();
  }

  Future<Map<String, Object?>> _alert(BridgeRequest request) async {
    final context = contextProvider();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_optionalString(request, 'title') ?? '提示'),
        content: Text(_optionalString(request, 'message') ?? ''),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_optionalString(request, 'buttonText') ?? '确定'),
          ),
        ],
      ),
    );
    return _ok();
  }

  Future<Map<String, Object?>> _confirm(BridgeRequest request) async {
    final context = contextProvider();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_optionalString(request, 'title') ?? '确认'),
        content: Text(_optionalString(request, 'message') ?? ''),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_optionalString(request, 'cancelText') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_optionalString(request, 'confirmText') ?? '确定'),
          ),
        ],
      ),
    );
    return <String, Object?>{'accepted': accepted ?? false};
  }

  Future<Map<String, Object?>> _actionSheet(BridgeRequest request) async {
    final options = _requiredStringList(request, 'options');
    final selected = await showModalBottomSheet<int>(
      context: contextProvider(),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (var index = 0; index < options.length; index += 1)
              ListTile(
                title: Text(options[index]),
                onTap: () => Navigator.of(context).pop(index),
              ),
          ],
        ),
      ),
    );
    return <String, Object?>{
      'selectedIndex': selected,
      'selected': selected == null ? null : options[selected],
    };
  }

  Future<Map<String, Object?>> _showLoading(BridgeRequest request) async {
    if (_loadingVisible) {
      return _ok();
    }
    _loadingVisible = true;
    unawaited(
      showDialog<void>(
        context: contextProvider(),
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(_optionalString(request, 'message') ?? '请稍候...'),
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() => _loadingVisible = false),
    );
    return _ok();
  }

  Map<String, Object?> _hideLoading() {
    if (_loadingVisible) {
      Navigator.of(contextProvider(), rootNavigator: true).pop();
      _loadingVisible = false;
    }
    return _ok();
  }

  Future<Object?> _handleClipboard(BridgeRequest request) async {
    return switch (request.method) {
      'readText' => <String, Object?>{
        'text': (await Clipboard.getData(Clipboard.kTextPlain))?.text,
      },
      'writeText' => _writeClipboard(request),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported clipboard method',
      ),
    };
  }

  Future<Map<String, Object?>> _writeClipboard(BridgeRequest request) async {
    await Clipboard.setData(
      ClipboardData(text: _requiredString(request, 'text')),
    );
    return _ok();
  }

  Future<Object?> _handleShare(BridgeRequest request) async {
    return switch (request.method) {
      'text' => _shareText(request),
      'files' => _shareFiles(request),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported share method',
      ),
    };
  }

  Future<Map<String, Object?>> _shareText(BridgeRequest request) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: _requiredString(request, 'text'),
        subject: _optionalString(request, 'subject'),
        title: _optionalString(request, 'title'),
      ),
    );
    return <String, Object?>{'status': result.status.name};
  }

  Future<Map<String, Object?>> _shareFiles(BridgeRequest request) async {
    final paths = _requiredStringList(request, 'paths');
    _ensureGrantedPaths(paths);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: paths.map(XFile.new).toList(),
        text: _optionalString(request, 'text'),
        subject: _optionalString(request, 'subject'),
        title: _optionalString(request, 'title'),
      ),
    );
    return <String, Object?>{'status': result.status.name};
  }

  Future<Object?> _handleOpen(BridgeRequest request) async {
    return switch (request.method) {
      'url' => _launch(_requiredString(request, 'url')),
      'phone' => _launch(
        'tel:${Uri.encodeComponent(_requiredString(request, 'number'))}',
      ),
      'email' => _openEmail(request),
      'map' => _openMap(request),
      'settings' => _openSettings(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported open method',
      ),
    };
  }

  Future<Map<String, Object?>> _openEmail(BridgeRequest request) {
    final subject = _optionalString(request, 'subject');
    final body = _optionalString(request, 'body');
    final query = <String, String>{};
    if (subject != null) {
      query['subject'] = subject;
    }
    if (body != null) {
      query['body'] = body;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: _requiredString(request, 'to'),
      queryParameters: query.isEmpty ? null : query,
    );
    return _launch(uri.toString());
  }

  Future<Map<String, Object?>> _openMap(BridgeRequest request) {
    final latitude = _requiredNum(request, 'latitude');
    final longitude = _requiredNum(request, 'longitude');
    final label = _optionalString(request, 'label');
    final query = label == null
        ? '$latitude,$longitude'
        : '$latitude,$longitude($label)';
    return _launch('geo:$latitude,$longitude?q=${Uri.encodeComponent(query)}');
  }

  Future<Map<String, Object?>> _openSettings() async {
    final opened = await ph.openAppSettings();
    return <String, Object?>{'opened': opened};
  }

  Future<Map<String, Object?>> _launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      throw const BridgeException(BridgeErrorCode.invalidParams, 'invalid URL');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return <String, Object?>{'opened': launched};
  }

  Future<Object?> _handleFile(BridgeRequest request) async {
    return switch (request.method) {
      'pick' => _pickFile(request),
      'saveText' => _saveTextFile(request),
      'saveBase64' => _saveBase64File(request),
      'readBase64' => _readBase64File(request),
      'share' => _shareFiles(request),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported file method',
      ),
    };
  }

  Future<Map<String, Object?>> _pickFile(BridgeRequest request) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: request.params['allowMultiple'] == true,
      withData: false,
    );
    final files = result?.files ?? const <PlatformFile>[];
    for (final file in files) {
      if (file.path != null) {
        _grantedFilePaths.add(file.path!);
      }
    }
    return <String, Object?>{'files': files.map(_platformFileJson).toList()};
  }

  Future<Map<String, Object?>> _saveTextFile(BridgeRequest request) async {
    final bytes = utf8.encode(_requiredString(request, 'text'));
    return _writeRuntimeFile(
      fileName: _optionalString(request, 'fileName') ?? 'file.txt',
      bytes: bytes,
    );
  }

  Future<Map<String, Object?>> _saveBase64File(BridgeRequest request) async {
    return _writeRuntimeFile(
      fileName: _optionalString(request, 'fileName') ?? 'file.bin',
      bytes: base64Decode(_requiredString(request, 'base64')),
    );
  }

  Future<Map<String, Object?>> _readBase64File(BridgeRequest request) async {
    final path = _requiredString(request, 'path');
    _ensureGrantedPaths(<String>[path]);
    final file = File(path);
    if (!await file.exists()) {
      throw const BridgeException(BridgeErrorCode.notFound, 'file not found');
    }
    return <String, Object?>{
      'base64': base64Encode(await file.readAsBytes()),
      'file': await _fileJson(file),
    };
  }

  Future<Map<String, Object?>> _writeRuntimeFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final safeName = _safeFileName(fileName);
    final directory = Directory('${rootDirectory.path}/runtime_files');
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    await file.writeAsBytes(bytes, flush: true);
    _grantedFilePaths.add(file.path);
    return <String, Object?>{'file': await _fileJson(file)};
  }

  Future<Object?> _handleMedia(BridgeRequest request) async {
    return switch (request.method) {
      'pickImage' => _pickMedia(request, ImageSource.gallery, image: true),
      'pickVideo' => _pickMedia(request, ImageSource.gallery, image: false),
      'captureImage' => _pickMedia(request, ImageSource.camera, image: true),
      'captureVideo' => _pickMedia(request, ImageSource.camera, image: false),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported media method',
      ),
    };
  }

  Future<Map<String, Object?>> _pickMedia(
    BridgeRequest request,
    ImageSource source, {
    required bool image,
  }) async {
    final quality = request.params['quality'] as int?;
    final file = image
        ? await _imagePicker.pickImage(source: source, imageQuality: quality)
        : await _imagePicker.pickVideo(source: source);
    if (file == null) {
      throw const BridgeException(BridgeErrorCode.cancelled, 'media cancelled');
    }
    _grantedFilePaths.add(file.path);
    return <String, Object?>{'file': await _xFileJson(file)};
  }

  Future<Object?> _handleLocation(BridgeRequest request) async {
    return switch (request.method) {
      'getPermissionStatus' => _locationPermissionStatus(),
      'requestPermission' => _requestLocationPermission(),
      'getCurrentPosition' => _currentPosition(request),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported location method',
      ),
    };
  }

  Future<Map<String, Object?>> _locationPermissionStatus() async {
    return <String, Object?>{
      'serviceEnabled': await Geolocator.isLocationServiceEnabled(),
      'permission': (await Geolocator.checkPermission()).name,
    };
  }

  Future<Map<String, Object?>> _requestLocationPermission() async {
    return <String, Object?>{
      'permission': (await Geolocator.requestPermission()).name,
    };
  }

  Future<Map<String, Object?>> _currentPosition(BridgeRequest request) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(
          seconds: (request.params['timeoutSeconds'] as int?) ?? 15,
        ),
      ),
    );
    return <String, Object?>{
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': position.timestamp.toUtc().toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _handleHaptics(BridgeRequest request) async {
    switch (request.method) {
      case 'selection':
        await HapticFeedback.selectionClick();
      case 'light':
      case 'success':
        await HapticFeedback.lightImpact();
      case 'medium':
      case 'warning':
        await HapticFeedback.mediumImpact();
      case 'heavy':
      case 'error':
        await HapticFeedback.heavyImpact();
      case 'vibrate':
        await HapticFeedback.vibrate();
      default:
        throw const BridgeException(
          BridgeErrorCode.invalidParams,
          'unsupported haptics method',
        );
    }
    return _ok();
  }

  Future<Object?> _handleBarcode(BridgeRequest request) async {
    final result = await Navigator.of(contextProvider()).push<String>(
      MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null) {
      throw const BridgeException(BridgeErrorCode.cancelled, 'scan cancelled');
    }
    return <String, Object?>{'value': result};
  }

  Future<Object?> _handleAudio(InstalledApp app, BridgeRequest request) async {
    return switch (request.method) {
      'requestPermission' => <String, Object?>{
        'granted': await _recorder.hasPermission(),
      },
      'startRecording' => _startRecording(app, request),
      'stopRecording' => _stopRecording(),
      'play' => _playAudio(request),
      'stop' => _stopAudio(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported audio method',
      ),
    };
  }

  Future<Map<String, Object?>> _startRecording(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    if (!await _recorder.hasPermission()) {
      throw const BridgeException(
        BridgeErrorCode.permissionDenied,
        'microphone permission denied',
      );
    }
    final directory = Directory(
      '${rootDirectory.path}/audio/${app.manifest.id}',
    );
    await directory.create(recursive: true);
    final path =
        '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _grantedFilePaths.add(path);
    return <String, Object?>{'path': path};
  }

  Future<Map<String, Object?>> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      return <String, Object?>{'path': null};
    }
    _grantedFilePaths.add(path);
    return <String, Object?>{'file': await _fileJson(File(path))};
  }

  Future<Map<String, Object?>> _playAudio(BridgeRequest request) async {
    final path = _requiredString(request, 'path');
    _ensureGrantedPaths(<String>[path]);
    await _audioPlayer.play(DeviceFileSource(path));
    return _ok();
  }

  Future<Map<String, Object?>> _stopAudio() async {
    await _audioPlayer.stop();
    return _ok();
  }

  Future<Object?> _handleBiometric(BridgeRequest request) async {
    return switch (request.method) {
      'canAuthenticate' => _canAuthenticate(),
      'authenticate' => _authenticate(request),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported biometric method',
      ),
    };
  }

  Future<Map<String, Object?>> _canAuthenticate() async {
    return <String, Object?>{
      'canCheckBiometrics': await _localAuth.canCheckBiometrics,
      'isDeviceSupported': await _localAuth.isDeviceSupported(),
      'available': (await _localAuth.getAvailableBiometrics())
          .map((type) => type.name)
          .toList(),
    };
  }

  Future<Map<String, Object?>> _authenticate(BridgeRequest request) async {
    final authenticated = await _localAuth.authenticate(
      localizedReason: _optionalString(request, 'reason') ?? '请验证身份',
    );
    return <String, Object?>{'authenticated': authenticated};
  }

  Future<Object?> _handleContacts(BridgeRequest request) async {
    return switch (request.method) {
      'requestPermission' => _requestContactsPermission(),
      'pick' => _pickContact(),
      _ => throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'unsupported contacts method',
      ),
    };
  }

  Future<Map<String, Object?>> _requestContactsPermission() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    return <String, Object?>{
      'status': status.name,
      'granted':
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited,
    };
  }

  Future<Map<String, Object?>> _pickContact() async {
    final contactId = await FlutterContacts.native.showPicker();
    if (contactId == null) {
      throw const BridgeException(
        BridgeErrorCode.cancelled,
        'contact cancelled',
      );
    }
    final contact = await FlutterContacts.get(
      contactId,
      properties: <ContactProperty>{
        ContactProperty.phone,
        ContactProperty.email,
      },
    );
    if (contact == null) {
      throw const BridgeException(
        BridgeErrorCode.notFound,
        'contact not found',
      );
    }
    return <String, Object?>{
      'contact': <String, Object?>{
        'id': contact.id,
        'displayName': contact.displayName,
        'phones': contact.phones.map((phone) => phone.number).toList(),
        'emails': contact.emails.map((email) => email.address).toList(),
      },
    };
  }

  Future<Map<String, Object?>> _handleCalendar(BridgeRequest request) async {
    final start = DateTime.tryParse(_requiredString(request, 'startTime'));
    final end = DateTime.tryParse(_requiredString(request, 'endTime'));
    if (start == null || end == null) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'calendar times must be ISO-8601',
      );
    }
    final result = await add2calendar.Add2Calendar.addEvent2Cal(
      add2calendar.Event(
        title: _requiredString(request, 'title'),
        description: _optionalString(request, 'description'),
        location: _optionalString(request, 'location'),
        startDate: start,
        endDate: end,
      ),
    );
    return <String, Object?>{'created': result};
  }

  Future<Map<String, Object?>> _handleDownload(
    InstalledApp app,
    BridgeRequest request,
  ) async {
    final url = _requiredString(request, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const BridgeException(
        BridgeErrorCode.invalidParams,
        'download.file only accepts https URLs',
      );
    }
    if (!_isAllowedHost(uri.host, app.manifest.networkAllowlist)) {
      throw BridgeException(
        BridgeErrorCode.permissionDenied,
        'host is not in networkAllowlist: ${uri.host}',
      );
    }
    final response = await _httpClient.get(uri);
    final fileName =
        _optionalString(request, 'fileName') ??
        uri.pathSegments.where((segment) => segment.isNotEmpty).lastOrNull ??
        'download.bin';
    return _writeRuntimeFile(fileName: fileName, bytes: response.bodyBytes);
  }

  Future<Map<String, Object?>> _handleEvents(BridgeRequest request) async {
    await emitEvent('subscription', <String, Object?>{
      'type': _requiredString(request, 'type'),
      'subscribed': request.method == 'subscribe',
    });
    return _ok();
  }

  Future<Object?> _guard(Future<Object?> Function() action) async {
    try {
      return await action();
    } on BridgeException {
      rethrow;
    } on MissingPluginException catch (error) {
      throw BridgeException(
        BridgeErrorCode.notSupported,
        error.message ?? '$error',
      );
    } on UnimplementedError catch (error) {
      throw BridgeException(BridgeErrorCode.notSupported, '$error');
    } on UnsupportedError catch (error) {
      throw BridgeException(
        BridgeErrorCode.notSupported,
        error.message ?? '$error',
      );
    }
  }

  Map<String, Object?> _platformFileJson(PlatformFile file) {
    return <String, Object?>{
      'name': file.name,
      'path': file.path,
      'size': file.size,
      'extension': file.extension,
      'mimeType': file.path == null ? null : lookupMimeType(file.path!),
    };
  }

  Future<Map<String, Object?>> _fileJson(File file) async {
    return <String, Object?>{
      'name': file.uri.pathSegments.last,
      'path': file.path,
      'size': await file.length(),
      'mimeType': lookupMimeType(file.path),
    };
  }

  Future<Map<String, Object?>> _xFileJson(XFile file) async {
    return <String, Object?>{
      'name': file.name,
      'path': file.path,
      'size': await file.length(),
      'mimeType': file.mimeType ?? lookupMimeType(file.path),
    };
  }

  void _ensureGrantedPaths(List<String> paths) {
    for (final path in paths) {
      if (!_grantedFilePaths.contains(path)) {
        throw BridgeException(
          BridgeErrorCode.permissionDenied,
          'file path is not available to this runtime: $path',
        );
      }
    }
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

  static String? _optionalString(BridgeRequest request, String key) {
    final value = request.params[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be a string',
      );
    }
    return value;
  }

  static num _requiredNum(BridgeRequest request, String key) {
    final value = request.params[key];
    if (value is! num) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be a number',
      );
    }
    return value;
  }

  static List<String> _requiredStringList(BridgeRequest request, String key) {
    final value = request.params[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw BridgeException(
        BridgeErrorCode.invalidParams,
        '$key must be a string array',
      );
    }
    return value.cast<String>();
  }

  static Map<String, Object?> _jsonSafeMap(Map<String, dynamic> source) {
    final result = <String, Object?>{};
    for (final entry in source.entries) {
      if (isJsonSafeValue(entry.value)) {
        result[entry.key] = entry.value as Object?;
      } else {
        result[entry.key] = entry.value.toString();
      }
    }
    return result;
  }

  static String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
  }

  static bool _isAllowedHost(String host, List<String> allowlist) {
    final lowerHost = host.toLowerCase();
    return allowlist.any(
      (allowed) =>
          lowerHost == allowed ||
          lowerHost.endsWith('.${allowed.toLowerCase()}'),
    );
  }

  static Map<String, Object?> _ok() => <String, Object?>{'ok': true};
}
