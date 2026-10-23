import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';

import '../../fakes/fake_library.dart';

void main() {
  const ssd = DiskId('1234-ABCD');
  const music = RemovableFolder(disk: ssd, diskLabel: 'SSD', path: 'Music');
  late FakeLibraryRepository repository;
  late FakeRemovableAudioSource source;
  late RemovableIndexer indexer;

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeRemovableAudioSource()
      ..mounted = [const MountedVolume(id: ssd, label: 'SSD')]
      ..granted = {music}
      ..picked = music
      ..files[(ssd, 'Music')] = [info('Music/a.mp3'), info('Music/b.mp3')];
    indexer = RemovableIndexer(repository: repository, source: source);
  });

  /// @verifies FR-006.1
  /// @verifies FR-006.7
  group('adding a folder', () {
    test('registers the disk and its tracks without tags', () async {
      expect(await indexer.addFolder(), AddFolderResult.added);

      final disk = await repository.disk(ssd);
      expect(disk?.kind, DiskKind.removable);
      expect(disk?.label, 'SSD');
      expect(await repository.chosenFolders(ssd), {'Music'});
      expect(repository.tracks.map((t) => t.info.relativePath), [
        'Music/a.mp3',
        'Music/b.mp3',
      ]);
      expect(repository.tracks.every((t) => t.info.title == null), isTrue);
    });

    test('a cancelled picker changes nothing', () async {
      source.picked = null;

      expect(await indexer.addFolder(), AddFolderResult.cancelled);
      expect(await repository.disk(ssd), isNull);
    });

    /// UC-003, 2b.
    test(
      'a folder without audio registers nothing and gives up access',
      () async {
        source.files[(ssd, 'Music')] = [];

        expect(await indexer.addFolder(), AddFolderResult.noAudio);
        expect(await repository.disk(ssd), isNull);
        expect(source.released, [(ssd, 'Music')]);
      },
    );

    test('a second folder joins the first and keeps its tracks', () async {
      await indexer.addFolder();
      source
        ..picked = const RemovableFolder(
          disk: ssd,
          diskLabel: 'SSD',
          path: 'Jazz',
        )
        ..files[(ssd, 'Jazz')] = [info('Jazz/c.mp3')];

      await indexer.addFolder();

      expect(await repository.chosenFolders(ssd), {'Music', 'Jazz'});
      expect(repository.tracks, hasLength(3));
    });

    test('a failed scan registers nothing', () async {
      source.failing[(ssd, 'Music')] = Exception('unplugged');

      await expectLater(indexer.addFolder(), throwsException);
      expect(await repository.disk(ssd), isNull);
    });
  });

  group('refreshing', () {
    setUp(() => indexer.addFolder());

    /// @verifies BR-004 the id of a file still there is kept.
    test('adds, removes and keeps identities', () async {
      final before = {
        for (final t in repository.tracks) t.info.relativePath: t.id,
      };
      source.files[(ssd, 'Music')] = [info('Music/a.mp3'), info('Music/c.mp3')];

      await indexer.refreshAll();

      final after = {
        for (final t in repository.tracks) t.info.relativePath: t.id,
      };
      expect(after.keys, {'Music/a.mp3', 'Music/c.mp3'});
      expect(after['Music/a.mp3'], before['Music/a.mp3']);
    });

    /// @verifies FR-006.9
    test('a failed scan deletes nothing', () async {
      source.failing[(ssd, 'Music')] = Exception('io error');

      await expectLater(indexer.refreshAll(), throwsException);
      expect(repository.tracks, hasLength(2));
    });

    /// @verifies FR-006.9
    test('an empty scan of a disk that has tracks is an error', () async {
      source.files[(ssd, 'Music')] = [];

      await expectLater(
        indexer.refreshAll(),
        throwsA(isA<EmptySourceException>()),
      );
      expect(repository.tracks, hasLength(2));
    });

    /// @verifies FR-006.10
    test('an absent disk is not scanned and keeps its tracks', () async {
      source
        ..mounted = []
        ..scanned.clear();

      await indexer.refreshAll();

      expect(source.scanned, isEmpty);
      expect(repository.tracks, hasLength(2));
    });

    /// @verifies FR-006.11
    test('a lost access is not scanned and keeps its tracks', () async {
      source
        ..granted = {}
        ..scanned.clear();

      await indexer.refreshAll();

      expect(source.scanned, isEmpty);
      expect(repository.tracks, hasLength(2));
    });

    test('one failing disk does not stop another', () async {
      const other = DiskId('9999-FFFF');
      source
        ..mounted = [
          const MountedVolume(id: ssd, label: 'SSD'),
          const MountedVolume(id: other, label: 'Other'),
        ]
        ..picked = const RemovableFolder(
          disk: other,
          diskLabel: 'Other',
          path: '',
        )
        ..granted = {
          music,
          const RemovableFolder(disk: other, diskLabel: 'Other', path: ''),
        }
        ..files[(other, '')] = [info('x.mp3')];
      await indexer.addFolder();
      source
        ..failing[(ssd, 'Music')] = Exception('io error')
        ..files[(other, '')] = [info('x.mp3'), info('y.mp3')];

      await expectLater(indexer.refreshAll(), throwsException);

      expect(repository.tracks.where((t) => t.disk == other), hasLength(2));
    });
  });

  group('disk state', () {
    setUp(() => indexer.addFolder());

    test('available when mounted and granted', () async {
      expect((await indexer.disks()).single.status, RemovableStatus.available);
    });

    test('absent when not mounted', () async {
      source.mounted = [];

      expect((await indexer.disks()).single.status, RemovableStatus.absent);
    });

    /// @verifies FR-006.11
    test('access lost when mounted without a grant', () async {
      source.granted = {};

      expect((await indexer.disks()).single.status, RemovableStatus.accessLost);
    });

    test('a granted parent folder covers its subfolders', () async {
      source.granted = {
        const RemovableFolder(disk: ssd, diskLabel: 'SSD', path: ''),
      };

      expect((await indexer.disks()).single.status, RemovableStatus.available);
    });

    test(
      'a granted folder does not cover a sibling with a common prefix',
      () async {
        source.granted = {
          const RemovableFolder(disk: ssd, diskLabel: 'SSD', path: 'Mus'),
        };

        expect(
          (await indexer.disks()).single.status,
          RemovableStatus.accessLost,
        );
      },
    );
  });

  group('removing a folder', () {
    test('drops its tracks, keeps the others, gives up the access', () async {
      await indexer.addFolder();
      source
        ..picked = const RemovableFolder(
          disk: ssd,
          diskLabel: 'SSD',
          path: 'Jazz',
        )
        ..files[(ssd, 'Jazz')] = [info('Jazz/c.mp3')];
      await indexer.addFolder();

      await indexer.removeFolder(ssd, 'Jazz');

      expect(repository.tracks.map((t) => t.info.relativePath), [
        'Music/a.mp3',
        'Music/b.mp3',
      ]);
      expect(await repository.chosenFolders(ssd), {'Music'});
      expect(source.released, [(ssd, 'Jazz')]);
    });

    test(
      'removing the last folder empties the disk without an error',
      () async {
        await indexer.addFolder();

        await indexer.removeFolder(ssd, 'Music');

        expect(repository.tracks, isEmpty);
        expect(source.released, [(ssd, 'Music')]);
      },
    );
  });

  test('cancel reaches the source', () async {
    await indexer.cancel();

    expect(source.cancels, 1);
  });

  test('a track keeps its tags state pending until read', () async {
    await indexer.addFolder();

    expect(
      repository.tracks.every((t) => t.tagsState == TagsState.pending),
      isTrue,
    );
  });

  /// @verifies FR-006.2 renewing a used folder now empty keeps its access.
  test('an empty folder already chosen keeps its access', () async {
    await indexer.addFolder();
    source.files[(ssd, 'Music')] = [];

    expect(await indexer.addFolder(), AddFolderResult.noAudio);

    expect(source.released, isEmpty);
    expect(await repository.chosenFolders(ssd), {'Music'});
  });

  /// @verifies FR-006.2 nothing changes if the scan fails.
  test('removing a folder is all or nothing', () async {
    await indexer.addFolder();
    source
      ..picked = const RemovableFolder(
        disk: ssd,
        diskLabel: 'SSD',
        path: 'Jazz',
      )
      ..files[(ssd, 'Jazz')] = [info('Jazz/c.mp3')];
    await indexer.addFolder();
    source.failing[(ssd, 'Music')] = Exception('io error');

    await expectLater(indexer.removeFolder(ssd, 'Jazz'), throwsException);

    expect(await repository.chosenFolders(ssd), {'Music', 'Jazz'});
    expect(repository.tracks, hasLength(3));
    expect(source.released, isEmpty);
  });

  /// @verifies BR-006.5 a stop ends the whole refresh.
  test('a cancelled scan does not go on with the next disk', () async {
    const other = DiskId('9999-FFFF');
    await indexer.addFolder();
    source
      ..mounted = [
        const MountedVolume(id: ssd, label: 'SSD'),
        const MountedVolume(id: other, label: 'Other'),
      ]
      ..picked = const RemovableFolder(
        disk: other,
        diskLabel: 'Other',
        path: '',
      )
      ..granted = {
        music,
        const RemovableFolder(disk: other, diskLabel: 'Other', path: ''),
      }
      ..files[(other, '')] = [info('x.mp3')];
    await indexer.addFolder();
    source
      ..scanned.clear()
      ..failing[(ssd, 'Music')] = const ScanCancelledException();

    await expectLater(
      indexer.refreshAll(),
      throwsA(isA<ScanCancelledException>()),
    );

    expect(source.scanned, [(ssd, 'Music')]);
  });

  /// @verifies FR-006.4 the name Android gives the volume is kept up to date.
  test('a renamed volume updates the label', () async {
    await indexer.addFolder();
    source.picked = const RemovableFolder(
      disk: ssd,
      diskLabel: 'Renamed',
      path: 'Music',
    );

    await indexer.addFolder();

    expect((await repository.disk(ssd))?.label, 'Renamed');
  });
}
