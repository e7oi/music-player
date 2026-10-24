import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/engine_issue.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/features/player/mini_player_bar.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/mini_player.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const ssd = DiskId('ssd');

LibraryTrack lib(
  String name, {
  DiskId disk = internalDisk,
  String? artist,
  String? album,
  int? seconds,
  int? number,
}) => LibraryTrack(
  id: name.hashCode,
  disk: disk,
  info: TrackInfo(
    relativePath: 'Music/$name.flac',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: name,
    artist: artist,
    album: album,
    trackNumber: number,
    duration: seconds == null ? null : Duration(seconds: seconds),
  ),
);

ProviderContainer? _container;

/// A test that ends by taking the widgets down and disposing the container
/// inside the test: the throttled position stream holds a timer that the
/// framework would otherwise find still pending.
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
  late FakeVolumeEvents volumes;
  late FakeTrackSourceOpener opener;
  late PlayerController player;

  final alpha = lib(
    'Alpha',
    artist: 'Mists',
    album: 'Shore',
    seconds: 60,
    number: 3,
  );
  final bravo = lib('Bravo', artist: 'Clara', seconds: 90);
  final charlie = lib('Charlie', seconds: 120);
  final remote = lib('Delta', disk: ssd, artist: 'Nodal', seconds: 30);
  final all = [alpha, bravo, charlie, remote];

  const disks = [
    Disk.internal,
    Disk(id: ssd, label: 'T7 Shield', kind: DiskKind.removable, markIndex: 0),
  ];

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    Set<DiskId> available = const {internalDisk, ssd},
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    engine = FakeAudioEngine();
    volumes = FakeVolumeEvents(available);
    opener = FakeTrackSourceOpener();
    player = PlayerController(engine: engine, opener: opener, volumes: volumes);
    await player.start();
    addTearDown(player.dispose);
    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWithValue(player),
        trackIndexProvider.overrideWithValue({for (final t in all) t.track: t}),
        playerDisksProvider.overrideWithValue(disks),
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
          home: const Scaffold(
            body: Column(
              children: [
                Expanded(child: SizedBox()),
                MiniPlayerBar(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> start(
    WidgetTester tester, {
    List<LibraryTrack>? tracks,
    int index = 0,
  }) async {
    await player.setQueue([
      for (final t in tracks ?? all) t.track,
    ], startIndex: index);
    await player.play();
    await tester.pump();
    await tester.pump();
  }

  Future<void> openPlayerPage(WidgetTester tester) async {
    await tester.tap(find.byType(MiniPlayer).first);
    await tester.pumpAndSettle();
  }

  /// @verifies FR-016.1
  /// @verifies FR-016.3
  group('mini player', () {
    flow('is absent while the queue is empty', (tester) async {
      await pump(tester);

      expect(find.byType(MiniPlayer), findsNothing);
    });

    flow('shows the current track with its source mark', (tester) async {
      await pump(tester);
      await start(tester);

      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Mists'), findsOneWidget);
      expect(find.byType(SourceMark), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    flow('a track without artist says Unknown artist', (tester) async {
      await pump(tester);
      await start(tester, index: 2);

      expect(find.text('Unknown artist'), findsOneWidget);
    });

    flow('next and play/pause drive the controller', (tester) async {
      await pump(tester);
      await start(tester);

      await tester.tap(find.byTooltip('Next track'));
      await tester.pump();
      expect(player.state.currentIndex, 1);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();

      expect(player.state.playing, isFalse);
      expect(find.byTooltip('Play'), findsOneWidget);
    });

    flow('is still there when playback stopped at the end', (tester) async {
      await pump(tester);
      await start(tester, tracks: [alpha]);

      engine.completeTrack();
      await tester.pump();
      await tester.pump();

      expect(player.state.status, PlayerStatus.stopped);
      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  });

  /// @verifies FR-016.7
  group('source lost', () {
    flow('names the disk and stays until the user plays again', (tester) async {
      await pump(tester);
      await start(tester, tracks: [remote, alpha]);

      volumes.emit(const VolumeEjecting(ssd));
      await tester.pump();
      await tester.pump();

      expect(find.text('Stopped: T7 Shield unplugged'), findsOneWidget);
      expect(find.byIcon(Icons.usb_off_rounded), findsOneWidget);

      volumes.emit(const VolumeMounted(ssd));
      await tester.pump();
      await tester.pump();
      expect(find.text('Stopped: T7 Shield unplugged'), findsOneWidget);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Stopped: T7 Shield unplugged'), findsNothing);
    });
  });

  /// @verifies FR-017.1
  group('player page', () {
    flow('opens from the mini player and closes by every way', (tester) async {
      await pump(tester);
      await start(tester);

      await openPlayerPage(tester);
      expect(find.byTooltip('Collapse'), findsOneWidget);
      await tester.tap(find.byTooltip('Collapse'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Collapse'), findsNothing);

      await openPlayerPage(tester);
      await tester.fling(
        find.text('Playing from'.toUpperCase()),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Collapse'), findsNothing);

      await openPlayerPage(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Collapse'), findsNothing);
    });

    flow('closes by itself when the queue empties', (tester) async {
      await pump(tester);
      await start(tester, tracks: [alpha]);
      await openPlayerPage(tester);

      await player.removeAt(0);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Collapse'), findsNothing);
      expect(find.byType(MiniPlayer), findsNothing);
    });

    /// @verifies FR-017.4
    flow('shows title, artist, album, source and details', (tester) async {
      await pump(tester);
      await start(tester);
      await openPlayerPage(tester);

      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Mists · Shore'), findsOneWidget);
      expect(find.text('Local · Track 3'), findsOneWidget);
      expect(find.byTooltip('Favorites (coming soon)'), findsOneWidget);
      final heart = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.favorite_border_rounded),
      );
      expect(heart.onPressed, isNull);
    });

    flow('a disk track names its disk', (tester) async {
      await pump(tester);
      await start(tester, index: 3);
      await openPlayerPage(tester);

      expect(find.text('T7 Shield · FLAC · Music'), findsOneWidget);
    });

    flow('says where the queue came from', (tester) async {
      final container = await pump(tester);
      container
          .read(queueOriginProvider.notifier)
          .set(QueueOrigin.tracksByTitle);
      await start(tester);
      await openPlayerPage(tester);

      expect(find.text('Playing from'.toUpperCase()), findsOneWidget);
      expect(find.text('Tracks · Title A→Z'), findsOneWidget);
    });

    /// @verifies FR-017.8
    flow('the up-next button counts the tracks and names the next', (
      tester,
    ) async {
      await pump(tester);
      await start(tester);
      await openPlayerPage(tester);

      expect(find.text('Up next · 3 tracks'), findsOneWidget);
      expect(find.text('Bravo · Clara'), findsOneWidget);

      await player.skipTo(3);
      await tester.pump();
      await tester.pump();
      expect(find.text('Up next · no track'), findsOneWidget);
    });

    /// @verifies FR-017.7
    flow('shuffle and repeat toggle with a state TalkBack can read', (
      tester,
    ) async {
      await pump(tester);
      await start(tester);
      await openPlayerPage(tester);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Shuffle'));
      await tester.pump();
      await tester.pump();
      expect(player.state.shuffle, isTrue);
      expect(
        tester.getSemantics(find.byTooltip('Shuffle')),
        matchesSemantics(
          label: 'Shuffle',
          value: 'on',
          hasToggledState: true,
          isToggled: true,
          isButton: true,
          hasTapAction: true,
        ),
      );

      for (final (mode, word) in [
        (RepeatMode.all, 'all tracks'),
        (RepeatMode.one, 'one track'),
        (RepeatMode.off, 'off'),
      ]) {
        await tester.tap(find.byTooltip('Repeat'));
        await tester.pump();
        await tester.pump();
        expect(player.state.repeat, mode);
        expect(tester.getSemantics(find.byTooltip('Repeat')).value, word);
      }
      handle.dispose();
    });

    /// @verifies FR-017.6
    flow('the position slider seeks on release and by 5 s steps', (
      tester,
    ) async {
      await pump(tester);
      await start(tester);
      engine
        ..emitDuration(const Duration(seconds: 60))
        ..emitPosition(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 400));
      await openPlayerPage(tester);
      final handle = tester.ensureSemantics();
      expect(find.text('0:10'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);

      tester.semantics.increase(find.semantics.byLabel('Position'));
      await tester.pump();

      expect(engine.calls.where((c) => c == 'seek'), hasLength(1));
      handle.dispose();
    });

    flow('the slider is off while the duration is unknown', (tester) async {
      await pump(tester);
      await start(tester);
      await openPlayerPage(tester);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });

    /// @verifies FR-017.9
    flow('an unreadable file is told in a banner, once', (tester) async {
      await pump(tester);
      await start(tester);
      await openPlayerPage(tester);

      engine.emitIssue(
        const EngineFailure(EngineFailureKind.playbackFailed, 'x'),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Cannot play “Alpha”: damaged file. Next track started.'),
        findsOneWidget,
      );
      expect(player.state.currentIndex, 1);
      await tester.tap(find.byTooltip('Hide this message'));
      await tester.pump();
      expect(find.textContaining('damaged file'), findsNothing);
    });

    /// @verifies FR-017.10
    flow('an ejection is told in a banner', (tester) async {
      await pump(tester);
      await start(tester, tracks: [remote, alpha]);
      await openPlayerPage(tester);

      volumes.emit(const VolumeEjecting(ssd));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Playback stopped: T7 Shield unplugged'),
        findsOneWidget,
      );
    });

    /// @verifies FR-017.11
    for (final (name, size, scale) in [
      ('portrait', const Size(412, 915), 1.0),
      ('landscape', const Size(915, 412), 1.0),
      ('portrait at 200 %', const Size(412, 915), 2.0),
      ('landscape at 200 %', const Size(915, 412), 2.0),
    ]) {
      flow('lays out without overflow in $name', (tester) async {
        await pump(tester, size: size, textScale: scale);
        await start(tester);
        await openPlayerPage(tester);

        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Collapse'), findsOneWidget);
        expect(find.byTooltip('Shuffle'), findsOneWidget);
      });
    }
  });
}
