import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import 'import_screen.dart';
import 'manage_screen.dart';
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
                    eyebrow: '${l10n.appTitle}  ·  CURIO',
                    title: '把好玩的小工具，\n一件件拾回家。',
                    subtitle: '把你的app放进口袋，拒绝localhost😛',
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
                        return _SwipeableAppTile(
                          key: ValueKey<String>(app.manifest.id),
                          app: app,
                          gradient: _gradientFor(app.manifest.id),
                          onOpen: () => _openApp(context, app),
                          onManage: () => _openManage(context, app),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: apps.length,
                    ),
                  ),
                if (apps.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.swipe_left_rounded,
                            size: 14,
                            color: WorkbenchPalette.inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.swipeToManageHint,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: WorkbenchPalette.inkSoft,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
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
    unawaited(
      environment.library
          .setLastUsed(app.manifest.id, DateTime.now())
          .catchError((Object _) {}),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RuntimeScreen(environment: environment, appId: app.manifest.id),
      ),
    );
  }

  Future<void> _openManage(BuildContext context, InstalledApp app) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ManageScreen(environment: environment, appId: app.manifest.id),
      ),
    );
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
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.importApp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 左滑卡片：拖动时显示底部「管理」按钮；松手后若超过阈值则进入管理页，否则吸附到展开/收起。
class _SwipeableAppTile extends StatefulWidget {
  const _SwipeableAppTile({
    required this.app,
    required this.gradient,
    required this.onOpen,
    required this.onManage,
    super.key,
  });

  final InstalledApp app;
  final LinearGradient gradient;
  final VoidCallback onOpen;
  final VoidCallback onManage;

  @override
  State<_SwipeableAppTile> createState() => _SwipeableAppTileState();
}

class _SwipeableAppTileState extends State<_SwipeableAppTile>
    with SingleTickerProviderStateMixin {
  static const double _revealWidth = 96;
  static const double _autoTriggerDistance = 168;
  static const double _maxOvershoot = 48;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late Animation<double> _animation = AlwaysStoppedAnimation<double>(0);
  double _drag = 0;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _drag = _animation.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    setState(() {
      _drag = (_drag - details.delta.dx).clamp(
        0.0,
        _autoTriggerDistance + _maxOvershoot,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drag >= _autoTriggerDistance) {
      _animateTo(0, opening: false);
      widget.onManage();
      return;
    }
    if (_drag >= _revealWidth * 0.55) {
      _animateTo(_revealWidth, opening: true);
    } else {
      _animateTo(0, opening: false);
    }
  }

  void _animateTo(double target, {required bool opening}) {
    _open = opening;
    _animation = Tween<double>(
      begin: _drag,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller
      ..reset()
      ..forward();
  }

  void _close() {
    if (_open || _drag > 0) {
      _animateTo(0, opening: false);
    }
  }

  void _handleTap() {
    if (_open) {
      _close();
      widget.onManage();
    } else {
      widget.onOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _ManageRevealLayer(
              progress: (_drag / _autoTriggerDistance).clamp(0.0, 1.0),
              onTap: () {
                _close();
                widget.onManage();
              },
            ),
          ),
          Transform.translate(
            offset: Offset(-_drag, 0),
            child: _AppTileBody(app: widget.app, gradient: widget.gradient),
          ),
        ],
      ),
    );
  }
}

class _ManageRevealLayer extends StatelessWidget {
  const _ManageRevealLayer({required this.progress, required this.onTap});

  /// 0 -> 完全收起，1 -> 已经达到自动触发阈值。
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (progress <= 0.001) {
      return const SizedBox.shrink();
    }
    final triggered = progress >= 1.0;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Container(
          width: 96 + (progress * 24),
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            gradient: WorkbenchPalette.coralGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: WorkbenchPalette.tinyShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      triggered
                          ? Icons.arrow_forward_rounded
                          : Icons.tune_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.manageAction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTileBody extends StatelessWidget {
  const _AppTileBody({required this.app, required this.gradient});

  final InstalledApp app;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final manifest = app.manifest;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconSticker(label: manifest.icon, gradient: gradient),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
