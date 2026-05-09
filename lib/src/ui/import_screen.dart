import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../services/app_environment.dart';
import 'theme.dart';

/// 云端示例 bundle 对象名（与上传脚本 / R2 上一致）。
const String kRemoteOfficialDemoBundleKey = '拾趣.ipd';

/// 输入框里展示给用户的示例 bundle 名（不含扩展名，提交时会自动补全）。
const String kRemoteOfficialDemoBundleDisplayName = '拾趣';

const String _kBundleExtension = '.ipd';

String _normalizeRemoteBundleSource(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains('://')) return trimmed;
  if (trimmed.toLowerCase().endsWith(_kBundleExtension)) return trimmed;
  return '$trimmed$_kBundleExtension';
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _remoteController = TextEditingController();
  bool _busyRemoteImport = false;

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
              subtitle: '做一款独一无二的app，把他放进你的口袋',
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
                    busy: _busyRemoteImport,
                    enabled: !_busyRemoteImport,
                    onSubmit: _importRemoteArchive,
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
    final source = _normalizeRemoteBundleSource(_remoteController.text);
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.remoteBundleRequired)),
      );
      return;
    }
    if (_remoteController.text.trim() != source) {
      _remoteController.text = source;
      _remoteController.selection = TextSelection.fromPosition(
        TextPosition(offset: source.length),
      );
    }

    setState(() => _busyRemoteImport = true);
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
        setState(() => _busyRemoteImport = false);
      }
    }
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: WorkbenchPalette.coralInk,
              ),
              onPressed: enabled
                  ? () {
                      controller.text = kRemoteOfficialDemoBundleDisplayName;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: kRemoteOfficialDemoBundleDisplayName.length,
                        ),
                      );
                    }
                  : null,
              child: Text(
                l10n.importRemoteFillDemoLabel(
                  kRemoteOfficialDemoBundleDisplayName,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: WorkbenchPalette.coralInk,
                ),
              ),
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
