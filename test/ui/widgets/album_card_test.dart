import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/album_card.dart';
import 'package:tuneshell/ui/widgets/artist_tile.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';

import 'support.dart';

void main() {
  /// @verifies FR-020.2
  /// @verifies FR-020.5
  for (final dark in themes) {
    group('AlbumCard in ${themeName(dark: dark)}', () {
      testWidgets('shows cover, title, marks and subtitle', (tester) async {
        var taps = 0;
        var presses = 0;
        await pumpUi(
          tester,
          Center(
            child: SizedBox(
              width: 180,
              child: AlbumCard(
                title: 'Littoral',
                subtitle: 'Les Brumes · 2019',
                size: 180,
                marks: const [
                  SourceMark(
                    shape: SourceMarkShape.circle,
                    color: Color(0xFF888888),
                  ),
                ],
                onTap: () => taps++,
                onLongPress: () => presses++,
              ),
            ),
          ),
          dark: dark,
        );

        expect(find.text('Littoral'), findsOneWidget);
        expect(find.text('Les Brumes · 2019'), findsOneWidget);
        expect(find.byType(SourceMark), findsOneWidget);
        expect(tester.getSize(find.byType(ArtworkTile)), const Size(180, 180));
        await tester.tap(find.text('Littoral'));
        await tester.longPress(find.text('Littoral'));
        expect(taps, 1);
        expect(presses, 1);
      });

      testWidgets('unavailable: plug icon, faded cover, still touchable', (
        tester,
      ) async {
        var taps = 0;
        await pumpUi(
          tester,
          Center(
            child: SizedBox(
              width: 180,
              child: AlbumCard(
                title: 'Champs',
                subtitle: 'Nodal',
                size: 180,
                unavailable: true,
                semanticsLabel: 'Champs, Nodal, unavailable',
                onTap: () => taps++,
              ),
            ),
          ),
          dark: dark,
        );

        expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);
        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(ArtworkTile),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacity.opacity, 0.35);
        await tester.tap(find.text('Champs'));
        expect(taps, 1);
        expect(
          find.bySemanticsLabel('Champs, Nodal, unavailable'),
          findsOneWidget,
        );
      });
    });
  }

  /// @verifies FR-021.2
  group('ArtistTile', () {
    testWidgets('an avatar with the initial, name and summary', (tester) async {
      await pumpUi(
        tester,
        const Column(
          children: [
            ArtistTile(
              name: 'Clara Vey',
              subtitle: '3 albums · 31 tracks',
              initial: 'C',
            ),
          ],
        ),
      );

      expect(find.text('C'), findsOneWidget);
      expect(find.text('Clara Vey'), findsOneWidget);
      expect(find.text('3 albums · 31 tracks'), findsOneWidget);
      expect(tester.getSize(find.byType(ArtistTile)).height, TsSize.trackRow);
    });

    testWidgets('tints alternate and a lost source greys the avatar', (
      tester,
    ) async {
      await pumpUi(
        tester,
        const Column(
          children: [
            ArtistAvatar(initial: 'A'),
            ArtistAvatar(initial: 'B', tint: 1),
            ArtistAvatar(initial: 'C', unavailable: true),
          ],
        ),
      );
      final scheme = Theme.of(tester.element(find.text('A'))).colorScheme;

      Color colorOf(String initial) =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: find.text(initial),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;

      expect(colorOf('A'), scheme.primaryContainer);
      expect(colorOf('B'), scheme.secondaryContainer);
      expect(colorOf('C'), scheme.surfaceContainerHigh);
    });

    testWidgets('grows instead of cutting at 200 % text', (tester) async {
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TsTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(412, 915),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Column(
                children: [
                  ArtistTile(
                    name: 'Clara Vey',
                    subtitle: '3 albums · 31 tracks',
                    initial: 'C',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(ArtistTile)).height,
        greaterThan(TsSize.trackRow),
      );
    });
  });
}
