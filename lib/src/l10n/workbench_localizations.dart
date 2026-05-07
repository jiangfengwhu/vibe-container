import 'package:flutter/widgets.dart';

import '../models/app_manifest.dart';

class WorkbenchLocalizations {
  const WorkbenchLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('zh'), Locale('en')];

  static const LocalizationsDelegate<WorkbenchLocalizations> delegate =
      _WorkbenchLocalizationsDelegate();

  static WorkbenchLocalizations of(BuildContext context) {
    return Localizations.of<WorkbenchLocalizations>(
      context,
      WorkbenchLocalizations,
    )!;
  }

  static Locale resolveLocale(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale != null) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == locale.languageCode) {
          return supported;
        }
      }
    }
    return const Locale('zh');
  }

  String get appTitle => _text('appTitle');
  String get importTooltip => _text('importTooltip');
  String get permissionsTooltip => _text('permissionsTooltip');
  String get refreshTooltip => _text('refreshTooltip');
  String get emptyLibraryTitle => _text('emptyLibraryTitle');
  String get emptyLibraryBody => _text('emptyLibraryBody');
  String get importSampleBundle => _text('importSampleBundle');
  String get neverOpened => _text('neverOpened');
  String get importScreenTitle => _text('importScreenTitle');
  String get importRemoteTitle => _text('importRemoteTitle');
  String get importRemoteBody => _text('importRemoteBody');
  String get remoteBundleInputLabel => _text('remoteBundleInputLabel');
  String get remoteBundleInputHint => _text('remoteBundleInputHint');
  String get downloadAndImport => _text('downloadAndImport');
  String get remoteBundleRequired => _text('remoteBundleRequired');
  String get builtInSamples => _text('builtInSamples');
  String get reimport => _text('reimport');
  String get import => _text('import');
  String get runtimeTitle => _text('runtimeTitle');
  String get appNotFound => _text('appNotFound');
  String get deny => _text('deny');
  String get allow => _text('allow');
  String get cancel => _text('cancel');
  String get delete => _text('delete');
  String get deleteAppBody => _text('deleteAppBody');
  String get runtimeErrorTitle => _text('runtimeErrorTitle');
  String get reload => _text('reload');
  String get permissionsTitle => _text('permissionsTitle');
  String get permissionsIntro => _text('permissionsIntro');
  String get noRuntimePermissions => _text('noRuntimePermissions');
  String get manageTitle => _text('manageTitle');
  String get manageEyebrow => _text('manageEyebrow');
  String get manageHeroSubtitle => _text('manageHeroSubtitle');
  String get permissionSectionTitle => _text('permissionSectionTitle');
  String get permissionSectionEyebrow => _text('permissionSectionEyebrow');
  String get immersiveSectionTitle => _text('immersiveSectionTitle');
  String get immersiveSectionEyebrow => _text('immersiveSectionEyebrow');
  String get immersiveTopLabel => _text('immersiveTopLabel');
  String get immersiveTopDescription => _text('immersiveTopDescription');
  String get immersiveBottomLabel => _text('immersiveBottomLabel');
  String get immersiveBottomDescription => _text('immersiveBottomDescription');
  String get immersiveHeaderLabel => _text('immersiveHeaderLabel');
  String get immersiveHeaderDescription => _text('immersiveHeaderDescription');
  String get immersiveResetDefault => _text('immersiveResetDefault');
  String get immersiveOverridden => _text('immersiveOverridden');
  String get dangerSectionTitle => _text('dangerSectionTitle');
  String get dangerSectionEyebrow => _text('dangerSectionEyebrow');
  String get deleteAppButton => _text('deleteAppButton');
  String get deleteAppHint => _text('deleteAppHint');
  String get swipeToManageHint => _text('swipeToManageHint');
  String get manageAction => _text('manageAction');

  String lastUsed(String date) {
    return _format(_text('lastUsed'), <String, String>{'date': date});
  }

  String imported(String appName) {
    return _format(_text('imported'), <String, String>{'app': appName});
  }

  String importFailed(Object error) {
    return _format(_text('importFailed'), <String, String>{'error': '$error'});
  }

  String deleteAppTitle(String appName) {
    return _format(_text('deleteAppTitle'), <String, String>{'app': appName});
  }

  String deleted(String appName) {
    return _format(_text('deleted'), <String, String>{'app': appName});
  }

  String appPermissions(String appName) {
    return _format(_text('appPermissions'), <String, String>{'app': appName});
  }

  String permissionRequestTitle(String appName, String capability) {
    return _format(_text('permissionRequestTitle'), <String, String>{
      'app': appName,
      'capability': capability,
    });
  }

  String capabilityTitle(AppCapability capability) {
    return switch (capability) {
      AppCapability.storage => _text('capabilityStorage'),
      AppCapability.secureStorage => _text('capabilitySecureStorage'),
      AppCapability.notification => _text('capabilityNotification'),
      AppCapability.network => _text('capabilityNetwork'),
      AppCapability.device => _text('capabilityDevice'),
      AppCapability.ui => _text('capabilityUi'),
      AppCapability.clipboard => _text('capabilityClipboard'),
      AppCapability.share => _text('capabilityShare'),
      AppCapability.open => _text('capabilityOpen'),
      AppCapability.file => _text('capabilityFile'),
      AppCapability.media => _text('capabilityMedia'),
      AppCapability.location => _text('capabilityLocation'),
      AppCapability.haptics => _text('capabilityHaptics'),
      AppCapability.barcode => _text('capabilityBarcode'),
      AppCapability.audio => _text('capabilityAudio'),
      AppCapability.biometric => _text('capabilityBiometric'),
      AppCapability.contacts => _text('capabilityContacts'),
      AppCapability.calendar => _text('capabilityCalendar'),
      AppCapability.download => _text('capabilityDownload'),
      AppCapability.events => _text('capabilityEvents'),
    };
  }

  String capabilityDescription(AppCapability capability) {
    return switch (capability) {
      AppCapability.storage => _text('capabilityStorageDescription'),
      AppCapability.secureStorage => _text(
        'capabilitySecureStorageDescription',
      ),
      AppCapability.notification => _text('capabilityNotificationDescription'),
      AppCapability.network => _text('capabilityNetworkDescription'),
      AppCapability.device => _text('capabilityDeviceDescription'),
      AppCapability.ui => _text('capabilityUiDescription'),
      AppCapability.clipboard => _text('capabilityClipboardDescription'),
      AppCapability.share => _text('capabilityShareDescription'),
      AppCapability.open => _text('capabilityOpenDescription'),
      AppCapability.file => _text('capabilityFileDescription'),
      AppCapability.media => _text('capabilityMediaDescription'),
      AppCapability.location => _text('capabilityLocationDescription'),
      AppCapability.haptics => _text('capabilityHapticsDescription'),
      AppCapability.barcode => _text('capabilityBarcodeDescription'),
      AppCapability.audio => _text('capabilityAudioDescription'),
      AppCapability.biometric => _text('capabilityBiometricDescription'),
      AppCapability.contacts => _text('capabilityContactsDescription'),
      AppCapability.calendar => _text('capabilityCalendarDescription'),
      AppCapability.download => _text('capabilityDownloadDescription'),
      AppCapability.events => _text('capabilityEventsDescription'),
    };
  }

  String permissionReason(AppCapability capability) {
    return switch (capability) {
      AppCapability.storage => _text('permissionReasonStorage'),
      AppCapability.secureStorage => _text('permissionReasonSecureStorage'),
      AppCapability.notification => _text('permissionReasonNotification'),
      AppCapability.network => _text('permissionReasonNetwork'),
      AppCapability.device => _text('permissionReasonDevice'),
      AppCapability.ui => _text('permissionReasonUi'),
      AppCapability.clipboard => _text('permissionReasonClipboard'),
      AppCapability.share => _text('permissionReasonShare'),
      AppCapability.open => _text('permissionReasonOpen'),
      AppCapability.file => _text('permissionReasonFile'),
      AppCapability.media => _text('permissionReasonMedia'),
      AppCapability.location => _text('permissionReasonLocation'),
      AppCapability.haptics => _text('permissionReasonHaptics'),
      AppCapability.barcode => _text('permissionReasonBarcode'),
      AppCapability.audio => _text('permissionReasonAudio'),
      AppCapability.biometric => _text('permissionReasonBiometric'),
      AppCapability.contacts => _text('permissionReasonContacts'),
      AppCapability.calendar => _text('permissionReasonCalendar'),
      AppCapability.download => _text('permissionReasonDownload'),
      AppCapability.events => _text('permissionReasonEvents'),
    };
  }

  String _text(String key) {
    final values =
        _localizedValues[locale.languageCode] ?? _localizedValues['zh']!;
    return values[key] ?? _localizedValues['zh']![key] ?? key;
  }

  static String _format(String template, Map<String, String> values) {
    var result = template;
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}

