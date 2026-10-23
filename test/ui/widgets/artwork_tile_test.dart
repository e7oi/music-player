import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';

import 'support.dart';

/// A 1 x 1 PNG, enough for a decoded image.
final _png = MemoryImage(
  Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x50,
    0x0F,
    0x00,
    0x04,
    0x85,
    0x01,
    0x80,
    0x84,
    0xA9,
    0x8C,
    0x21,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]),
);

void main() {
  /// @verifies FR-010.3
  for (final dark in themes) {
    group('in ${themeName(dark: dark)}', () {
      testWidgets('no cover: a neutral tile with a note', (tester) async {
        await pumpUi(tester, const ArtworkTile(), dark: dark);

        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('the four sizes of the design', (tester) async {
        for (final size in [
          TsSize.coverSmall,
          TsSize.coverPanel,
          TsSize.coverDetail,
          TsSize.coverPlayer,
        ]) {
          await pumpUi(tester, ArtworkTile(size: size), dark: dark);

          expect(
            tester.getSize(find.byType(ArtworkTile)),
            Size.square(size),
            reason: '$size',
          );
        }
      });

      testWidgets('a cover is shown when there is one', (tester) async {
        await pumpUi(tester, ArtworkTile(image: _png), dark: dark);

        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('unavailable: faded to 35 %', (tester) async {
        await pumpUi(tester, const ArtworkTile(unavailable: true), dark: dark);

        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.35);
      });

      testWidgets('available: fully opaque', (tester) async {
        await pumpUi(tester, const ArtworkTile(), dark: dark);

        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      });
    });
  }

  testWidgets('a cover that cannot load falls back to the tile', (
    tester,
  ) async {
    await pumpUi(
      tester,
      ArtworkTile(image: MemoryImage(Uint8List.fromList(const [1, 2, 3]))),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });
}
