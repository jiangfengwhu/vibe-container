import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import 'theme.dart';

/// 应用管理页：合并权限、沉浸模式与删除入口，替代旧的 PermissionScreen。
class ManageScreen extends StatelessWidget {
  const ManageScreen({
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
        return Scaffold(
          backgroundColor: WorkbenchPalette.cream,
          body: SafeArea(
            top: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: <Widget>[
                _ManageHero(app: app),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _SectionHeader(
                        eyebrow: l10n.immersiveSectionEyebrow,
                        title: l10n.immersiveSectionTitle,
                      ),
                      const SizedBox(height: 12),
                      _ImmersiveSection(app: app, environment: environment),
                      const SizedBox(height: 26),
                      _SectionHeader(
                        eyebrow: l10n.permissionSectionEyebrow,
                        title: l10n.permissionSectionTitle,
                        caption: l10n.permissionsIntro,
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 26),
                      _SectionHeader(
                        eyebrow: l10n.dangerSectionEyebrow,
                        title: l10n.dangerSectionTitle,
                      ),
                      const SizedBox(height: 12),
                      _DeleteCard(
                        app: app,
                        onDeleted: () => Navigator.of(context).maybePop(),
                        environment: environment,
                      ),
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

class _ManageHero extends StatelessWidget {
  const _ManageHero({required this.app});

  final InstalledApp app;

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
                  child: Text(
                    l10n.manageEyebrow,
                    style: const TextStyle(
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
                            app.manifest.name,
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
                            l10n.manageHeroSubtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: WorkbenchPalette.inkSecondary,
                              letterSpacing: 0.2,
                              height: 1.55,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.caption,
  });

  final String eyebrow;
  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const DotDecor(),
              const SizedBox(width: 8),
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: WorkbenchPalette.coralInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.4,
                  color: WorkbenchPalette.inkPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  width: 22,
                  height: 2,
                  color: WorkbenchPalette.coral,
                ),
              ),
            ],
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12.5,
                color: WorkbenchPalette.inkSecondary,
                letterSpacing: 0.2,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImmersiveSection extends StatelessWidget {
  const _ImmersiveSection({required this.app, required this.environment});

  final InstalledApp app;
  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effective = app.effectiveImmersive;
    final overridden = app.immersiveOverride != null;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: <Widget>[
          _ImmersiveTile(
            icon: Icons.expand_less_rounded,
            color: const Color(0xFF7E9DB8),
            title: l10n.immersiveTopLabel,
            description: l10n.immersiveTopDescription,
            value: effective.topInset,
            onChanged: (value) =>
                _update(effective.copyWith(topInset: value)),
          ),
          const Divider(indent: 18, endIndent: 18, height: 1),
          _ImmersiveTile(
            icon: Icons.expand_more_rounded,
            color: const Color(0xFF94A878),
            title: l10n.immersiveBottomLabel,
            description: l10n.immersiveBottomDescription,
            value: effective.bottomInset,
            onChanged: (value) =>
                _update(effective.copyWith(bottomInset: value)),
          ),
          const Divider(indent: 18, endIndent: 18, height: 1),
          _ImmersiveTile(
            icon: Icons.view_headline_rounded,
            color: WorkbenchPalette.coral,
            title: l10n.immersiveHeaderLabel,
            description: l10n.immersiveHeaderDescription,
            value: effective.showHeader,
            onChanged: (value) =>
                _update(effective.copyWith(showHeader: value)),
          ),
          if (overridden)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.bookmark_added_outlined,
                    size: 14,
                    color: WorkbenchPalette.inkSoft,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.immersiveOverridden,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: WorkbenchPalette.inkSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        environment.library.clearImmersiveOverride(
                          app.manifest.id,
                        ),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: Text(l10n.immersiveResetDefault),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _update(AppImmersiveConfig next) {
    return environment.library.setImmersive(app.manifest.id, next);
  }
}

class _ImmersiveTile extends StatelessWidget {
  const _ImmersiveTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WorkbenchPalette.inkPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
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
            value: value,
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

class _DeleteCard extends StatelessWidget {
  const _DeleteCard({
    required this.app,
    required this.environment,
    required this.onDeleted,
  });

  final InstalledApp app;
  final AppEnvironment environment;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SoftCard(
      background: const Color(0xFFFFF1EE),
      border: const Color(0xFFEFC9C2),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WorkbenchPalette.coral.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WorkbenchPalette.coral.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: WorkbenchPalette.coralInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.deleteAppButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: WorkbenchPalette.coralInk,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.deleteAppHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WorkbenchPalette.inkSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAppTitle(app.manifest.name)),
        content: Text(l10n.deleteAppBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await environment.storage.delete(app.manifest.id);
    await environment.library.remove(app.manifest.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.deleted(app.manifest.name))));
    onDeleted();
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
