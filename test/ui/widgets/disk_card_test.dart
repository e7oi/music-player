import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/disk_card.dart';

import 'support.dart';

void main() {
  DiskCard card(
    DiskStatus status, {
    VoidCallback? onStop,
    VoidCallback? onRenew,
  }) => DiskCard(
    name: 'SSD',
    summary: '1 To · 2 dossiers · 812 pistes',
    status: status,
    statusLabel: switch (status) {
      DiskStatus.connected || DiskStatus.scanning => 'Connecté',
      DiskStatus.absent => 'Non connecté',
      DiskStatus.needsAccess => 'Accès à renouveler',
    },
    scanLabel: 'Parcours du disque : 1 240 / 3 100 fichiers',
    scanProgress: 0.4,
    stopLabel: 'Arrêter',
    onStop: onStop,
    explanation: "L'autorisation n'est plus valable.",
    renewLabel: "Renouveler l'accès",
    onRenew: onRenew,
    children: const [Text('folder row')],
  );

  for (final dark in themes) {
    group('in ${themeName(dark: dark)}', () {
      /// @verifies FR-010.3
      testWidgets('connected: name, summary and a positive chip', (
        tester,
      ) async {
        await pumpUi(tester, card(DiskStatus.connected), dark: dark);

        expect(find.text('SSD'), findsOneWidget);
        expect(find.text('1 To · 2 dossiers · 812 pistes'), findsOneWidget);
        expect(find.text('Connecté'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text("Renouveler l'accès"), findsNothing);
        expect(find.text('folder row'), findsOneWidget);
      });

      testWidgets('scanning: progress and a stop action', (tester) async {
        var stopped = 0;
        await pumpUi(
          tester,
          card(DiskStatus.scanning, onStop: () => stopped++),
          dark: dark,
        );

        expect(
          find.text('Parcours du disque : 1 240 / 3 100 fichiers'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0.4,
        );
        await tester.tap(find.text('Arrêter'));
        expect(stopped, 1);
      });

      testWidgets('absent: neutral, unplugged icon, no action', (tester) async {
        await pumpUi(tester, card(DiskStatus.absent), dark: dark);

        expect(find.text('Non connecté'), findsOneWidget);
        expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.text('Arrêter'), findsNothing);
      });

      testWidgets('needs access: amber chip, explanation, renew button', (
        tester,
      ) async {
        var renewed = 0;
        await pumpUi(
          tester,
          card(DiskStatus.needsAccess, onRenew: () => renewed++),
          dark: dark,
        );

        expect(find.text('Accès à renouveler'), findsOneWidget);
        expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
        expect(find.text("L'autorisation n'est plus valable."), findsOneWidget);
        await tester.tap(find.text("Renouveler l'accès"));
        expect(renewed, 1);
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(TsSize.touchTarget),
        );
      });
    });
  }

  /// @verifies FR-010.6
  testWidgets('TalkBack reads name, summary and state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpUi(tester, card(DiskStatus.absent));

    expect(
      tester.getSemantics(find.byType(DiskCard)).label,
      contains('SSD, 1 To · 2 dossiers · 812 pistes, Non connecté'),
    );
    handle.dispose();
  });

  testWidgets('every state tells itself in words, not by colour only', (
    tester,
  ) async {
    for (final status in DiskStatus.values) {
      await pumpUi(tester, card(status));

      final labels = {
        DiskStatus.connected: 'Connecté',
        DiskStatus.scanning: 'Connecté',
        DiskStatus.absent: 'Non connecté',
        DiskStatus.needsAccess: 'Accès à renouveler',
      };
      expect(find.text(labels[status]!), findsOneWidget, reason: '$status');
    }
  });
}
