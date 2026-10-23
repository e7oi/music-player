import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/library/removable_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

void main() {
  const ssd = DiskId('1234-ABCD');
  const music = RemovableFolder(disk: ssd, diskLabel: 'SSD', path: 'Music');
  late FakeLibraryRepository repository;
  late FakeRemovableAudioSource source;
  late FakeTagReader reader;
  late FakeVolumeEvents volumes;
  late ProviderContainer container;

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeRemovableAudioSource()
      ..mounted = [const MountedVolume(id: ssd, label: 'SSD')]
      ..granted = {music}
      ..picked = music
      ..files[(ssd, 'Music')] = [info('Music/a.mp3'), info('Music/b.mp3')];
    reader = FakeTagReader();
    volumes = FakeVolumeEvents({internalDisk, ssd});
    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        removableAudioSourceProvider.overrideWithValue(source),
        tagReaderProvider.overrideWithValue(reader),
        volumeEventsProvider.overrideWithValue(volumes),
      ],
    );
  });

  tearDown(() => container.dispose());

  RemovableViewState state() => container.read(removableControllerProvider);
  RemovableController controller() =>
      container.read(removableControllerProvider.notifier);

  /// @verifies UC-003
  group('controller', () {
    test('adding a folder lists the disk and reads the tags', () async {
      reader.tags[const Track(disk: ssd, relativePath: 'Music/a.mp3')] =
          const FileTags(title: 'Alpha');

      await controller().addFolder();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(state().busy, isFalse);
      expect(state().disks.single.disk.label, 'SSD');
      expect(state().disks.single.folders, {'Music'});
      expect(repository.tracks, hasLength(2));
      expect(
        repository.tracks.every((t) => t.tagsState != TagsState.pending),
        isTrue,
      );
      expect(volumes.refreshes, greaterThan(0));
    });

    test('a folder without audio says so', () async {
      source.files[(ssd, 'Music')] = [];

      await controller().addFolder();

      expect(state().message, RemovableMessage.noAudio);
      expect(state().disks, isEmpty);
    });

    test('a folder of the phone is refused with its own message', () async {
      source.pickError = const NotRemovableException();

      await controller().addFolder();

      expect(state().message, RemovableMessage.notRemovable);
    });

    test('a failed scan says so and keeps the app usable', () async {
      source.failing[(ssd, 'Music')] = Exception('unplugged');

      await controller().addFolder();

      expect(state().message, RemovableMessage.addFailed);
      expect(state().busy, isFalse);
    });

    test('clearing the message empties it', () async {
      source.files[(ssd, 'Music')] = [];
      await controller().addFolder();

      controller().clearMessage();

      expect(state().message, isNull);
    });

    test('a refresh that fails reports it and keeps the tracks', () async {
      await controller().addFolder();
      source.failing[(ssd, 'Music')] = Exception('io error');

      await controller().refresh();

      expect(state().message, RemovableMessage.refreshFailed);
      expect(repository.tracks, hasLength(2));
    });

    /// @verifies FR-006.10
    test(
      'coming back to the foreground reads the availability again',
      () async {
        await controller().addFolder();
        source.mounted = [];

        await controller().onResumed();

        expect(state().disks.single.status.name, 'absent');
        expect(volumes.refreshes, greaterThan(1));
      },
    );

    test('removing a folder drops its tracks', () async {
      await controller().addFolder();

      await controller().removeFolder(ssd, 'Music');

      expect(repository.tracks, isEmpty);
      expect(source.released, [(ssd, 'Music')]);
    });

    /// @verifies BR-006.5 a stop is not followed by the reading of tags.
    test('a stopped scan does not start the tags', () async {
      await repository.setChosenFolders(
        const Disk(id: ssd, label: 'SSD', kind: DiskKind.removable),
        {'Music'},
      );
      await repository.applyScan(ssd, [info('Music/a.mp3')]);
      source.failing[(ssd, 'Music')] = const ScanCancelledException();

      await controller().refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(reader.reads, isEmpty);
      expect(state().busy, isFalse);
    });

    /// @verifies BR-006.5
    test('cancel stops the scan and the tags', () async {
      await controller().cancel();

      expect(source.cancels, 1);
    });
  });

  group('page', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: RemovablePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a hint before any disk', (tester) async {
      await pump(tester);

      expect(find.textContaining('No removable disk yet'), findsOneWidget);
      expect(find.text('Add a folder'), findsOneWidget);
    });

    /// @verifies UC-003
    testWidgets('adding a folder shows the disk and its folder', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Add a folder'));
      await tester.pumpAndSettle();

      expect(find.text('SSD'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
    });

    /// @verifies FR-006.10
    testWidgets('an absent disk is shown as not connected', (tester) async {
      await container.read(removableIndexerProvider).addFolder();
      source.mounted = [];
      await pump(tester);

      expect(find.text('Not connected'), findsOneWidget);
    });

    /// @verifies FR-006.11
    testWidgets('a lost access offers to renew it', (tester) async {
      await container.read(removableIndexerProvider).addFolder();
      source.granted = {};
      await pump(tester);

      expect(find.text('Access to renew'), findsOneWidget);
      expect(find.text('Renew access'), findsOneWidget);
      expect(repository.tracks, hasLength(2));
    });

    testWidgets('a message appears for a folder without audio', (tester) async {
      source.files[(ssd, 'Music')] = [];
      await pump(tester);

      await tester.tap(find.text('Add a folder'));
      await tester.pumpAndSettle();

      expect(
        find.text('No audio file was found in this folder.'),
        findsOneWidget,
      );
    });

    testWidgets('removing a folder asks the controller to drop it', (
      tester,
    ) async {
      await container.read(removableIndexerProvider).addFolder();
      await pump(tester);

      await tester.tap(find.byTooltip('Remove this folder'));
      await tester.pumpAndSettle();

      expect(repository.tracks, isEmpty);
      expect(find.text('Music'), findsNothing);
    });
  });
}
