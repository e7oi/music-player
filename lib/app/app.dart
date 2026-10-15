import 'package:flutter/material.dart';
import 'package:musicplayer/features/home/home_page.dart';
import 'package:musicplayer/l10n/generated/app_localizations.dart';

class MusicPlayerApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.teal,
      brightness: Brightness.dark,
    ),
    home: const HomePage(),
  );
}
