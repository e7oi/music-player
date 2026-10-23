import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

import '../../fakes/fake_audio_engine.dart';
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
  late FakeRemovableAudioSource removable;
  late FakeTrackSourceOpener opener;
  late ProviderContainer container;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  setUp(() async {
    repository = FakeLibraryRepository();
    removable = FakeRemovableAudioSource()
      ..mounted = [const MountedVolume(id: _ssd, label: 'SSD')]
      ..granted = {_music}
      ..picked = _music
      ..files[(_ssd, 'Music')] = [info('Music/s.mp3', title: 'Sea')];
    opener = FakeTrackSourceOpener();
    await repository.ensureDisk(Disk.internal);
    await repository.applyIndex(internalDisk, [
      info('Music/a.mp3', title: 'Alpha'),
      info('Music/b.mp3', title: 'Beta'),
    ]);
    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        removableAudioSourceProvider.overrideWithValue(removable),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        trackSourceOpenerProvider.overrideWithValue(opener),
        volumeEventsProvider.overrideWithValue(
          FakeVolumeEvents({internalDisk, _ssd}),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  LibraryListModel? model() => container.read(libraryListModelProvider);

  void listen() {
    container
      ..listen(libraryListModelProvider, (_, _) {}, fireImmediately: true)
      ..listen(lastPlayedProvider, (_, _) {}, fireImmediately: true)
      ..listen(unreadableTracksProvider, (_, _) {}, fireImmediately: true);
  }

  test('the model is empty until the tracks are read, then complete', () async {
    listen();

    await settle();

    expect(model()?.entries.map((e) => e.track.displayTitle), [
      'Alpha',
      'Beta',
    ]);
  });

  /// @verifies BR-008.1
  test('a disk that is not mounted makes its tracks unavailable', () async {
    await container.read(removableIndexerProvider).addFolder();
    removable.mounted = [];
    listen();
    await container.read(removableControllerProvider.notifier).load();

    await settle();

    expect(container.read(unavailableDisksProvider), {_ssd: DiskIssue.absent});
    expect(model()?.unavailableCount, 1);
    final sea = model()!.entries.firstWhere(
      (e) => e.track.displayTitle == 'Sea',
    );
    expect(sea.state, TrackTileState.unavailable);
    expect(sea.disk?.markIndex, 0);
  });

  /// @verifies BR-008.1
  test('a lost access makes them unavailable too', () async {
    await container.read(removableIndexerProvider).addFolder();
    removable.granted = {};
    listen();
    await container.read(removableControllerProvider.notifier).load();

    await settle();

    expect(container.read(unavailableDisksProvider), {
      _ssd: DiskIssue.accessLost,
    });
  });

  /// @verifies FR-013.4
  test('the last played track is kept after the player stops', () async {
    listen();
    await settle();
    final player = container.read(playerControllerProvider);
    final alpha = model()!.entries.first.track.track;

    await player.setQueue([alpha]);
    await player.play();
    await settle();
    await player.stop();
    await settle();

    expect(container.read(lastPlayedProvider), alpha);
  });

  /// @verifies FR-011.6
  test('a track the engine failed on is marked unreadable', () async {
    listen();
    await settle();
    final player = container.read(playerControllerProvider);
    final beta = model()!.entries.last.track.track;
    opener.failing.add(beta);

    await player.setQueue([beta]);
    await player.play();
    await settle();

    expect(container.read(unreadableTracksProvider), {beta});
    expect(model()!.entries.last.state, TrackTileState.unreadable);
  });

  /// @verifies BR-008.3
  test('a closed banner returns when the sources change', () async {
    await container.read(removableIndexerProvider).addFolder();
    removable.mounted = [];
    listen();
    await container.read(removableControllerProvider.notifier).load();
    await settle();
    final banner = model()!.banner!;

    container
        .read(dismissedBannerProvider.notifier)
        .dismiss(banner.fingerprint);
    await settle();
    expect(model()!.banner, isNull);

    removable.mounted = [const MountedVolume(id: _ssd, label: 'SSD')];
    await container.read(removableControllerProvider.notifier).load();
    await settle();
    expect(model()!.banner, isNull);
    removable.mounted = [];
    await container.read(removableControllerProvider.notifier).load();
    await settle();
    // The disk left, came back and left again: the banner returns.
    expect(model()!.banner, isNotNull);
  });
}
