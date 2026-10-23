import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

import 'support.dart';

void main() {
  TrackTile tile({
    TrackTileState state = TrackTileState.normal,
    VoidCallback? onTap,
    Widget? mark,
  }) => TrackTile(
    title: 'Aube sur le fleuve',
    artist: 'Les Brumes',
    duration: '4:18',
    state: state,
    mark: mark,
    unavailableLabel: 'Nodal · non connecté',
    unreadableLabel: 'Fichier illisible',
    playingLabel: 'en lecture',
    onTap: onTap,
  );

  for (final dark in themes) {
    group('in ${themeName(dark: dark)}', () {
      /// @verifies FR-010.3
      testWidgets('normal: title, artist, duration, 64 dp high', (
        tester,
      ) async {
        await pumpUi(tester, tile(), dark: dark);

        expect(find.text('Aube sur le fleuve'), findsOneWidget);
        expect(find.text('Les Brumes'), findsOneWidget);
        expect(find.text('4:18'), findsOneWidget);
        expect(tester.getSize(find.byType(TrackTile)).height, TsSize.trackRow);
      });

      testWidgets('playing: tinted row, equaliser, primary title', (
        tester,
      ) async {
        await pumpUi(tester, tile(state: TrackTileState.playing), dark: dark);

        final scheme = Theme.of(tester.element(find.byType(TrackTile)));
        expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
        final title = tester.widget<Text>(find.text('Aube sur le fleuve'));
        expect(title.style?.color, scheme.colorScheme.primary);
        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(TrackTile),
            matching: find.byType(Material),
          ),
        );
        expect(
          material.color,
          TsColors.of(tester.element(find.byType(TrackTile))).nowPlayingRow,
        );
      });

      testWidgets('no artwork: the neutral tile', (tester) async {
        await pumpUi(tester, tile(state: TrackTileState.noArtwork), dark: dark);

        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      });

      testWidgets('unavailable: greyed, unplugged icon and the reason', (
        tester,
      ) async {
        await pumpUi(
          tester,
          tile(state: TrackTileState.unavailable),
          dark: dark,
        );

        expect(find.text('Nodal · non connecté'), findsOneWidget);
        expect(find.text('Les Brumes'), findsNothing);
        expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);
        final context = tester.element(find.byType(TrackTile));
        final title = tester.widget<Text>(find.text('Aube sur le fleuve'));
        expect(title.style?.color, TsColors.of(context).unavailable);
        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.35);
      });

      testWidgets('unreadable: error icon and text, not colour alone', (
        tester,
      ) async {
        await pumpUi(
          tester,
          tile(state: TrackTileState.unreadable),
          dark: dark,
        );

        expect(find.text('Fichier illisible'), findsOneWidget);
        expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      });

      testWidgets('loading: a skeleton with no text', (tester) async {
        await pumpUi(tester, tile(state: TrackTileState.loading), dark: dark);

        expect(find.byType(Text), findsNothing);
        expect(tester.getSize(find.byType(TrackTile)).height, TsSize.trackRow);
      });
    });
  }

  /// @verifies FR-010.6
  group('touch and accessibility', () {
    testWidgets('the whole row is the touch area, at least 48 dp', (
      tester,
    ) async {
      var taps = 0;
      await pumpUi(tester, tile(onTap: () => taps++));

      await tester.tapAt(
        tester.getTopLeft(find.byType(TrackTile)) + const Offset(2, 2),
      );
      await tester.tapAt(
        tester.getBottomRight(find.byType(TrackTile)) - const Offset(2, 2),
      );

      expect(taps, 2);
      expect(
        tester.getSize(find.byType(TrackTile)).height,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
    });

    testWidgets('an unavailable track stays touchable', (tester) async {
      var taps = 0;
      await pumpUi(
        tester,
        tile(state: TrackTileState.unavailable, onTap: () => taps++),
      );

      await tester.tap(find.byType(TrackTile));

      expect(taps, 1);
    });

    testWidgets('a long press is forwarded', (tester) async {
      var pressed = false;
      await pumpUi(
        tester,
        TrackTile(title: 'T', onLongPress: () => pressed = true),
      );

      await tester.longPress(find.byType(TrackTile));

      expect(pressed, isTrue);
    });

    testWidgets('TalkBack reads one label: title, artist, duration', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpUi(tester, tile(onTap: () {}));

      expect(
        tester.getSemantics(find.byType(TrackTile)),
        matchesSemantics(
          label: 'Aube sur le fleuve, Les Brumes, 4:18',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the caller can name the state and the source', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(
        tester,
        TrackTile(
          title: 'Auroral',
          semanticsLabel:
              'Auroral, Nodal, 5:03, indisponible : SSD non connecté',
          onTap: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(TrackTile)).label,
        contains('SSD non connecté'),
      );
      handle.dispose();
    });
  });

  /// @verifies FR-010.3
  testWidgets('the source mark comes before the artist', (tester) async {
    await pumpUi(tester, tile(mark: SourceMark.disk(0, TsColors.light)));

    final mark = tester.getRect(find.byType(SourceMark));
    final artist = tester.getRect(find.text('Les Brumes'));
    expect(mark.right, lessThanOrEqualTo(artist.left));
    expect((mark.center.dy - artist.center.dy).abs(), lessThan(8));
  });

  /// @verifies FR-010.6
  group('TalkBack says the state in words', () {
    for (final (state, said) in [
      (
        TrackTileState.playing,
        'Aube sur le fleuve, Les Brumes, 4:18, en lecture',
      ),
      (
        TrackTileState.unavailable,
        'Aube sur le fleuve, Les Brumes, 4:18, Nodal · non connecté',
      ),
      (
        TrackTileState.unreadable,
        'Aube sur le fleuve, Les Brumes, 4:18, Fichier illisible',
      ),
    ]) {
      testWidgets('${state.name}: $said', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpUi(tester, tile(state: state, onTap: () {}));

        expect(find.bySemanticsLabel(said), findsOneWidget);
        handle.dispose();
      });
    }
  });

  /// @verifies BR-007 rule 9
  group('text size', () {
    Future<void> pumpScaled(WidgetTester tester, double scale) async {
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TsTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: Column(
                children: [
                  TrackTile(
                    title:
                        'Un titre de piste assez long pour passer à la ligne',
                    artist: 'Les Brumes · un nom d artiste long aussi',
                    duration: '4:18',
                    state: TrackTileState.unavailable,
                    unavailableLabel: 'Nodal · non connecté à ce téléphone',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('fixed at 64 dp up to 1.3 times', (tester) async {
      await pumpScaled(tester, 1.3);

      expect(tester.getSize(find.byType(TrackTile)).height, TsSize.trackRow);
      expect(tester.takeException(), isNull);
    });

    testWidgets('grows at 200 % and never overflows', (tester) async {
      await pumpScaled(tester, 2);

      expect(
        tester.getSize(find.byType(TrackTile)).height,
        greaterThanOrEqualTo(TsSize.trackRow),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
