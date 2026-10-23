import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/features/shell/settings_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

void main() {
  /// @verifies FR-010.7 the gallery is offered in debug and profile builds.
  testWidgets('offers the component gallery, which opens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const SettingsPage(),
        ),
      ),
    );

    expect(find.text('Réglages'), findsOneWidget);
    await tester.tap(find.text('Galerie de composants'));
    await tester.pumpAndSettle();

    expect(find.text('Component gallery'), findsOneWidget);
  });
}
