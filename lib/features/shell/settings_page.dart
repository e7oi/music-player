import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/features/shell/coming_soon_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/demo/component_gallery.dart';

/// The Settings view. Its content comes with MPL-048; meanwhile debug and
/// profile builds offer the component gallery (FR-010.7, ADR-010).
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              MaterialPageRoute(
                builder: (_) => ComponentGallery(
                  // FR-010.5: the handle keeps the Back gesture out.
                  onHandleRect: (rect) {
                    final ratio = View.of(context).devicePixelRatio;
                    unawaited(
                      ref.read(gestureExclusionProvider).setRects([
                        if (rect != null)
                          Rect.fromLTRB(
                            rect.left * ratio,
                            rect.top * ratio,
                            rect.right * ratio,
                            rect.bottom * ratio,
                          ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
