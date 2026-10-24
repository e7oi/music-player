import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/features/browse/albums_view.dart';
import 'package:tuneshell/features/browse/artists_view.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/player/mini_player_bar.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/shell/home_shell.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/album_card.dart';
import 'package:tuneshell/ui/widgets/artist_tile.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const ssd = DiskId('ssd');

var _id = 0;

LibraryTrack t(
  String title, {
  String? albumArtist,
  String? album,
  int? disc,
  int? number,
  int? year,
  int seconds = 60,
  DiskId disk = internalDisk,
}) => LibraryTrack(
  id: ++_id,
  disk: disk,
  info: TrackInfo(
    relativePath: 'Music/$title.mp3',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
    albumArtist: albumArtist,
    artist: albumArtist,
    album: album,
    discNumber: disc,
    trackNumber: number,
    year: year,
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
  late List<List<Rect>> rects;

  // An album of two discs given in disorder, one of one track, a second
  // artist, and tracks without tags.
  final lib = [
    t(
      'd2t1',
      albumArtist: 'Clara',
      album: 'Littoral',
      disc: 2,
      number: 1,
      year: 2019,
    ),
    t(
      'd1t2',
      albumArtist: 'Clara',
      album: 'Littoral',
      disc: 1,
      number: 2,
      year: 2019,
    ),
    t(
      'd1t1',
      albumArtist: 'Clara',
      album: 'Littoral',
      disc: 1,
      number: 1,
      year: 2019,
    ),
    t('solo', albumArtist: 'Clara', album: 'Azur', number: 1, year: 2015),
    t('off1', albumArtist: 'Nodal', album: 'Champs', number: 1, disk: ssd),
    t('raw'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<LibraryTrack>? tracks,
    Set<DiskId> available = const {internalDisk, ssd},
    Size size = const Size(412, 915),
    double textScale = 1,
    Stream<List<LibraryTrack>>? tracksStream,
  }) async {
    tester.view
      ..physicalSize = size
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
    rects = [];
    final all = tracks ?? lib;
    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWithValue(player),
        listedTracksProvider.overrideWith(
          (ref) => tracksStream ?? Stream.value(all),
        ),
        libraryDisksProvider.overrideWith(
          (ref) => Stream.value(const [
            Disk.internal,
            Disk(
              id: ssd,
              label: 'T7 Shield',
              kind: DiskKind.removable,
              markIndex: 0,
            ),
          ]),
        ),
        unavailableDiskIdsProvider.overrideWithValue({
          for (final id in {internalDisk, ssd})
            if (!available.contains(id)) id,
        }),
        trackIndexProvider.overrideWithValue({for (final x in all) x.track: x}),
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
        gestureRegionsProvider.overrideWithValue(
          GestureRegions((r) async => rects.add(r)),
        ),
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
          home: const HomeShell(
            tracks: SizedBox(),
            albums: AlbumsView(),
            artists: ArtistsView(),
            playerBar: MiniPlayerBar(),
          ),
        ),
      ),
    );
    // A stream that has not spoken yet leaves a spinner turning for ever.
    if (tracksStream == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is NavigationBar || w is NavigationRail,
        ),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// @verifies FR-020.1
  /// @verifies FR-020.2
  group('Albums', () {
    flow('a grid with the count and the sort label', (tester) async {
      await pump(tester);
      await tab(tester, 'Albums');

      expect(find.text('4 albums'), findsOneWidget);
      expect(find.text('Album artist'), findsOneWidget);
      expect(find.byType(AlbumCard), findsNWidgets(4));
      expect(find.text('Littoral'), findsOneWidget);
      expect(find.text('Clara · 2019'), findsWidgets);
    });

    flow('sorted by artist, then year', (tester) async {
      await pump(tester);
      await tab(tester, 'Albums');

      final titles = [
        for (final card in tester.widgetList<AlbumCard>(find.byType(AlbumCard)))
          card.title,
      ];
      expect(titles, ['Unknown album', 'Azur', 'Littoral', 'Champs']);
    });

    flow('the unknown album says its artist and its tracks', (tester) async {
      await pump(tester);
      await tab(tester, 'Albums');

      expect(find.text('Unknown artist · 1 track'), findsOneWidget);
    });

    /// @verifies FR-020.5
    flow('an album of an absent disk is greyed and says why', (tester) async {
      await pump(tester, available: {internalDisk});
      await tab(tester, 'Albums');

      final off = tester
          .widgetList<AlbumCard>(find.byType(AlbumCard))
          .firstWhere((c) => c.title == 'Champs');
      expect(off.unavailable, isTrue);
      expect(off.semanticsLabel, contains('T7 Shield not connected'));
    });

    flow('an empty library says so and points to Tracks', (tester) async {
      await pump(tester, tracks: const []);
      await tab(tester, 'Albums');

      expect(find.text('No albums'), findsOneWidget);
      expect(find.text('Choose folders in the Tracks tab.'), findsOneWidget);
    });

    /// @verifies FR-020.8
    flow('a detail opens in the tab and Back returns to the grid', (
      tester,
    ) async {
      await pump(tester);
      await tab(tester, 'Albums');

      await tester.tap(find.text('Littoral'));
      await tester.pumpAndSettle();
      expect(find.text('Play'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Play'), findsNothing);
      expect(find.byType(AlbumCard), findsWidgets);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlbumCard), findsNothing);
    });
  });

  /// @verifies FR-020.9
  /// @verifies FR-020.10
  group('Album detail', () {
    Future<void> open(WidgetTester tester) async {
      await pump(tester);
      await tab(tester, 'Albums');
      await tester.tap(find.text('Littoral'));
      await tester.pumpAndSettle();
    }

    flow('header, discs and tracks by disc then number', (tester) async {
      await open(tester);

      expect(find.text('Clara'), findsOneWidget);
      expect(find.text('2019'), findsOneWidget);
      expect(find.text('2 discs · 3 tracks · 3 min'), findsOneWidget);
      expect(find.text('DISC 1'), findsOneWidget);
      expect(find.text('DISC 2'), findsOneWidget);
      final order = [
        for (final name in ['d1t1', 'd1t2', 'd2t1'])
          tester.getTopLeft(find.text(name)).dy,
      ];
      expect(order, [...order]..sort());
    });

    flow('Play queues the album in disc then track order', (tester) async {
      await open(tester);

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump();

      expect(player.state.queue.map((x) => x.relativePath), [
        'Music/d1t1.mp3',
        'Music/d1t2.mp3',
        'Music/d2t1.mp3',
      ]);
      expect(player.state.currentIndex, 0);
      expect(player.state.shuffle, isFalse);
      expect(player.state.playing, isTrue);
    });

    flow('Shuffle turns the mode on and starts the album', (tester) async {
      await open(tester);

      await tester.tap(find.text('Shuffle'));
      await tester.pump();
      await tester.pump();

      expect(player.state.shuffle, isTrue);
      expect(player.state.queue, hasLength(3));
      expect(player.state.playing, isTrue);
    });

    flow('touching a track plays the album from it', (tester) async {
      await open(tester);

      await tester.tap(find.text('d2t1'));
      await tester.pump();
      await tester.pump();

      expect(player.state.currentTrack!.relativePath, 'Music/d2t1.mp3');
      expect(player.state.queue, hasLength(3));
    });

    flow('the queue says it comes from the album', (tester) async {
      await open(tester);

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump();

      expect(
        _container!.read(queueOriginProvider),
        const AlbumOrigin('Littoral'),
      );
    });

    flow('the playing track is marked', (tester) async {
      await open(tester);
      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    });

    /// @verifies FR-022.4
    flow('an unavailable track explains and starts nothing', (tester) async {
      await pump(tester, available: {internalDisk});
      await tab(tester, 'Albums');
      await tester.tap(find.text('Champs'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('off1'));
      await tester.pump();

      expect(find.text('Plug in T7 Shield to play this track'), findsOneWidget);
      expect(player.state.queue, isEmpty);
    });

    /// @verifies FR-022.6
    flow('a long press on a card queues the whole album in order', (
      tester,
    ) async {
      await pump(tester);
      await player.setQueue([lib.last.track]);
      await tab(tester, 'Albums');

      await tester.longPress(find.text('Littoral'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to queue'));
      await tester.pumpAndSettle();

      expect(player.state.queue.map((x) => x.relativePath).skip(1), [
        'Music/d1t1.mp3',
        'Music/d1t2.mp3',
        'Music/d2t1.mp3',
      ]);
      expect(find.text('Added to the queue: Littoral'), findsOneWidget);
    });

    flow('"Play next" puts the album right after the current track', (
      tester,
    ) async {
      await pump(tester);
      await player.setQueue([lib.last.track, lib[3].track]);
      await tab(tester, 'Albums');

      await tester.longPress(find.text('Littoral'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play next'));
      await tester.pumpAndSettle();

      expect(player.state.queue.map((x) => x.relativePath).take(4), [
        'Music/raw.mp3',
        'Music/d1t1.mp3',
        'Music/d1t2.mp3',
        'Music/d2t1.mp3',
      ]);
    });
  });

  /// @verifies FR-021
  group('Artists', () {
    flow('a list with the count, avatars, summaries and headers', (
      tester,
    ) async {
      await pump(tester);
      await tab(tester, 'Artists');

      expect(find.text('3 artists · grouped by album artist'), findsOneWidget);
      expect(find.text('Clara'), findsOneWidget);
      expect(find.text('2 albums · 4 tracks'), findsOneWidget);
      expect(find.text('Unknown artist'), findsOneWidget);
      expect(find.text('1 track without tags'), findsOneWidget);
      expect(find.text('#'), findsOneWidget);
      expect(find.text('C'), findsWidgets);
      expect(find.byType(ArtistTile), findsNWidgets(3));
    });

    flow('an artist of an absent disk is greyed and names the disk', (
      tester,
    ) async {
      await pump(tester, available: {internalDisk});
      await tab(tester, 'Artists');

      expect(
        find.text('1 album · 1 track · T7 Shield not connected'),
        findsOneWidget,
      );
      final tile = tester
          .widgetList<ArtistTile>(find.byType(ArtistTile))
          .firstWhere((x) => x.name == 'Nodal');
      expect(tile.unavailable, isTrue);
    });

    flow('the detail shows the albums and the tracks, album by album', (
      tester,
    ) async {
      await pump(tester);
      await tab(tester, 'Artists');
      await tester.tap(find.text('Clara'));
      await tester.pumpAndSettle();

      expect(find.text('2 albums · 4 tracks · 4 min'), findsOneWidget);
      expect(find.text('Play all'), findsOneWidget);
      expect(find.text('Albums'), findsWidgets);
      final order = [
        for (final name in ['solo', 'd1t1', 'd1t2', 'd2t1'])
          tester.getTopLeft(find.text(name)).dy,
      ];
      expect(order, [...order]..sort());
    });

    flow('Play all queues the albums in order and names the artist', (
      tester,
    ) async {
      await pump(tester);
      await tab(tester, 'Artists');
      await tester.tap(find.text('Clara'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play all'));
      await tester.pump();
      await tester.pump();

      expect(player.state.queue.map((x) => x.relativePath), [
        'Music/solo.mp3',
        'Music/d1t1.mp3',
        'Music/d1t2.mp3',
        'Music/d2t1.mp3',
      ]);
      expect(
        _container!.read(queueOriginProvider),
        const ArtistOrigin('Clara'),
      );
    });

    flow('an album of the carousel opens its detail; Back returns', (
      tester,
    ) async {
      await pump(tester);
      await tab(tester, 'Artists');
      await tester.tap(find.text('Clara'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AlbumCard, 'Littoral'));
      await tester.pumpAndSettle();
      expect(find.text('2 discs · 3 tracks · 3 min'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Play all'), findsOneWidget);
    });

    flow('Shuffle on an artist turns the mode on', (tester) async {
      await pump(tester);
      await tab(tester, 'Artists');
      await tester.tap(find.text('Clara'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shuffle'));
      await tester.pump();
      await tester.pump();

      expect(player.state.shuffle, isTrue);
      expect(player.state.queue, hasLength(4));
    });

    flow('an empty library says so', (tester) async {
      await pump(tester, tracks: const []);
      await tab(tester, 'Artists');

      expect(find.text('No artists'), findsOneWidget);
    });
  });

  /// @verifies FR-020.6
  flow('the index of the tab in front is the one that keeps Back out', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 150; i++)
        t(
          't$i',
          albumArtist: 'Artist ${String.fromCharCode(65 + i % 26)}$i',
          album: 'Album $i',
          number: 1,
        ),
    ];
    await pump(tester, tracks: many);

    await tab(tester, 'Albums');
    await tester.pump();
    final albumsRects = rects.last;
    await tab(tester, 'Artists');
    await tester.pump();

    expect(albumsRects, isNotEmpty);
    expect(rects.last, isNotEmpty);
    await tab(tester, 'Albums');
    await tester.pump();
    expect(rects.last, hasLength(1));
  });

  /// @verifies FR-022.8
  flow('an album added on an empty queue says where it comes from', (
    tester,
  ) async {
    await pump(tester);
    await tab(tester, 'Albums');

    await tester.longPress(find.text('Littoral'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to queue'));
    await tester.pumpAndSettle();

    expect(
      _container!.read(queueOriginProvider),
      const AlbumOrigin('Littoral'),
    );
    expect(player.state.queue, hasLength(3));
    expect(player.state.playing, isTrue);
  });

  flow('an artist added on an empty queue says where it comes from', (
    tester,
  ) async {
    await pump(tester);
    await tab(tester, 'Artists');

    await tester.longPress(find.text('Clara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play next'));
    await tester.pumpAndSettle();

    expect(_container!.read(queueOriginProvider), const ArtistOrigin('Clara'));
  });

  /// @verifies FR-022.7
  flow('cards, rows and tracks offer the menu actions to TalkBack', (
    tester,
  ) async {
    List<String> labels() => [
      for (final semantics in tester.widgetList<Semantics>(
        find.byType(Semantics),
      ))
        ...?semantics.properties.customSemanticsActions?.keys.map(
          (action) => action.label ?? '',
        ),
    ];

    await pump(tester);
    await tab(tester, 'Albums');
    expect(labels().where((l) => l == 'Add to queue'), isNotEmpty);
    await tester.tap(find.text('Littoral'));
    await tester.pumpAndSettle();
    expect(labels().where((l) => l == 'Play next').length, greaterThan(2));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tab(tester, 'Artists');
    expect(labels().where((l) => l == 'Play next'), isNotEmpty);
    await tester.tap(find.text('Clara'));
    await tester.pumpAndSettle();
    expect(labels().where((l) => l == 'Add to queue').length, greaterThan(4));
  });

  /// @verifies FR-022.5
  flow('Play on an album with no available disk starts nothing', (
    tester,
  ) async {
    await pump(tester, available: {internalDisk});
    await tab(tester, 'Albums');
    await tester.tap(find.text('Champs'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pump();

    expect(find.text('Plug in T7 Shield to play this track'), findsOneWidget);
    expect(player.state.queue, isEmpty);
  });

  /// @verifies FR-022.3
  flow('Shuffle does not always start on the first track', (tester) async {
    final big = [
      for (var i = 0; i < 20; i++)
        t('s$i', albumArtist: 'Big', album: 'Album', number: i + 1),
    ];
    await pump(tester, tracks: big);
    await tab(tester, 'Albums');
    await tester.tap(find.text('Album'));
    await tester.pumpAndSettle();

    final firsts = <String>{};
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.text('Shuffle'));
      await tester.pump();
      await tester.pump();
      firsts.add(player.state.currentTrack!.relativePath);
    }

    expect(firsts.length, greaterThan(1));
    expect(player.state.shuffle, isTrue);
  });

  /// @verifies FR-020.10
  flow('an unavailable track of a detail shows the plug icon', (tester) async {
    await pump(tester, available: {internalDisk});
    await tab(tester, 'Albums');
    await tester.tap(find.text('Champs'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.usb_off_rounded), findsWidgets);
  });

  flow('a track number below one shows the position instead', (tester) async {
    await pump(
      tester,
      tracks: [
        t('first', albumArtist: 'A', album: 'Zero', number: 0),
        t('second', albumArtist: 'A', album: 'Zero', number: 0),
      ],
    );
    await tab(tester, 'Albums');
    await tester.tap(find.text('Zero'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  /// @verifies FR-020.8
  flow('a detail whose album is gone says so', (tester) async {
    final updates = StreamController<List<LibraryTrack>>();
    addTearDown(updates.close);
    await pump(tester, tracksStream: updates.stream);
    updates.add(lib);
    await tester.pumpAndSettle();
    await tab(tester, 'Albums');
    await tester.tap(find.text('Littoral'));
    await tester.pumpAndSettle();

    updates.add([lib.last]);
    await tester.pumpAndSettle();

    expect(
      find.text('This album is no longer in the library.'),
      findsOneWidget,
    );
  });

  flow('an artist detail whose artist is gone says so', (tester) async {
    final updates = StreamController<List<LibraryTrack>>();
    addTearDown(updates.close);
    await pump(tester, tracksStream: updates.stream);
    updates.add(lib);
    await tester.pumpAndSettle();
    await tab(tester, 'Artists');
    await tester.tap(find.text('Clara'));
    await tester.pumpAndSettle();

    updates.add([lib.last]);
    await tester.pumpAndSettle();

    expect(
      find.text('This artist is no longer in the library.'),
      findsOneWidget,
    );
  });

  flow('the grid keeps its place when a detail is closed', (tester) async {
    final many = [
      for (var i = 0; i < 150; i++)
        t(
          't$i',
          albumArtist: 'Artist ${i.toString().padLeft(3, '0')}',
          album: 'Album ${i.toString().padLeft(3, '0')}',
          number: 1,
        ),
    ];
    await pump(tester, tracks: many);
    await tab(tester, 'Albums');
    await tester.drag(find.byType(GridView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    final grid = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    final before = grid.position.pixels;
    expect(before, greaterThan(500));

    await tester.tap(find.byType(AlbumCard).hitTestable().first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(grid.position.pixels, before);
  });

  /// @verifies FR-020.6
  flow('no index handle under 100 albums, one above', (tester) async {
    await pump(tester);
    await tab(tester, 'Albums');
    await tester.pump();
    expect(rects.every((list) => list.isEmpty), isTrue);
  });

  /// @verifies FR-020.12
  for (final (name, size, scale) in [
    ('portrait', const Size(412, 915), 1.0),
    ('landscape', const Size(915, 412), 1.0),
    ('200 %', const Size(412, 915), 2.0),
  ]) {
    flow('lays out without overflow in $name', (tester) async {
      await pump(tester, size: size, textScale: scale);
      await tab(tester, 'Albums');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Littoral'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Littoral'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tab(tester, 'Artists');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Clara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clara'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  flow('a source mark shows on a card whose disk has a mark', (tester) async {
    await pump(tester);
    await tab(tester, 'Albums');

    expect(find.byType(SourceMark), findsWidgets);
  });
}
