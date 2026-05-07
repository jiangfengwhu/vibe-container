import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../services/app_environment.dart';
import '../services/bundle_manager.dart';
import 'theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _remoteController = TextEditingController();
  late Future<List<SampleBundle>> _samples;
  String? _busySampleId;

  @override
  void initState() {
    super.initState();
    _samples = widget.environment.bundleManager.listSamples();
  }

  @override
  void dispose() {
    _remoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkbenchPalette.cream,
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            const HeroBanner(
              eyebrow: 'IMPORT  &  PLAY',
              title: '挑一个小工具，搬回家',
              subtitle: '从云端拖回 AI 生成的 .iprod 包，\n或挑一个内置示例，立刻把它点开。',
              leading: FloatingBackButton(),
              contentPadding: EdgeInsets.fromLTRB(20, 8, 20, 28),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _RemoteImportCard(
                    controller: _remoteController,
                    busy: _busySampleId == '__remote__',
                    enabled: _busySampleId == null,
                    onSubmit: _importRemoteArchive,
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(
                    eyebrow: 'BUILT-IN  SAMPLES',
                    title: context.l10n.builtInSamples,
                    caption: '官方精选小样本，一键体验运行时桥接',
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<SampleBundle>>(
                    future: _samples,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            ),
                          ),
                        );
                      }
                      final samples = snapshot.data ?? const <SampleBundle>[];
                      if (samples.isEmpty) {
                        return _EmptySamplesHint();
                      }
                      return Column(
                        children: <Widget>[
                          for (final sample in samples) ...<Widget>[
                            _SampleImportCard(
                              sample: sample,
                              busy: _busySampleId == sample.id,
                              enabled: _busySampleId == null,
                              isInstalled:
                                  widget.environment.library.findById(
                                    'local.${sample.id}',
                                  ) !=
                                  null,
                              onImport: () => _import(sample),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importRemoteArchive() async {
    final source = _remoteController.text.trim();
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.remoteBundleRequired)),
      );
      return;
    }

    setState(() => _busySampleId = '__remote__');
    try {
      final installed = await widget.environment.bundleManager
          .importRemoteArchive(source);
      await widget.environment.library.upsert(installed);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imported(installed.manifest.name))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.importFailed(error))));
    } finally {
      if (mounted) {
        setState(() => _busySampleId = null);
      }
    }
  }

  Future<void> _import(SampleBundle sample) async {
    setState(() => _busySampleId = sample.id);
    try {
      final installed = await widget.environment.bundleManager.importSample(
        sample.id,
      );
      await widget.environment.library.upsert(installed);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imported(installed.manifest.name))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.importFailed(error))));
    } finally {
      if (mounted) {
        setState(() => _busySampleId = null);
      }
    }
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
                  fontSize: 20,
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoteImportCard extends StatelessWidget {
  const _RemoteImportCard({
    required this.controller,
    required this.busy,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool busy;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFFFF1ED), Color(0xFFFFE6E2)],
      ),
      border: const Color(0xFFF5C8C2),
      shadow: WorkbenchPalette.softShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: WorkbenchPalette.coralGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33E94B5C),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.importRemoteTitle,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: WorkbenchPalette.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.importRemoteBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.65,
              color: WorkbenchPalette.inkSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: l10n.remoteBundleInputLabel,
              hintText: l10n.remoteBundleInputHint,
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: WorkbenchPalette.inkSoft,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: enabled ? onSubmit : null,
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_download_outlined, size: 18),
            label: Text(l10n.downloadAndImport),
          ),
        ],
      ),
    );
  }
}

class _EmptySamplesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
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
              Icons.menu_book_outlined,
              color: WorkbenchPalette.inkSecondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '内置示例还在准备中，先去远程导入试试看。',
              style: TextStyle(
                fontSize: 13,
                color: WorkbenchPalette.inkSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleImportCard extends StatelessWidget {
  const _SampleImportCard({
    required this.sample,
    required this.busy,
    required this.enabled,
    required this.isInstalled,
    required this.onImport,
  });

  final SampleBundle sample;
  final bool busy;
  final bool enabled;
  final bool isInstalled;
  final VoidCallback onImport;

  static const _gradients = <LinearGradient>[
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFFE3DD), Color(0xFFFCD2CB)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFCEBC7), Color(0xFFF5DBA2)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFE3EBD3), Color(0xFFC9D8B4)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFE0EBF3), Color(0xFFB7CFE0)],
    ),
  ];

  LinearGradient get _seedGradient {
    final hash = sample.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _seedGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: WorkbenchPalette.inkPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            sample.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: WorkbenchPalette.inkPrimary,
                            ),
                          ),
                        ),
                        if (isInstalled)
                          const SoftTag(
                            label: '已安装',
                            color: WorkbenchPalette.inkSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sample.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        color: WorkbenchPalette.inkSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: enabled ? onImport : null,
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isInstalled
                        ? Icons.refresh_rounded
                        : Icons.download_rounded,
                    size: 18,
                  ),
            label: Text(isInstalled ? l10n.reimport : l10n.import),
            style: OutlinedButton.styleFrom(
              foregroundColor: WorkbenchPalette.coralInk,
              backgroundColor: WorkbenchPalette.coralWash.withValues(
                alpha: 0.55,
              ),
              side: BorderSide(
                color: WorkbenchPalette.coral.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
