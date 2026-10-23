import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/features/library/library_page.dart';
import 'package:tuneshell/features/library/player_bar.dart';
import 'package:tuneshell/features/shell/home_shell.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/platform/internal_storage.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

void main() {
  late FakeLibraryRepository repository;
  late FakeInternalAudioSource source;
  late FakeAudioPermission permission;
  late FakeAudioEngine engine;

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/a.mp3', title: 'Alpha'),
        info('Music/b.mp3', title: 'Bravo'),
        info('Music/c.mp3', title: 'Charlie'),
        info('Ringtones/r.ogg', title: 'Ring'),
      ];
    permission = FakeAudioPermission(AudioPermissionStatus.granted);
    engine = FakeAudioEngine();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repository),
          internalAudioSourceProvider.overrideWithValue(source),
          audioPermissionProvider.overrideWithValue(permission),
          audioEngineProvider.overrideWithValue(engine),
          trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
          volumeEventsProvider.overrideWithValue(InternalVolumeEvents()),
          removableAudioSourceProvider.overrideWithValue(
            FakeRemovableAudioSource(),
          ),
          tagReaderProvider.overrideWithValue(FakeTagReader()),
          artworkDirectoryProvider.overrideWith((ref) => '/artwork'),
        ],
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomeShell(tracks: LibraryPage(), playerBar: PlayerBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// @verifies UC-001
  /// @verifies FR-003
  testWidgets('first launch: folders, then the list of the chosen ones', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Ringtones'), findsOneWidget);
    expect(find.text('3 files'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Ring'), findsNothing);
  });

  /// @verifies UC-001
  testWidgets('touching a track plays it with the whole list as the queue', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charlie'));
    await tester.pumpAndSettle();

    expect(
      (engine.loadedSource! as FileMediaSource).path,
      'internal/Music/c.mp3',
    );
    expect(engine.state.playing, isTrue);
    final player = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPage)),
    ).read(playerControllerProvider);
    expect(player.state.queue.map((t) => t.relativePath), [
      'Music/a.mp3',
      'Music/b.mp3',
      'Music/c.mp3',
    ]);
    expect(player.state.currentIndex, 2);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Charlie'),
      ),
      findsOneWidget,
    );
  });

  /// @verifies FR-003.4
  group('leaving the folder choice', () {
    Future<void> openChoice(WidgetTester tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Folders'));
      await tester.pumpAndSettle();
      expect(find.text('Music folders'), findsOneWidget);
    }

    testWidgets('the back button returns to the list', (tester) async {
      await openChoice(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Music folders'), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('the system Back gesture returns to the list', (tester) async {
      await openChoice(tester);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('Music folders'), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('the first choice has no back button', (tester) async {
      await pumpPage(tester);

      expect(find.text('Music folders'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
    });
  });

  testWidgets('the playback bar stays while the folders are open', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Folders'));
    await tester.pumpAndSettle();

    expect(find.text('Music folders'), findsOneWidget);
    expect(find.byType(PlayerBar), findsOneWidget);
  });

  /// @verifies FR-004
  testWidgets('a permanent refusal offers the settings', (tester) async {
    permission
      ..current = AudioPermissionStatus.permanentlyDenied
      ..answer = AudioPermissionStatus.permanentlyDenied;
    await pumpPage(tester);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(permission.settingsOpened, 1);
  });

  /// @verifies UC-001
  testWidgets('no folder chosen leads back to the folder choice', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Music'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('No folder chosen'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Choose folders'));
    await tester.pumpAndSettle();

    expect(find.text('Music folders'), findsOneWidget);
  });

  /// @verifies BR-004 rule 5: the tracks of an absent disk are greyed.
  testWidgets('tracks of an absent disk are greyed', (tester) async {
    const ssd = DiskId('1234-ABCD');
    await repository.ensureDisk(Disk.internal);
    await repository.ensureDisk(
      const Disk(id: ssd, label: 'SSD', kind: DiskKind.removable),
    );
    await repository.applyScan(ssd, [info('Gone.mp3', title: 'Gone')]);
    await repository.setChosenFolders(Disk.internal, {'Music'});
    await pumpPage(tester);

    TrackTileState state(String title) =>
        tester.widget<TrackTile>(find.widgetWithText(TrackTile, title)).state;
    expect(state('Gone'), TrackTileState.unavailable);
    expect(state('Alpha'), TrackTileState.noArtwork);
  });

  /// Tracks of an absent SSD among the local ones (BR-008).
  Future<void> pumpWithAbsentDisk(WidgetTester tester) async {
    const ssd = DiskId('1234-ABCD');
    await repository.ensureDisk(Disk.internal);
    await repository.ensureDisk(
      const Disk(id: ssd, label: 'SSD', kind: DiskKind.removable),
    );
    await repository.applyScan(ssd, [info('Gone.mp3', title: 'Gone')]);
    await repository.setChosenFolders(Disk.internal, {'Music'});
    await pumpPage(tester);
  }

  group('the sources banner', () {
    /// @verifies BR-008.2
    testWidgets('names the absent disk and counts its tracks', (tester) async {
      await pumpWithAbsentDisk(tester);

      expect(find.text('1 track skipped: SSD missing'), findsOneWidget);
      expect(find.text('See'), findsOneWidget);
      expect(find.text('1 missing'), findsOneWidget);
    });

    /// @verifies BR-008.3
    testWidgets('can be hidden', (tester) async {
      await pumpWithAbsentDisk(tester);

      await tester.tap(find.byTooltip('Hide this message'));
      await tester.pumpAndSettle();

      expect(find.textContaining('skipped'), findsNothing);
    });

    /// @verifies FR-011.5
    testWidgets('the count line tells how many are unavailable', (
      tester,
    ) async {
      await pumpWithAbsentDisk(tester);

      expect(find.text('4 tracks · 1 unavailable'), findsOneWidget);
      expect(find.text('Title A→Z'), findsOneWidget);
    });

    /// @verifies BR-008.5
    testWidgets('touching an unavailable track says what to plug in', (
      tester,
    ) async {
      await pumpWithAbsentDisk(tester);

      await tester.tap(find.text('Gone'));
      await tester.pump();

      expect(find.text('Plug in SSD to play this track'), findsOneWidget);
      expect(engine.loadedSource, isNull);
    });
  });

  /// @verifies FR-011.9
  testWidgets('an empty library offers the folders and a refresh', (
    tester,
  ) async {
    source.files = [info('Ringtones/r.ogg', title: 'Ring')];
    await repository.ensureDisk(Disk.internal);
    await repository.setChosenFolders(Disk.internal, {'Music'});
    await pumpPage(tester);

    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Refresh'), findsOneWidget);
  });

  /// @verifies FR-011.1
  testWidgets('the search button is there, and disabled', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.search_rounded),
    );
    expect(button.onPressed, isNull);
    expect(find.byTooltip('Search (soon)'), findsOneWidget);
  });

  /// @verifies FR-013.3
  /// @verifies FR-013.5
  testWidgets('the now playing button leads back to the track', (tester) async {
    source.files = [
      for (var i = 0; i < 300; i++)
        info('Music/$i.mp3', title: 'T${i.toString().padLeft(3, '0')}'),
    ];
    await pumpPage(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T000'));
    await tester.pumpAndSettle();
    final list = find.byType(CustomScrollView);
    Finder fab() => find.byType(JumpToCurrentFab);
    expect(fab(), findsOneWidget);
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0,
      reason: 'the playing row is on screen',
    );

    await tester.drag(list, const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

    await tester.tap(
      find.descendant(of: fab(), matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();

    expect(find.text('T000'), findsWidgets);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0);
    // The timers of the fold and of the highlight end.
    await tester.pump(const Duration(seconds: 2));
  });
}
