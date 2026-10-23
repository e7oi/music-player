import 'package:flutter/material.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// A main view whose content comes with a later ticket (FR-009.2).
class ComingSoonPage extends StatelessWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Text(
          AppLocalizations.of(context).comingSoon,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
}
