import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';
import 'package:tuneshell/ui/widgets/mini_player.dart';

import 'support.dart';

Widget player({
  bool playing = true,
  bool sourceLost = false,
  String title = 'Dawn on the river',
  String subtitle = 'The Mists',
  List<String>? log,
}) => Column(
  children: [
    MiniPlayer(
      title: title,
      subtitle: subtitle,
      playing: playing,
      sourceLost: sourceLost,
      progress: const MiniPlayerProgress(value: 0.38),
      openLabel: 'Open the player',
      previousLabel: 'Previous',
      playLabel: 'Play',
      pauseLabel: 'Pause',
      nextLabel: 'Next',
      onOpen: () => log?.add('open'),
      onPrevious: () => log?.add('previous'),
      onPlayPause: () => log?.add('toggle'),
      onNext: () => log?.add('next'),
    ),
  ],
);

void main() {
  /// @verifies FR-016.3
  /// @verifies FR-016.4
  /// @verifies FR-016.5
  for (final dark in themes) {
    group('MiniPlayer in ${themeName(dark: dark)}', () {
      testWidgets('shows the track and calls the commands', (tester) async {
        final log = <String>[];
        await pumpUi(tester, player(log: log), dark: dark);

        expect(find.text('Dawn on the river'), findsOneWidget);
        expect(find.text('The Mists'), findsOneWidget);
        await tester.tap(find.byTooltip('Previous'));
        await tester.tap(find.byTooltip('Pause'));
        await tester.tap(find.byTooltip('Next'));
        await tester.tap(find.text('Dawn on the river'));

        expect(log, ['previous', 'toggle', 'next', 'open']);
      });

      testWidgets('the button says Play when paused', (tester) async {
        await pumpUi(tester, player(playing: false), dark: dark);

        expect(find.byTooltip('Play'), findsOneWidget);
        expect(find.byTooltip('Pause'), findsNothing);
      });

      testWidgets('a drag up opens the player, a drag down does not', (
        tester,
      ) async {
        final log = <String>[];
        await pumpUi(tester, player(log: log), dark: dark);

        await tester.fling(
          find.text('Dawn on the river'),
          const Offset(0, 80),
          800,
        );
        expect(log, isEmpty);
        await tester.fling(
          find.text('Dawn on the river'),
          const Offset(0, -80),
          800,
        );

        expect(log, ['open']);
      });

      testWidgets('is 64 dp high with 48 dp buttons', (tester) async {
        await pumpUi(tester, player(), dark: dark);

        expect(
          tester.getSize(find.byType(MiniPlayer)).height,
          TsSize.miniPlayer + 2 * TsSpace.s,
        );
        for (final tip in ['Previous', 'Pause', 'Next']) {
          final size = tester.getSize(find.byTooltip(tip));
          expect(size.width, greaterThanOrEqualTo(TsSize.touchTarget));
          expect(size.height, greaterThanOrEqualTo(TsSize.touchTarget));
        }
      });
    });
  }

  /// @verifies FR-016.7
  group('source lost', () {
    testWidgets('says why in text with an icon, and fades the cover', (
      tester,
    ) async {
      await pumpUi(
        tester,
        player(
          playing: false,
          sourceLost: true,
          subtitle: 'Stopped: T7 Shield unplugged',
        ),
      );

      expect(find.text('Stopped: T7 Shield unplugged'), findsOneWidget);
      expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);
      final tile = find.byType(ArtworkTile);
      expect(
        find.descendant(of: tile, matching: find.byType(Opacity)),
        findsOneWidget,
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(of: tile, matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.5);
    });
  });

  /// @verifies FR-016.2
  group('large text', () {
    testWidgets('grows instead of cutting at 200 %', (tester) async {
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TsTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(body: player()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MiniPlayer)).height,
        greaterThanOrEqualTo(TsSize.miniPlayer + 2 * TsSpace.s),
      );
    });
  });

  /// @verifies FR-016.6
  testWidgets('the progress bar follows its value', (tester) async {
    await pumpUi(tester, const MiniPlayerProgress(value: 0.25));

    final fraction = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fraction.widthFactor, 0.25);
  });
}
