import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/installed_app.dart';
import '../services/app_environment.dart';
import 'import_screen.dart';
import 'permission_screen.dart';
import 'runtime_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: environment.library,
      builder: (context, _) {
        final apps = environment.library.apps;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.appTitle),
            actions: <Widget>[
              IconButton(
                tooltip: context.l10n.importTooltip,
                icon: const Icon(Icons.add_box_outlined),
                onPressed: () => _openImport(context),
              ),
            ],
          ),
          body: SafeArea(
            child: apps.isEmpty
                ? _EmptyLibrary(onImport: () => _openImport(context))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return _AppTile(
                        app: app,
                        onOpen: () => _openApp(context, app),
                        onPermissions: () => _openPermissions(context, app),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: apps.length,
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
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                context.l10n.emptyLibraryTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.emptyLibraryBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.importSampleBundle),
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
    required this.onOpen,
    required this.onPermissions,
  });

  final InstalledApp app;
  final VoidCallback onOpen;
  final VoidCallback onPermissions;

  @override
  Widget build(BuildContext context) {
    final manifest = app.manifest;
    final l10n = context.l10n;
    final lastUsed = app.lastUsedAt == null
        ? l10n.neverOpened
        : l10n.lastUsed(_formatDate(app.lastUsedAt!.toLocal()));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  manifest.icon,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      manifest.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manifest.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastUsed,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.permissionsTooltip,
                icon: const Icon(Icons.shield_outlined),
                onPressed: onPermissions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
