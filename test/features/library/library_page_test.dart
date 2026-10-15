import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/app/providers/library_providers.dart';
import 'package:musicplayer/app/providers/player_providers.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';
import 'package:musicplayer/features/library/library_page.dart';
import 'package:musicplayer/features/library/player_bar.dart';
import 'package:musicplayer/l10n/generated/app_localizations.dart';
import 'package:musicplayer/platform/internal_storage.dart';

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
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: LibraryPage(),
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
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PlayerBar),
        matching: find.text('Charlie'),
      ),
      findsOneWidget,
    );
  });

  /// @verifies FR-004
  testWidgets('a permanent refusal offers the settings', (tester) async {
    permission.current = AudioPermissionStatus.permanentlyDenied;
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

    expect(find.text('No folder chosen.'), findsOneWidget);
    await tester.tap(find.text('Choose folders'));
    await tester.pumpAndSettle();

    expect(find.text('Music folders'), findsOneWidget);
  });
}
