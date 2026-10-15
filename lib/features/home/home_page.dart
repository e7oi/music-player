import 'package:flutter/material.dart';
import 'package:musicplayer/l10n/generated/app_localizations.dart';

/// Placeholder until the screens of MPL-016 exist.
class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.homePlaceholder)),
    );
  }
}
