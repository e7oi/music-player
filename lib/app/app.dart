import 'package:flutter/material.dart';
import 'package:tuneshell/features/library/library_page.dart';
import 'package:tuneshell/features/library/player_bar.dart';
import 'package:tuneshell/features/shell/home_shell.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

class TuneShellApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // FR-008.2: follows the system (the default mode); the setting comes with
    // MPL-048.
    theme: TsTheme.light(),
    darkTheme: TsTheme.dark(),
    home: const HomeShell(tracks: LibraryPage(), playerBar: PlayerBar()),
  );
}
