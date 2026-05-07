import 'package:flutter/material.dart';

import '../l10n/workbench_localizations.dart';
import '../models/app_manifest.dart';
import '../services/app_environment.dart';

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
            appBar: AppBar(title: Text(l10n.permissionsTitle)),
            body: Center(child: Text(l10n.appNotFound)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appPermissions(app.manifest.name))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.permissionsIntro,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final capability in app.manifest.permissions)
                  Card(
                    child: SwitchListTile(
                      value: app.grantedPermissions[capability] ?? false,
                      title: Text(l10n.capabilityTitle(capability)),
                      subtitle: Text(l10n.capabilityDescription(capability)),
                      secondary: Icon(_icon(capability)),
                      onChanged: (value) => environment.library.setPermission(
                        appId,
                        capability,
                        value,
                      ),
                    ),
                  ),
                if (app.manifest.permissions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noRuntimePermissions),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _icon(AppCapability capability) {
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
}
