import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/queue_sheet.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const ssd = DiskId('ssd');

LibraryTrack lib(String name, {DiskId disk = internalDisk, int seconds = 60}) =>
    LibraryTrack(
      id: name.hashCode,
      disk: disk,
      info: TrackInfo(
        relativePath: '$name.flac',
        size: 1,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
        title: name,
        artist: 'Artist $name',
        duration: Duration(seconds: seconds),
      ),
    );

ProviderContainer? _container;

void flow(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    _container?.dispose();
    _container = null;
    await tester.pump(const Duration(seconds: 1));
  });
}

void main() {
  late FakeAudioEngine engine;
  late PlayerController player;

  Future<void> pump(
    WidgetTester tester,
    List<LibraryTrack> tracks, {
    int current = 0,
    Set<DiskId> available = const {internalDisk, ssd},
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    engine = FakeAudioEngine();
    player = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents(available),
    );
    await player.start();
    addTearDown(player.dispose);
    await player.setQueue([
      for (final t in tracks) t.track,
    ], startIndex: current);
    await player.play();
    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWithValue(player),
        trackIndexProvider.overrideWithValue({
          for (final t in tracks) t.track: t,
        }),
        playerDisksProvider.overrideWithValue(const [
          Disk.internal,
          Disk(
            id: ssd,
            label: 'T7 Shield',
            kind: DiskKind.removable,
            markIndex: 0,
          ),
        ]),
        artworkDirectoryProvider.overrideWith((ref) => '/artwork'),
      ],
    );
    _container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showQueueSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final a = lib('Alpha');
  final b = lib('Bravo');
  final c = lib('Charlie');
  final d = lib('Delta');
  final e = lib('Echo');

  /// @verifies FR-018.2
  /// @verifies FR-018.3
  /// @verifies FR-018.4
  group('content', () {
    flow('header, current track and upcoming ones', (tester) async {
      await pump(tester, [a, b, c]);

      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('3 tracks · 3:00'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('1:00'), findsNWidgets(3));
    });

    flow('says shuffled when the shuffle is on', (tester) async {
      await pump(tester, [a, b, c]);

      await player.setShuffle(enabled: true);
      await tester.pumpAndSettle();

      expect(find.text('3 tracks · 3:00 · shuffled'), findsOneWidget);
    });

    flow('past tracks are not listed', (tester) async {
      await pump(tester, [a, b, c], current: 1);

      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    flow('the last track has no up-next section', (tester) async {
      await pump(tester, [a, b], current: 1);

      expect(find.text('UP NEXT'), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Clear upcoming'),
            )
            .onPressed,
        isNull,
      );
    });

    /// @verifies FR-018.7
    flow('an absent disk greys the row and says it will be skipped', (
      tester,
    ) async {
      await pump(
        tester,
        [a, lib('Remote', disk: ssd), c],
        available: {internalDisk},
      );

      expect(
        find.text('Artist Remote · not connected, will be skipped'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);
    });
  });

  /// @verifies FR-018.6
  flow('touching a row of the upcoming tracks plays it', (tester) async {
    await pump(tester, [a, b, c, d]);

    await tester.tap(find.text('Charlie'));
    await tester.pump();
    await tester.pump();

    expect(player.state.currentIndex, 2);
    expect(player.state.queue, [a.track, b.track, c.track, d.track]);
  });

  /// @verifies FR-018.9
  flow('Clear upcoming keeps the current track', (tester) async {
    await pump(tester, [a, b, c], current: 1);

    await tester.tap(find.text('Clear upcoming'));
    await tester.pumpAndSettle();

    expect(player.state.queue, [a.track, b.track]);
    expect(find.text('Charlie'), findsNothing);
    expect(find.text('2 tracks · 2:00'), findsOneWidget);
  });

  /// @verifies FR-018.8
  group('removing', () {
    flow('a swipe removes the track and says so', (tester) async {
      await pump(tester, [a, b, c, d]);

      await tester.drag(find.text('Charlie'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(player.state.queue, [a.track, b.track, d.track]);
      expect(find.text('Charlie removed from the queue'), findsOneWidget);
      expect(find.text('Charlie'), findsNothing);
      expect(player.state.currentTrack, a.track);
    });

    flow('TalkBack has a Remove from queue action', (tester) async {
      await pump(tester, [a, b, c]);

      final labels = [
        for (final semantics in tester.widgetList<Semantics>(
          find.byType(Semantics),
        ))
          ...?semantics.properties.customSemanticsActions?.keys.map(
            (action) => action.label,
          ),
      ];

      expect(labels.where((l) => l == 'Remove from queue'), hasLength(2));
      expect(labels, contains('Move up'));
    });

    flow('the current track cannot be swiped away', (tester) async {
      await pump(tester, [a, b]);

      await tester.drag(find.text('Alpha'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(player.state.queue, [a.track, b.track]);
    });
  });

  /// @verifies FR-018.5
  group('reordering', () {
    flow('the handle carries the label Move {title}', (tester) async {
      await pump(tester, [a, b, c]);
      final handle = tester.ensureSemantics();

      expect(find.bySemanticsLabel('Move Bravo'), findsOneWidget);
      expect(find.bySemanticsLabel('Move Alpha'), findsNothing);
      handle.dispose();
    });

    flow('dragging a handle moves the track inside the upcoming ones', (
      tester,
    ) async {
      await pump(tester, [a, b, c, d, e]);

      final handle = find.bySemanticsLabel('Move Echo');
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, -TsSize.trackRow));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -2 * TsSize.trackRow));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final order = player.state.queue.map((t) => t.relativePath).toList();
      expect(order.first, 'Alpha.flac');
      expect(order.indexOf('Echo.flac'), lessThan(3));
      expect(order, hasLength(5));
      expect(player.state.currentIndex, 0);
    });
  });

  /// @verifies FR-018.10
  flow('a queue of 7 500 tracks opens and scrolls', (tester) async {
    final tracks = [
      for (var i = 0; i < 7500; i++) lib('T${i.toString().padLeft(4, '0')}'),
    ];
    await pump(tester, tracks);

    expect(find.text('7,500 tracks · 125:00:00'), findsOneWidget);
    await tester.fling(find.text('T0001'), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  /// @verifies FR-018.11
  flow('lays out at 200 % without overflow', (tester) async {
    await pump(tester, [a, b, c], textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Charlie'), findsOneWidget);
  });
}
