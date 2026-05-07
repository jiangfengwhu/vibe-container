import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../l10n/workbench_localizations.dart';
import '../services/app_environment.dart';
import '../services/bundle_manager.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late Future<List<SampleBundle>> _samples;
  String? _busySampleId;

  @override
  void initState() {
    super.initState();
    _samples = widget.environment.bundleManager.listSamples();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.importScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.importGeneratedTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.importGeneratedBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _busySampleId == null ? _pickArchive : null,
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(context.l10n.chooseIprodZip),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.builtInSamples,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<SampleBundle>>(
              future: _samples,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final samples = snapshot.data ?? const <SampleBundle>[];
                return Column(
                  children: <Widget>[
                    for (final sample in samples) ...<Widget>[
                      _SampleImportCard(
                        sample: sample,
                        busySampleId: _busySampleId,
                        isInstalled:
                            widget.environment.library.findById(
                              'local.${sample.id}',
                            ) !=
                            null,
                        onImport: () => _import(sample),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickArchive() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['zip', 'iprod'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() => _busySampleId = '__archive__');
    try {
      final installed = await widget.environment.bundleManager.importArchive(
        path,
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

class _SampleImportCard extends StatelessWidget {
  const _SampleImportCard({
    required this.sample,
    required this.busySampleId,
    required this.isInstalled,
    required this.onImport,
  });

  final SampleBundle sample;
  final String? busySampleId;
  final bool isInstalled;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              sample.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              sample.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: busySampleId == null ? onImport : null,
              icon: busySampleId == sample.id
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isInstalled ? Icons.refresh : Icons.download_outlined),
              label: Text(
                isInstalled ? context.l10n.reimport : context.l10n.import,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
