import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuneshell/features/shell/coming_soon_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/demo/component_gallery.dart';

/// The Settings view. Its content comes with MPL-048; meanwhile debug and
/// profile builds offer the component gallery (FR-010.7, ADR-010).
class SettingsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!(kDebugMode || kProfileMode)) {
      return ComingSoonPage(title: l10n.navSettings);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.widgets_rounded),
            title: Text(l10n.demoGallery),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const ComponentGallery()),
            ),
          ),
        ],
      ),
    );
  }
}
