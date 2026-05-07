import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import 'theme.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({
    required this.environment,
    required this.appId,
    super.key,
  });

  final AppEnvironment environment;
  final String appId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: environment.library,
      builder: (context, _) {
        final l10n = context.l10n;
        final app = environment.library.findById(appId);
        if (app == null) {
          return Scaffold(
            backgroundColor: WorkbenchPalette.cream,
            body: SafeArea(
              child: Stack(
                children: <Widget>[
                  const Positioned(
                    left: 16,
                    top: 12,
                    child: FloatingBackButton(),
                  ),
                  Center(
                    child: Text(
                      l10n.appNotFound,
                      style: const TextStyle(
                        color: WorkbenchPalette.inkSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final permissions = app.manifest.permissions.toList();
        final grantedCount = permissions
            .where((p) => app.grantedPermissions[p] ?? false)
            .length;
        return Scaffold(
          backgroundColor: WorkbenchPalette.cream,
          body: SafeArea(
            top: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: <Widget>[
                _PermissionHero(
                  app: app,
                  grantedCount: grantedCount,
                  totalCount: permissions.length,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SoftCard(
                        background: const Color(0xFFFFF7EE),
                        border: const Color(0xFFEEDDC4),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.tips_and_updates_outlined,
                              size: 18,
                              color: Color(0xFFC58A2E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.permissionsIntro,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.65,
                                  color: WorkbenchPalette.inkSecondary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (permissions.isEmpty)
                        SoftCard(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: WorkbenchPalette.creamDeep,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.lock_open_rounded,
                                  color: WorkbenchPalette.inkSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.noRuntimePermissions,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: WorkbenchPalette.inkSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List<Widget>.generate(permissions.length, (index) {
                          final capability = permissions[index];
                          final granted =
                              app.grantedPermissions[capability] ?? false;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == permissions.length - 1 ? 0 : 12,
                            ),
                            child: _PermissionCard(
                              capability: capability,
                              granted: granted,
                              onChanged: (value) =>
                                  environment.library.setPermission(
                                    appId,
                                    capability,
                                    value,
                                  ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionHero extends StatelessWidget {
  const _PermissionHero({
    required this.app,
    required this.grantedCount,
    required this.totalCount,
  });

  final InstalledApp app;
  final int grantedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: WorkbenchPalette.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: -42,
            top: -36,
            child: _Bubble(
              color: WorkbenchPalette.coral.withValues(alpha: 0.22),
              size: 150,
            ),
          ),
          Positioned(
            right: -22,
            bottom: -48,
            child: _Bubble(
              color: WorkbenchPalette.honey.withValues(alpha: 0.36),
              size: 110,
            ),
          ),
          Positioned(
            left: -34,
            bottom: 18,
            child: _Bubble(
              color: WorkbenchPalette.matcha.withValues(alpha: 0.32),
              size: 78,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FloatingBackButton(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WorkbenchPalette.paper.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: WorkbenchPalette.coral.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'PERMISSIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                      color: WorkbenchPalette.coralInk,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    IconSticker(label: app.manifest.icon, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            l10n.appPermissions(app.manifest.name),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: 0.3,
                              color: WorkbenchPalette.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalCount == 0
                                ? '此应用没有声明运行时权限'
                                : '已开启 $grantedCount / $totalCount  ·  v${app.manifest.version}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: WorkbenchPalette.inkSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.capability,
    required this.granted,
    required this.onChanged,
  });

  final AppCapability capability;
  final bool granted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _colorFor(capability);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(_iconFor(capability), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l10n.capabilityTitle(capability),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: WorkbenchPalette.inkPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (capability.requiresRuntimeGrant)
                      SoftTag(label: '运行时', color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.capabilityDescription(capability),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: WorkbenchPalette.inkSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: granted,
            onChanged: onChanged,
            activeTrackColor: color,
            inactiveTrackColor: WorkbenchPalette.creamDeep,
            inactiveThumbColor: WorkbenchPalette.paper,
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Icon(Icons.check_rounded, size: 16, color: color);
              }
              return const Icon(
                Icons.close_rounded,
                size: 14,
                color: WorkbenchPalette.inkSoft,
              );
            }),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(AppCapability capability) {
    return switch (capability) {
      AppCapability.storage => Icons.storage_outlined,
      AppCapability.secureStorage => Icons.enhanced_encryption_outlined,
      AppCapability.notification => Icons.notifications_outlined,
      AppCapability.network => Icons.public_outlined,
      AppCapability.device => Icons.devices_outlined,
      AppCapability.ui => Icons.widgets_outlined,
      AppCapability.clipboard => Icons.content_paste_outlined,
      AppCapability.share => Icons.ios_share_outlined,
      AppCapability.open => Icons.open_in_new_outlined,
      AppCapability.file => Icons.folder_open_outlined,
      AppCapability.media => Icons.photo_library_outlined,
      AppCapability.location => Icons.location_on_outlined,
      AppCapability.haptics => Icons.vibration_outlined,
      AppCapability.barcode => Icons.qr_code_scanner_outlined,
      AppCapability.audio => Icons.mic_outlined,
      AppCapability.biometric => Icons.fingerprint,
      AppCapability.contacts => Icons.contacts_outlined,
      AppCapability.calendar => Icons.event_outlined,
      AppCapability.download => Icons.download_outlined,
      AppCapability.events => Icons.sensors_outlined,
    };
  }

  static Color _colorFor(AppCapability capability) {
    switch (capability) {
      case AppCapability.storage:
      case AppCapability.secureStorage:
      case AppCapability.file:
        return WorkbenchPalette.coral;
      case AppCapability.notification:
      case AppCapability.events:
        return const Color(0xFFE6A027);
      case AppCapability.network:
      case AppCapability.download:
        return const Color(0xFF7E9DB8);
      case AppCapability.media:
      case AppCapability.barcode:
      case AppCapability.audio:
        return const Color(0xFFB89DC4);
      case AppCapability.location:
      case AppCapability.calendar:
        return const Color(0xFF94A878);
      case AppCapability.biometric:
        return const Color(0xFFC97A77);
      default:
        return WorkbenchPalette.inkSecondary;
    }
  }
}
