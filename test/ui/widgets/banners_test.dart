import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

import 'support.dart';

void main() {
  /// @verifies FR-010.3
  group('StatusBanner', () {
    for (final dark in themes) {
      testWidgets('the three kinds in ${themeName(dark: dark)}', (
        tester,
      ) async {
        await pumpUi(
          tester,
          const Column(
            children: [
              StatusBanner(kind: BannerKind.error, message: 'error'),
              StatusBanner(kind: BannerKind.warning, message: 'warning'),
              StatusBanner(kind: BannerKind.info, message: 'info'),
            ],
          ),
          dark: dark,
        );
        final scheme = Theme.of(tester.element(find.text('error'))).colorScheme;

        final colors = [
          for (final m in ['error', 'warning', 'info'])
            ((tester
                        .widget<DecoratedBox>(
                          find
                              .ancestor(
                                of: find.text(m),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration)
                    as BoxDecoration)
                .color,
        ];
        expect(colors, [
          scheme.errorContainer,
          scheme.tertiaryContainer,
          scheme.surfaceContainerHigh,
        ]);
        // Never the colour alone: each kind has its icon.
        expect(find.byIcon(Icons.error_rounded), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      });
    }

    testWidgets('action and close are touchable, 48 dp, and called', (
      tester,
    ) async {
      var acted = 0;
      var closed = 0;
      await pumpUi(
        tester,
        StatusBanner(
          kind: BannerKind.warning,
          message: '12 pistes ignorées : SSD absent',
          actionLabel: 'Voir',
          onAction: () => acted++,
          dismissTooltip: 'Fermer',
          onDismiss: () => closed++,
        ),
      );

      await tester.tap(find.text('Voir'));
      await tester.tap(find.byTooltip('Fermer'));

      expect((acted, closed), (1, 1));
      expect(
        tester.getSize(find.byTooltip('Fermer')).shortestSide,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Voir')).height,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
    });

    testWidgets('at least 56 dp high, even for one short line', (tester) async {
      await pumpUi(
        tester,
        const StatusBanner(kind: BannerKind.info, message: 'ok'),
      );

      expect(
        tester.getSize(find.byType(StatusBanner)).height,
        greaterThanOrEqualTo(TsSize.bannerMin),
      );
    });

    /// @verifies FR-010.6
    testWidgets('is a live region, announced once', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(
        tester,
        const StatusBanner(kind: BannerKind.error, message: 'Accès refusé'),
      );

      final node = tester.getSemantics(
        find
            .descendant(
              of: find.byType(StatusBanner),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    /// @verifies BR-007 the banner is in the flow: it pushes the list down.
    for (final size in [const Size(412, 915), const Size(915, 412)]) {
      testWidgets('never covers the first track at ${size.width.toInt()} dp', (
        tester,
      ) async {
        var taps = 0;
        await pumpUi(
          tester,
          Column(
            children: [
              const StatusBanner(
                kind: BannerKind.warning,
                message: '12 pistes ignorées : SSD absent',
                actionLabel: 'Voir',
              ),
              Expanded(
                child: ListView(
                  children: [TrackTile(title: 'Première', onTap: () => taps++)],
                ),
              ),
            ],
          ),
          size: size,
        );

        final banner = tester.getRect(find.byType(StatusBanner));
        final first = tester.getRect(find.byType(TrackTile));
        expect(first.top, greaterThanOrEqualTo(banner.bottom));
        await tester.tap(find.text('Première'));
        expect(taps, 1);
      });
    }
  });

  group('ProgressBanner', () {
    testWidgets('determinate: the bar follows the value', (tester) async {
      await pumpUi(
        tester,
        const ProgressBanner(
          label: 'Lecture des étiquettes : 340 / 2 600',
          value: 0.13,
        ),
      );

      expect(find.text('Lecture des étiquettes : 340 / 2 600'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.13);
    });

    testWidgets('indeterminate when there is no value', (tester) async {
      await pumpUi(
        tester,
        const ProgressBanner(
          label: 'Recherche des fichiers audio… 1 120 trouvés',
        ),
      );

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
      await tester.pump(const Duration(milliseconds: 400));
    });

    /// @verifies FR-010.6
    testWidgets('TalkBack reads the label, not the steps', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(
        tester,
        const ProgressBanner(label: 'Lecture des étiquettes', value: 0.5),
      );

      final node = tester.getSemantics(
        find
            .descendant(
              of: find.byType(ProgressBanner),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(node.label, 'Lecture des étiquettes');
      expect(node.value, isEmpty);
      handle.dispose();
    });
  });
}