extension WorkbenchLocalizationsX on BuildContext {
  WorkbenchLocalizations get l10n => WorkbenchLocalizations.of(this);
}

class _WorkbenchLocalizationsDelegate
    extends LocalizationsDelegate<WorkbenchLocalizations> {
  const _WorkbenchLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return WorkbenchLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<WorkbenchLocalizations> load(Locale locale) async {
    return WorkbenchLocalizations(locale);
  }

  @override
  bool shouldReload(_WorkbenchLocalizationsDelegate old) => false;
}

const _localizedValues = <String, Map<String, String>>{
  'zh': <String, String>{
    'appTitle': '拾趣',
    'importTooltip': '导入',
    'permissionsTooltip': '权限',
    'refreshTooltip': '刷新',
    'emptyLibraryTitle': '还没有本地应用',
    'emptyLibraryBody': '导入示例 bundle，即可把它作为本地 WebView 应用运行。',
    'importSampleBundle': '导入示例应用',
    'neverOpened': '从未打开',
    'lastUsed': '上次使用 {date}',
    'importScreenTitle': '导入应用 bundle',
    'importRemoteTitle': '从 Cloudflare 下载',
    'importRemoteBody':
        '输入上传脚本返回的对象 key 或完整下载 URL，宿主会从 infra.308893.xyz 下载并校验导入。',
    'remoteBundleInputLabel': 'Bundle key 或下载 URL',
    'remoteBundleInputHint':
        '例如 local.checkin.ipd 或 https://infra.308893.xyz/api/r2/objects/...',
    'downloadAndImport': '下载并导入',
    'remoteBundleRequired': '请输入 bundle key 或下载 URL。',
    'builtInSamples': '内置示例',
    'reimport': '重新导入',
    'import': '导入',
    'imported': '{app} 已导入',
    'importFailed': '导入失败：{error}',
    'runtimeTitle': '运行时',
    'appNotFound': '未找到应用',
    'deny': '拒绝',
    'allow': '允许',
    'cancel': '取消',
    'delete': '删除',
    'deleteAppTitle': '删除 {app}？',
    'deleteAppBody': '这会移除此应用及其本地 bundle 文件，也会清除此应用的本地存储数据。',
    'deleted': '{app} 已删除',
    'runtimeErrorTitle': '运行时错误',
    'reload': '重新加载',
    'permissionsTitle': '权限',
    'appPermissions': '{app} 权限',
    'permissionsIntro': '权限由 app.json 声明，可随时关闭。关闭后的能力会被运行时桥接拒绝。',
    'noRuntimePermissions': '此应用没有声明运行时权限。',
    'manageTitle': '管理',
    'manageEyebrow': 'MANAGE  ·  这只小工具',
    'manageHeroSubtitle': '调整权限、沉浸模式，或者把它温柔地送走。',
    'permissionSectionTitle': '权限开关',
    'permissionSectionEyebrow': 'PERMISSIONS',
    'immersiveSectionTitle': '沉浸模式',
    'immersiveSectionEyebrow': 'IMMERSIVE',
    'immersiveTopLabel': '顶部留出状态栏',
    'immersiveTopDescription': '关闭后，mini app 会铺到状态栏背后，请用 CSS env(safe-area-inset-top) 自行避让。',
    'immersiveBottomLabel': '底部留出 home 指示器',
    'immersiveBottomDescription': '关闭后，mini app 会铺到底部手势条背后，请用 CSS env(safe-area-inset-bottom) 自行避让。',
    'immersiveHeaderLabel': '显示宿主顶栏',
    'immersiveHeaderDescription': '打开后会在 mini app 上方加一条返回 / 刷新 / 管理的 chrome 顶栏。',
    'immersiveResetDefault': '恢复 manifest 默认',
    'immersiveOverridden': '当前为自定义覆盖',
    'dangerSectionTitle': '危险操作',
    'dangerSectionEyebrow': 'DANGER',
    'deleteAppButton': '删除这只小工具',
    'deleteAppHint': '会移除应用、本地 bundle 与隔离存储。',
    'swipeToManageHint': '左滑卡片可以管理',
    'manageAction': '管理',
    'permissionRequestTitle': '{app} 请求使用{capability}',
    'capabilityStorage': '存储',
    'capabilitySecureStorage': '安全存储',
    'capabilityNotification': '通知',
    'capabilityNetwork': '网络',
    'capabilityDevice': '设备信息',
    'capabilityUi': '界面交互',
    'capabilityClipboard': '剪贴板',
    'capabilityShare': '系统分享',
    'capabilityOpen': '打开外部资源',
    'capabilityFile': '文件',
    'capabilityMedia': '媒体',
    'capabilityLocation': '位置',
    'capabilityHaptics': '触感反馈',
    'capabilityBarcode': '扫码',
    'capabilityAudio': '音频',
    'capabilityBiometric': '生物识别',
    'capabilityContacts': '联系人',
    'capabilityCalendar': '日历',
    'capabilityDownload': '下载',
    'capabilityEvents': '运行时事件',
    'capabilityStorageDescription': '读取和写入此应用自己的本地数据。',
    'capabilitySecureStorageDescription': '读取和写入此应用自己的加密敏感数据。',
    'capabilityNotificationDescription': '请求并安排本地提醒。',
    'capabilityNetworkDescription': '访问 manifest allowlist 中的 HTTPS 地址。',
    'capabilityDeviceDescription': '读取平台、设备、应用版本、网络和电量状态。',
    'capabilityUiDescription': '使用宿主 toast、弹窗、确认框和加载状态。',
    'capabilityClipboardDescription': '读取和写入系统剪贴板文本。',
    'capabilityShareDescription': '调用系统分享面板分享文本或文件。',
    'capabilityOpenDescription': '打开 URL、电话、邮件、地图和系统设置。',
    'capabilityFileDescription': '选择、保存、读取和分享用户授权的文件。',
    'capabilityMediaDescription': '选择或拍摄图片和视频。',
    'capabilityLocationDescription': '请求位置权限并读取当前位置。',
    'capabilityHapticsDescription': '触发系统触感反馈。',
    'capabilityBarcodeDescription': '打开相机扫描二维码或条形码。',
    'capabilityAudioDescription': '录音、播放和停止音频。',
    'capabilityBiometricDescription': '请求系统生物识别认证。',
    'capabilityContactsDescription': '让用户选择一个联系人。',
    'capabilityCalendarDescription': '向系统日历添加事件。',
    'capabilityDownloadDescription': '下载 allowlist 中的 HTTPS 文件。',
    'capabilityEventsDescription': '监听前后台、网络、主题、语言和权限变化。',
    'permissionReasonStorage': '允许 Web 应用只读写它自己的本地数据命名空间。',
    'permissionReasonSecureStorage': '允许 Web 应用保存 token、密钥等敏感信息。',
    'permissionReasonNotification': '允许 Web 应用通过宿主运行时请求本地提醒。',
    'permissionReasonNetwork': '允许 Web 应用访问 manifest allowlist 中的 HTTPS 地址。',
    'permissionReasonDevice': '允许 Web 应用读取设备和应用的基础状态。',
    'permissionReasonUi': '允许 Web 应用使用宿主界面组件展示反馈。',
    'permissionReasonClipboard': '允许 Web 应用访问系统剪贴板文本。',
    'permissionReasonShare': '允许 Web 应用打开系统分享面板。',
    'permissionReasonOpen': '允许 Web 应用打开外部应用或系统设置。',
    'permissionReasonFile': '允许 Web 应用访问用户选择或它自己创建的文件。',
    'permissionReasonMedia': '允许 Web 应用选择或拍摄媒体文件。',
    'permissionReasonLocation': '允许 Web 应用读取当前位置。',
    'permissionReasonHaptics': '允许 Web 应用触发触感反馈。',
    'permissionReasonBarcode': '允许 Web 应用使用相机扫码。',
    'permissionReasonAudio': '允许 Web 应用使用麦克风录音并播放音频。',
    'permissionReasonBiometric': '允许 Web 应用请求系统身份验证。',
    'permissionReasonContacts': '允许 Web 应用让你选择一个联系人。',
    'permissionReasonCalendar': '允许 Web 应用创建系统日历事件。',
    'permissionReasonDownload': '允许 Web 应用下载指定 allowlist 中的文件。',
    'permissionReasonEvents': '允许 Web 应用监听宿主运行时事件。',
  },
  'en': <String, String>{
    'appTitle': 'Curio',
    'importTooltip': 'Import',
    'permissionsTooltip': 'Permissions',
    'refreshTooltip': 'Refresh',
    'emptyLibraryTitle': 'No local apps yet',
    'emptyLibraryBody':
        'Import a sample bundle to run it as a local WebView app.',
    'importSampleBundle': 'Import sample bundle',
    'neverOpened': 'Never opened',
    'lastUsed': 'Last used {date}',
    'importScreenTitle': 'Import app bundle',
    'importRemoteTitle': 'Download from Cloudflare',
    'importRemoteBody':
        'Enter the object key or full download URL returned by the upload script. The host downloads from infra.308893.xyz, validates, and imports it.',
    'remoteBundleInputLabel': 'Bundle key or download URL',
    'remoteBundleInputHint':
        'Example: local.checkin.ipd or https://infra.308893.xyz/api/r2/objects/...',
    'downloadAndImport': 'Download and import',
    'remoteBundleRequired': 'Enter a bundle key or download URL.',
    'builtInSamples': 'Built-in samples',
    'reimport': 'Re-import',
    'import': 'Import',
    'imported': '{app} imported',
    'importFailed': 'Import failed: {error}',
    'runtimeTitle': 'Runtime',
    'appNotFound': 'App not found',
    'deny': 'Deny',
    'allow': 'Allow',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'deleteAppTitle': 'Delete {app}?',
    'deleteAppBody':
        'This removes the app, its local bundle files, and its local storage data.',
    'deleted': '{app} deleted',
    'runtimeErrorTitle': 'Runtime error',
    'reload': 'Reload',
    'permissionsTitle': 'Permissions',
    'appPermissions': '{app} permissions',
    'permissionsIntro':
        'Permissions are declared by app.json and can be disabled at any time. Disabled capabilities are rejected by the runtime bridge.',
    'noRuntimePermissions': 'This app declares no runtime permissions.',
    'manageTitle': 'Manage',
    'manageEyebrow': 'MANAGE  ·  THIS LITTLE TOOL',
    'manageHeroSubtitle':
        'Tune permissions, immersive mode, or quietly send it away.',
    'permissionSectionTitle': 'Permissions',
    'permissionSectionEyebrow': 'PERMISSIONS',
    'immersiveSectionTitle': 'Immersive mode',
    'immersiveSectionEyebrow': 'IMMERSIVE',
    'immersiveTopLabel': 'Reserve top status bar',
    'immersiveTopDescription':
        'When off, the mini app extends behind the status bar. Use CSS env(safe-area-inset-top) to adapt.',
    'immersiveBottomLabel': 'Reserve bottom home indicator',
    'immersiveBottomDescription':
        'When off, the mini app extends behind the bottom gesture bar. Use CSS env(safe-area-inset-bottom) to adapt.',
    'immersiveHeaderLabel': 'Show host header',
    'immersiveHeaderDescription':
        'When on, a back / refresh / manage chrome header is shown above the mini app.',
    'immersiveResetDefault': 'Reset to manifest default',
    'immersiveOverridden': 'Currently overridden',
    'dangerSectionTitle': 'Danger zone',
    'dangerSectionEyebrow': 'DANGER',
    'deleteAppButton': 'Delete this little tool',
    'deleteAppHint':
        'Removes the app, its local bundle, and its isolated storage.',
    'swipeToManageHint': 'Swipe a card left to manage',
    'manageAction': 'Manage',
    'permissionRequestTitle': '{app} requests {capability}',
    'capabilityStorage': 'Storage',
    'capabilitySecureStorage': 'Secure storage',
    'capabilityNotification': 'Notifications',
    'capabilityNetwork': 'Network',
    'capabilityDevice': 'Device',
    'capabilityUi': 'UI',
    'capabilityClipboard': 'Clipboard',
    'capabilityShare': 'Share',
    'capabilityOpen': 'Open',
    'capabilityFile': 'Files',
    'capabilityMedia': 'Media',
    'capabilityLocation': 'Location',
    'capabilityHaptics': 'Haptics',
    'capabilityBarcode': 'Barcode',
    'capabilityAudio': 'Audio',
    'capabilityBiometric': 'Biometrics',
    'capabilityContacts': 'Contacts',
    'capabilityCalendar': 'Calendar',
    'capabilityDownload': 'Download',
    'capabilityEvents': 'Runtime events',
    'capabilityStorageDescription': 'Read and write this app own local data.',
    'capabilitySecureStorageDescription':
        'Read and write this app own encrypted sensitive data.',
    'capabilityNotificationDescription':
        'Request and schedule local reminders.',
    'capabilityNetworkDescription': 'Fetch HTTPS URLs from manifest allowlist.',
    'capabilityDeviceDescription':
        'Read platform, device, app version, network, and battery state.',
    'capabilityUiDescription':
        'Use host toast, alert, confirm, action sheet, and loading UI.',
    'capabilityClipboardDescription': 'Read and write system clipboard text.',
    'capabilityShareDescription': 'Open the system share sheet.',
    'capabilityOpenDescription':
        'Open URLs, phone, email, maps, and system settings.',
    'capabilityFileDescription':
        'Pick, save, read, and share user-authorized files.',
    'capabilityMediaDescription': 'Pick or capture images and videos.',
    'capabilityLocationDescription':
        'Request location permission and read current position.',
    'capabilityHapticsDescription': 'Trigger system haptic feedback.',
    'capabilityBarcodeDescription': 'Scan QR codes and barcodes.',
    'capabilityAudioDescription': 'Record, play, and stop audio.',
    'capabilityBiometricDescription': 'Request system biometric auth.',
    'capabilityContactsDescription': 'Let the user pick one contact.',
    'capabilityCalendarDescription': 'Add events to the system calendar.',
    'capabilityDownloadDescription': 'Download HTTPS files from allowlist.',
    'capabilityEventsDescription': 'Listen to host runtime events.',
    'permissionReasonStorage':
        'This allows the web app to read and write only its own local data namespace.',
    'permissionReasonSecureStorage':
        'This allows the web app to store tokens, keys, and other sensitive values.',
    'permissionReasonNotification':
        'This allows the web app to request local reminders through the host runtime.',
    'permissionReasonNetwork':
        'This allows the web app to fetch HTTPS URLs from its manifest allowlist.',
    'permissionReasonDevice':
        'This allows the web app to read basic device and app state.',
    'permissionReasonUi': 'This allows the web app to show host UI feedback.',
    'permissionReasonClipboard':
        'This allows the web app to access system clipboard text.',
    'permissionReasonShare':
        'This allows the web app to open the system share sheet.',
    'permissionReasonOpen':
        'This allows the web app to open external apps or settings.',
    'permissionReasonFile':
        'This allows the web app to access files you pick or it creates.',
    'permissionReasonMedia':
        'This allows the web app to pick or capture media files.',
    'permissionReasonLocation':
        'This allows the web app to read the current location.',
    'permissionReasonHaptics':
        'This allows the web app to trigger haptic feedback.',
    'permissionReasonBarcode': 'This allows the web app to scan codes.',
    'permissionReasonAudio':
        'This allows the web app to record and play audio.',
    'permissionReasonBiometric':
        'This allows the web app to request system authentication.',
    'permissionReasonContacts':
        'This allows the web app to let you pick one contact.',
    'permissionReasonCalendar':
        'This allows the web app to create system calendar events.',
    'permissionReasonDownload':
        'This allows the web app to download allowlisted files.',
    'permissionReasonEvents':
        'This allows the web app to listen to host runtime events.',
  },
};
