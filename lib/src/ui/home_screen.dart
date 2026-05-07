import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import 'import_screen.dart';
import 'permission_screen.dart';
import 'runtime_screen.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.environment, super.key});

  final AppEnvironment environment;

  static const _stickerGradients = <LinearGradient>[
    WorkbenchPalette.coralGradient,
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFF7B2B2), Color(0xFFE48A8A)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFF6CD78), Color(0xFFE2A552)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFC9D8B4), Color(0xFF94A878)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFB7CFE0), Color(0xFF7E9DB8)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFE6CFEA), Color(0xFFB89DC4)],
    ),
  ];

  static LinearGradient _gradientFor(String seed) {
    if (seed.isEmpty) {
      return _stickerGradients.first;
    }
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return _stickerGradients[hash % _stickerGradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: environment.library,
      builder: (context, _) {
        final apps = environment.library.apps;
        final l10n = context.l10n;
        return Scaffold(
          backgroundColor: WorkbenchPalette.cream,
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: HeroBanner(
                    eyebrow: 'YOUR  WORKBENCH',
                    title: l10n.appTitle,
                    subtitle: '把 AI 生成的小工具，温柔收进口袋。\n慢慢用，慢慢搭，像写日记一样。',
                    trailing: _ImportFab(onTap: () => _openImport(context)),
                    contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                    child: _SectionHeader(
                      eyebrow: 'MY  LITTLE  APPS',
                      title: '我的小桌面',
                      caption: apps.isEmpty
                          ? '还没有任何应用，先去导入一个吧～'
                          : '${apps.length} 个本地小应用，点开继续使用',
                    ),
                  ),
                ),
                if (apps.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyLibrary(onImport: () => _openImport(context)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return _AppTile(
                          app: app,
                          gradient: _gradientFor(app.manifest.id),
                          onOpen: () => _openApp(context, app),
                          onPermissions: () => _openPermissions(context, app),
                          onDelete: () => _deleteApp(context, app),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: apps.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openImport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImportScreen(environment: environment),
      ),
    );
  }

  Future<void> _openApp(BuildContext context, InstalledApp app) async {
    await environment.library.setLastUsed(app.manifest.id, DateTime.now());
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RuntimeScreen(environment: environment, appId: app.manifest.id),
      ),
    );
  }

  Future<void> _openPermissions(BuildContext context, InstalledApp app) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PermissionScreen(environment: environment, appId: app.manifest.id),
      ),
    );
  }

  Future<void> _deleteApp(BuildContext context, InstalledApp app) async {
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
  }
}

class _ImportFab extends StatelessWidget {
  const _ImportFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.importTooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: WorkbenchPalette.coralGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
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
    return Column(
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
                fontSize: 22,
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
                width: 24,
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
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: WorkbenchPalette.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: WorkbenchPalette.sand),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 28,
                      top: 28,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: WorkbenchPalette.coralWash,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 32,
                      bottom: 30,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: WorkbenchPalette.honey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      top: 40,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: WorkbenchPalette.matcha,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: WorkbenchPalette.paper,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: WorkbenchPalette.softShadow,
                        ),
                        child: const Icon(
                          Icons.coffee_outlined,
                          size: 44,
                          color: WorkbenchPalette.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.emptyLibraryTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: WorkbenchPalette.inkPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.emptyLibraryBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: WorkbenchPalette.inkSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.importSampleBundle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.gradient,
    required this.onOpen,
    required this.onPermissions,
    required this.onDelete,
  });

  final InstalledApp app;
  final LinearGradient gradient;
  final VoidCallback onOpen;
  final VoidCallback onPermissions;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final manifest = app.manifest;
    final l10n = context.l10n;
    final lastUsed = app.lastUsedAt == null
        ? l10n.neverOpened
        : l10n.lastUsed(_formatDate(app.lastUsedAt!.toLocal()));
    final permissions = manifest.permissions.toList();

    return SoftCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconSticker(label: manifest.icon, gradient: gradient),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        manifest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: WorkbenchPalette.inkPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manifest.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: WorkbenchPalette.inkSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: WorkbenchPalette.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            lastUsed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: WorkbenchPalette.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  _GhostIconButton(
                    tooltip: l10n.permissionsTooltip,
                    icon: Icons.shield_outlined,
                    onPressed: onPermissions,
                  ),
                  const SizedBox(height: 6),
                  _GhostIconButton(
                    tooltip: l10n.delete,
                    icon: Icons.delete_outline_rounded,
                    onPressed: onDelete,
                    color: WorkbenchPalette.coralInk,
                  ),
                ],
              ),
            ],
          ),
          if (permissions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final permission in permissions.take(4))
                  SoftTag(
                    label: l10n.capabilityTitle(permission),
                    color: _tagColorFor(permission),
                  ),
                if (permissions.length > 4)
                  SoftTag(
                    label: '+${permissions.length - 4}',
                    color: WorkbenchPalette.inkSecondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _tagColorFor(AppCapability capability) {
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
      default:
        return WorkbenchPalette.inkSecondary;
    }
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = WorkbenchPalette.inkSecondary,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WorkbenchPalette.cream,
              shape: BoxShape.circle,
              border: Border.all(color: WorkbenchPalette.sand),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}
