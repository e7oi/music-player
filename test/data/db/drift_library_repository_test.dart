import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/data/db/drift_library_repository.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';

import '../../fakes/fake_library.dart';

void main() {
  late LibraryDatabase db;
  late DriftLibraryRepository repository;

  setUp(() async {
    db = LibraryDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = DriftLibraryRepository(db);
    await repository.ensureDisk(Disk.internal);
  });

  tearDown(() => db.close());

  Future<List<LibraryTrack>> tracks() => repository.watchTracks().first;

  group('disks and folders', () {
    test('an unknown disk is null', () async {
      expect(await repository.disk(const DiskId('other')), isNull);
    });

    /// @verifies FR-003
    test('choosing folders registers the disk in the same step', () async {
      const other = Disk(
        id: DiskId('other'),
        label: 'SSD',
        kind: DiskKind.removable,
      );

      await repository.setChosenFolders(other, {'Music'});

      expect(await repository.disk(other.id), isNotNull);
      expect(await repository.chosenFolders(other.id), {'Music'});
    });

    test('ensureDisk keeps the stored disk', () async {
      await repository.ensureDisk(Disk.internal);

      final disk = await repository.disk(internalDisk);
      expect(disk?.label, 'Local');
      expect(disk?.kind, DiskKind.internal);
    });

    /// @verifies FR-003
    test('chosen folders are replaced, not merged', () async {
      await repository.setChosenFolders(Disk.internal, {'Music', 'Podcasts'});
      await repository.setChosenFolders(Disk.internal, {'Music'});

      expect(await repository.chosenFolders(internalDisk), {'Music'});
    });
  });

  group('BR-004 applyIndex', () {
    /// @verifies BR-004
    test('adds the found tracks', () async {
      final result = await repository.applyIndex(internalDisk, [
        info('Music/b.mp3', title: 'B'),
        info('Music/a.mp3', title: 'A'),
      ]);

      expect(result.added, 2);
      expect((await tracks()).map((t) => t.displayTitle), ['A', 'B']);
    });

    /// @verifies BR-004
    test('keeps the id of a track whose information changed', () async {
      await repository.applyIndex(internalDisk, [
        info('Music/a.mp3', title: 'A'),
      ]);
      final before = (await tracks()).single;

      final result = await repository.applyIndex(internalDisk, [
        info('Music/a.mp3', title: 'A2', modified: 5),
      ]);

      final after = (await tracks()).single;
      expect(result.updated, 1);
      expect(after.id, before.id);
      expect(after.displayTitle, 'A2');
    });

    /// @verifies BR-004
    test('an unchanged track is neither updated nor re-created', () async {
      await repository.applyIndex(internalDisk, [info('Music/a.mp3')]);

      final result = await repository.applyIndex(internalDisk, [
        info('Music/a.mp3'),
      ]);

      expect(result.added + result.updated + result.removed, 0);
    });

    /// @verifies BR-004
    test('a moved file is a new track and the old one is removed', () async {
      await repository.applyIndex(internalDisk, [info('Music/a.mp3')]);
      final before = (await tracks()).single;

      final result = await repository.applyIndex(internalDisk, [
        info('Music/x/a.mp3'),
      ]);

      final after = (await tracks()).single;
      expect(result.added, 1);
      expect(result.removed, 1);
      expect(after.id, isNot(before.id));
    });

    test('keeps every field of the track information', () async {
      final full = TrackInfo(
        relativePath: 'Music/a.flac',
        size: 123,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        title: 'T',
        artist: 'Ar',
        album: 'Al',
        albumArtist: 'AA',
        trackNumber: 3,
        discNumber: 2,
        year: 1999,
        genre: 'G',
        duration: const Duration(milliseconds: 180500),
      );

      await repository.applyIndex(internalDisk, [full]);

      expect((await tracks()).single.info, full);
      expect((await tracks()).single.disk, internalDisk);
    });

    test('a duplicate path in one index is stored once', () async {
      await repository.applyIndex(internalDisk, [
        info('Music/a.mp3'),
        info('Music/a.mp3'),
      ]);

      expect(await tracks(), hasLength(1));
    });

    test('only touches the tracks of the given disk', () async {
      const other = Disk(
        id: DiskId('other'),
        label: 'SSD',
        kind: DiskKind.removable,
      );
      await repository.ensureDisk(other);
      await repository.applyIndex(other.id, [info('a.mp3')]);

      await repository.applyIndex(internalDisk, []);

      expect((await tracks()).single.disk, other.id);
    });

    test('an index of an unregistered disk fails', () async {
      expect(
        () => repository.applyIndex(const DiskId('nope'), []),
        throwsStateError,
      );
    });

    test('watchTracks emits after each index', () async {
      final emissions = <int>[];
      final sub = repository.watchTracks().listen(
        (t) => emissions.add(t.length),
      );
      await pumpEventQueue();
      await repository.applyIndex(internalDisk, [info('Music/a.mp3')]);
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions, [0, 1]);
    });
  });

  group('removable disk (ADR-008)', () {
    const ssd = DiskId('1234-ABCD');
    const disk = Disk(id: ssd, label: 'SSD', kind: DiskKind.removable);

    Future<LibraryTrack> only() async => (await tracks()).single;

    setUp(() => repository.ensureDisk(disk));

    test('disks lists every registered disk', () async {
      expect((await repository.disks()).map((d) => d.id), [internalDisk, ssd]);
    });

    /// @verifies FR-006.8
    test(
      'applyScan adds, keeps unchanged files and removes the others',
      () async {
        await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
        final idOfA = (await tracks())
            .firstWhere((t) => t.info.relativePath == 'a.mp3')
            .id;

        final result = await repository.applyScan(ssd, [
          info('a.mp3'),
          info('c.mp3'),
        ]);

        expect((result.added, result.updated, result.removed), (1, 0, 1));
        final byPath = {
          for (final t in await tracks()) t.info.relativePath: t.id,
        };
        expect(byPath.keys, {'a.mp3', 'c.mp3'});
        expect(byPath['a.mp3'], idOfA);
      },
    );

    /// @verifies FR-006.8
    test('applyScan keeps the tags of an unchanged file', () async {
      await repository.applyScan(ssd, [info('a.mp3')]);
      final id = (await only()).id;
      await repository.applyFileTags([
        TagUpdate.read(
          id,
          const FileTags(title: 'A', artwork: 'art1'),
          writeTags: true,
        ),
      ]);

      await repository.applyScan(ssd, [info('a.mp3')]);

      final track = await only();
      expect(track.info.title, 'A');
      expect(track.artwork, 'art1');
      expect(track.tagsState, TagsState.done);
    });

    /// @verifies FR-006.8
    test(
      'applyScan marks a changed file pending and keeps its old tags',
      () async {
        await repository.applyScan(ssd, [info('a.mp3')]);
        final id = (await only()).id;
        await repository.applyFileTags([
          TagUpdate.read(id, const FileTags(title: 'A'), writeTags: true),
        ]);

        final result = await repository.applyScan(ssd, [
          info('a.mp3', size: 5000),
        ]);

        expect(result.updated, 1);
        final track = await only();
        expect(track.info.title, 'A');
        expect(track.info.size, 5000);
        expect(track.tagsState, TagsState.pending);
      },
    );

    /// @verifies FR-007.3
    test(
      'pendingTracks only lists the pending tracks of the given disks',
      () async {
        await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
        await repository.applyIndex(internalDisk, [info('Music/i.mp3')]);
        final a = (await tracks()).firstWhere(
          (t) => t.info.relativePath == 'a.mp3',
        );
        await repository.applyFileTags([TagUpdate.failed(a.id)]);

        final pending = await repository.pendingTracks({ssd}, 10);

        expect(pending.map((p) => p.track.relativePath), ['b.mp3']);
        expect(pending.single.track.disk, ssd);
        expect(await repository.countPending({ssd}), 1);
        expect(await repository.countPending({ssd, internalDisk}), 2);
        expect(
          await repository.pendingTracks({ssd, internalDisk}, 1),
          hasLength(1),
        );
      },
    );

    /// @verifies FR-007.1
    test('applyFileTags stores every tag of a removable track', () async {
      await repository.applyScan(ssd, [info('a.mp3')]);

      await repository.applyFileTags([
        TagUpdate.read(
          (await only()).id,
          const FileTags(
            title: 'T',
            artist: 'Ar',
            album: 'Al',
            albumArtist: 'AA',
            trackNumber: 3,
            discNumber: 2,
            year: 1999,
            genre: 'G',
            duration: Duration(seconds: 61),
            artwork: 'art1',
          ),
          writeTags: true,
        ),
      ]);

      final track = await only();
      expect(track.info.title, 'T');
      expect(track.info.artist, 'Ar');
      expect(track.info.album, 'Al');
      expect(track.info.albumArtist, 'AA');
      expect(track.info.trackNumber, 3);
      expect(track.info.discNumber, 2);
      expect(track.info.year, 1999);
      expect(track.info.genre, 'G');
      expect(track.info.duration, const Duration(seconds: 61));
      expect(track.artwork, 'art1');
      expect(track.tagsState, TagsState.done);
    });

    /// @verifies FR-007.2
    test(
      'applyFileTags with writeTags false only stores the artwork',
      () async {
        await repository.applyIndex(internalDisk, [
          info('Music/i.mp3', title: 'MediaStore'),
        ]);
        final id = (await only()).id;

        await repository.applyFileTags([
          TagUpdate.read(
            id,
            const FileTags(title: 'File', artwork: 'art1'),
            writeTags: false,
          ),
        ]);

        final track = await only();
        expect(track.info.title, 'MediaStore');
        expect(track.artwork, 'art1');
      },
    );

    /// @verifies FR-007.5
    test('a failed update marks the track failed and keeps its data', () async {
      await repository.applyScan(ssd, [info('a.mp3')]);

      await repository.applyFileTags([TagUpdate.failed((await only()).id)]);

      expect((await only()).tagsState, TagsState.failed);
    });

    /// @verifies FR-007.8
    test(
      'a changed internal file is read again, an unchanged one is not',
      () async {
        await repository.applyIndex(internalDisk, [info('Music/i.mp3')]);
        final id = (await only()).id;
        await repository.applyFileTags([
          TagUpdate.read(id, const FileTags(artwork: 'art1'), writeTags: false),
        ]);

        await repository.applyIndex(internalDisk, [
          info('Music/i.mp3', title: 'New tag only'),
        ]);
        expect((await only()).tagsState, TagsState.done);
        expect((await only()).artwork, 'art1');

        await repository.applyIndex(internalDisk, [
          info('Music/i.mp3', title: 'New tag only', size: 9),
        ]);
        expect((await only()).tagsState, TagsState.pending);
      },
    );

    /// @verifies FR-007.10
    test(
      'artworkInUse lists each identifier once and none after removal',
      () async {
        await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
        await repository.applyFileTags([
          for (final t in await tracks())
            TagUpdate.read(
              t.id,
              const FileTags(artwork: 'art1'),
              writeTags: true,
            ),
        ]);
        expect(await repository.artworkInUse(), {'art1'});

        await repository.applyScan(ssd, const []);

        expect(await repository.artworkInUse(), isEmpty);
      },
    );

    /// @verifies FR-007.3
    test(
      'resetFailedTags puts the failed tracks of the disks back to pending',
      () async {
        await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
        await repository.applyIndex(internalDisk, [info('Music/i.mp3')]);
        await repository.applyFileTags([
          for (final t in await tracks()) TagUpdate.failed(t.id),
        ]);

        await repository.resetFailedTags({ssd});

        final byDisk = {
          for (final t in await tracks()) t.info.relativePath: t.tagsState,
        };
        expect(byDisk['a.mp3'], TagsState.pending);
        expect(byDisk['b.mp3'], TagsState.pending);
        expect(byDisk['Music/i.mp3'], TagsState.failed);
      },
    );

    test('trackCount counts the tracks of one disk', () async {
      await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
      await repository.applyIndex(internalDisk, [info('Music/i.mp3')]);

      expect(await repository.trackCount(ssd), 2);
      expect(await repository.trackCount(internalDisk), 1);
      expect(await repository.trackCount(const DiskId('nope')), 0);
    });

    /// @verifies FR-006.4
    test('setChosenFolders renames the disk', () async {
      await repository.setChosenFolders(
        const Disk(id: ssd, label: 'Renamed', kind: DiskKind.removable),
        {'Music'},
      );

      expect((await repository.disk(ssd))?.label, 'Renamed');
    });
  });
}
