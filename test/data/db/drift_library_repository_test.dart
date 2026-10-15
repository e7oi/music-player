import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/data/db/drift_library_repository.dart';
import 'package:musicplayer/data/db/library_database.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/model/track.dart';

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

    test('ensureDisk keeps the stored disk', () async {
      await repository.ensureDisk(Disk.internal);

      final disk = await repository.disk(internalDisk);
      expect(disk?.label, 'Local');
      expect(disk?.kind, DiskKind.internal);
    });

    /// @verifies FR-003
    test('chosen folders are replaced, not merged', () async {
      await repository.setChosenFolders(internalDisk, {'Music', 'Podcasts'});
      await repository.setChosenFolders(internalDisk, {'Music'});

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
}
