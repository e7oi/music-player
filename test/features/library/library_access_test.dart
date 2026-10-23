import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/removable_controller.dart';

import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

const _ssd = DiskId('SSD-1');
const RemovableFolder _music = RemovableFolder(
  disk: _ssd,
  diskLabel: 'SSD',
  path: 'Music',
);

void main() {
  late FakeLibraryRepository repository;
  late FakeAudioPermission permission;
  late FakeRemovableAudioSource removable;
  late ProviderContainer container;

  LibraryViewState state() => container.read(libraryControllerProvider);
  LibraryController controller() =>
      container.read(libraryControllerProvider.notifier);

  setUp(() {
    repository = FakeLibraryRepository();
    permission = FakeAudioPermission(AudioPermissionStatus.permanentlyDenied);
    removable = FakeRemovableAudioSource()
      ..mounted = [const MountedVolume(id: _ssd, label: 'SSD')]
      ..granted = {_music}
      ..picked = _music
      ..files[(_ssd, 'Music')] = [info('Music/s.mp3', title: 'Sea')];
    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        internalAudioSourceProvider.overrideWithValue(
          FakeInternalAudioSource(),
        ),
        audioPermissionProvider.overrideWithValue(permission),
        removableAudioSourceProvider.overrideWithValue(removable),
        tagReaderProvider.overrideWithValue(FakeTagReader()),
        volumeEventsProvider.overrideWithValue(
          FakeVolumeEvents({internalDisk, _ssd}),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  /// @verifies FR-014.5
  group('choosing a folder instead of granting access', () {
    setUp(() => controller().start());

    test('a disk folder is added and the library shows it', () async {
      expect(
        state(),
        isA<LibraryPermissionNeeded>().having(
          (s) => s.permanent,
          'permanent',
          true,
        ),
      );

      await controller().chooseFolderInstead();

      expect(state(), isA<LibraryReady>());
      expect(repository.tracks.map((t) => t.info.title), ['Sea']);
    });

    test('a cancelled picker keeps the blocked screen', () async {
      removable.picked = null;

      await controller().chooseFolderInstead();

      expect(state(), isA<LibraryPermissionNeeded>());
    });

    test('a folder of the phone is refused and says why', () async {
      removable.pickError = const NotRemovableException();

      await controller().chooseFolderInstead();

      expect(state(), isA<LibraryPermissionNeeded>());
      expect(
        container.read(removableControllerProvider).message,
        RemovableMessage.notRemovable,
      );
    });

    test('returning to the app does not undo it', () async {
      await controller().chooseFolderInstead();

      await controller().onResumed();

      expect(state(), isA<LibraryReady>());
    });

    test('access granted later in the settings offers the folders', () async {
      await controller().chooseFolderInstead();
      permission.current = AudioPermissionStatus.granted;

      await controller().onResumed();

      expect(state(), isA<LibraryFolderChoice>());
    });

    test('Not now from that explanation returns to the library', () async {
      await controller().chooseFolderInstead();
      await controller().openFolderChoice();

      controller().declineAccess();

      expect(state(), isA<LibraryReady>());
      expect(repository.tracks.map((t) => t.info.title), ['Sea']);
    });

    test('Back from that explanation returns to the library', () async {
      await controller().chooseFolderInstead();
      await controller().openFolderChoice();

      controller().backToWelcome();

      expect(state(), isA<LibraryReady>());
    });

    test('access granted from the dialog ends the limited library', () async {
      await controller().chooseFolderInstead();
      await controller().openFolderChoice();
      permission
        ..current = AudioPermissionStatus.notRequested
        ..answer = AudioPermissionStatus.granted;

      await controller().requestPermission();
      await controller().openFolderChoice();

      expect(state(), isA<LibraryFolderChoice>());
    });

    test('Folders without access leads back to the explanation', () async {
      await controller().chooseFolderInstead();

      await controller().openFolderChoice();

      expect(
        state(),
        isA<LibraryWelcome>().having((s) => s.explaining, 'explaining', true),
      );
    });
  });

  /// @verifies FR-015.7
  group('adding a folder from the folder choice', () {
    setUp(() async {
      permission.current = AudioPermissionStatus.granted;
      await controller().start();
    });

    test('keeps the choice on screen, with its checked folders', () async {
      final before = state();
      expect(before, isA<LibraryFolderChoice>());

      await controller().addRemovableFolder();

      expect(state(), same(before));
    });

    test('the disk is registered for the disks screen', () async {
      await controller().addRemovableFolder();

      expect(
        container.read(removableControllerProvider).disks.single.disk.id,
        _ssd,
      );
    });
  });
}
