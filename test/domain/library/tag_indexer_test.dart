import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
import 'package:tuneshell/domain/library/services/tag_indexer.dart';

import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

void main() {
  const ssd = DiskId('1234-ABCD');
  late FakeLibraryRepository repository;
  late FakeTagReader reader;
  late FakeVolumeEvents volumes;
  late TagIndexer indexer;

  Track ssdTrack(String name) => Track(disk: ssd, relativePath: name);

  setUp(() async {
    repository = FakeLibraryRepository();
    reader = FakeTagReader();
    volumes = FakeVolumeEvents({internalDisk, ssd});
    indexer = TagIndexer(
      repository: repository,
      reader: reader,
      volumes: volumes,
      batchSize: 2,
    );
    await repository.ensureDisk(Disk.internal);
    await repository.ensureDisk(
      const Disk(id: ssd, label: 'SSD', kind: DiskKind.removable),
    );
  });

  /// @verifies FR-007.1
  test('stores the tags and artwork of the removable tracks', () async {
    await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
    reader.tags[ssdTrack('a.mp3')] = const FileTags(
      title: 'A',
      artist: 'X',
      artwork: 'art1',
    );
    reader.tags[ssdTrack('b.mp3')] = const FileTags(title: 'B');

    await indexer.run();

    final byPath = {for (final t in repository.tracks) t.info.relativePath: t};
    expect(byPath['a.mp3']?.info.title, 'A');
    expect(byPath['a.mp3']?.info.artist, 'X');
    expect(byPath['a.mp3']?.artwork, 'art1');
    expect(byPath['b.mp3']?.artwork, isNull);
    expect(
      repository.tracks.every((t) => t.tagsState == TagsState.done),
      isTrue,
    );
  });

  /// @verifies FR-007.2
  test('keeps the MediaStore tags of the internal storage', () async {
    await repository.applyIndex(internalDisk, [
      info('Music/a.mp3', title: 'From MediaStore'),
    ]);
    reader.tags[const Track(disk: internalDisk, relativePath: 'Music/a.mp3')] =
        const FileTags(title: 'From file', artwork: 'art1');

    await indexer.run();

    final track = repository.tracks.single;
    expect(track.info.title, 'From MediaStore');
    expect(track.artwork, 'art1');
    expect(track.tagsState, TagsState.done);
  });

  /// @verifies FR-007.5
  test('an unreadable file fails alone and the run goes on', () async {
    await repository.applyScan(ssd, [
      info('a.mp3'),
      info('b.mp3'),
      info('c.mp3'),
    ]);
    reader.throwing.add(ssdTrack('a.mp3'));
    reader.tags[ssdTrack('c.mp3')] = const FileTags(title: 'C');

    await indexer.run();

    final states = {
      for (final t in repository.tracks) t.info.relativePath: t.tagsState,
    };
    expect(states, {
      'a.mp3': TagsState.failed,
      'b.mp3': TagsState.failed,
      'c.mp3': TagsState.done,
    });
  });

  /// @verifies FR-007.3
  test('a failed track is not read again by the next run', () async {
    await repository.applyScan(ssd, [info('a.mp3')]);

    await indexer.run();
    reader.reads.clear();
    await indexer.run();

    expect(reader.reads, isEmpty);
  });

  /// @verifies FR-007.4
  test('a second run reads only what is still pending', () async {
    await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
    reader.tags[ssdTrack('a.mp3')] = const FileTags(title: 'A');
    reader.tags[ssdTrack('b.mp3')] = const FileTags(title: 'B');
    await indexer.run();
    await repository.applyScan(ssd, [
      info('a.mp3'),
      info('b.mp3'),
      info('c.mp3'),
    ]);
    reader.reads.clear();

    await indexer.run();

    expect(reader.reads, [ssdTrack('c.mp3')]);
  });

  /// @verifies FR-006.8 a changed file is read again.
  test('a changed file is read again', () async {
    await repository.applyScan(ssd, [info('a.mp3')]);
    await indexer.run();
    reader.reads.clear();

    await repository.applyScan(ssd, [info('a.mp3', size: 2000)]);
    await indexer.run();

    expect(reader.reads, [ssdTrack('a.mp3')]);
  });

  /// @verifies BR-006.4
  test('never reads more files at once than the limit', () async {
    await repository.applyScan(ssd, [
      for (var i = 0; i < 9; i++) info('$i.mp3'),
    ]);

    await indexer.run();

    expect(reader.maxActive, lessThanOrEqualTo(2));
    expect(reader.reads, hasLength(9));
  });

  test('skips the tracks of an absent disk', () async {
    await repository.applyScan(ssd, [info('a.mp3')]);
    final away = TagIndexer(
      repository: repository,
      reader: reader,
      volumes: FakeVolumeEvents({internalDisk}),
    );

    await away.run();

    expect(reader.reads, isEmpty);
    expect(repository.tracks.single.tagsState, TagsState.pending);
  });

  /// @verifies BR-006.5
  /// @verifies BR-006.6
  test('cancel stops after the files in flight and loses nothing', () async {
    await repository.applyScan(ssd, [
      for (var i = 0; i < 8; i++) info('$i.mp3'),
    ]);
    reader.onRead = (_) {
      if (reader.reads.length == 3) indexer.cancel();
    };

    await indexer.run();

    final done = repository.tracks.where(
      (t) => t.tagsState != TagsState.pending,
    );
    expect(done.length, inInclusiveRange(3, 4));
    expect(reader.retained, isNull);

    reader.onRead = null;
    await indexer.run();
    expect(
      repository.tracks.every((t) => t.tagsState != TagsState.pending),
      isTrue,
    );
  });

  /// @verifies FR-007.9 progress is reported.
  test('reports progress and ends idle', () async {
    await repository.applyScan(ssd, [
      for (var i = 0; i < 5; i++) info('$i.mp3'),
    ]);
    final seen = <TagProgress>[];
    final sub = indexer.progressStream.listen(seen.add);

    await indexer.run();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.first.total, 5);
    expect(seen.map((p) => p.done), containsAllInOrder([0, 2, 4, 5]));
    expect(seen.last.running, isFalse);
  });

  /// @verifies FR-007.10
  test('keeps only the artwork still used', () async {
    await repository.applyScan(ssd, [info('a.mp3')]);
    reader.tags[ssdTrack('a.mp3')] = const FileTags(artwork: 'art1');

    await indexer.run();

    expect(reader.retained, {'art1'});
  });

  test('a run while another is going joins it', () async {
    await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);

    await Future.wait([indexer.run(), indexer.run()]);

    expect(reader.reads, hasLength(2));
  });

  /// @verifies FR-007.3 a disk that went away says nothing about the files.
  test('a lost access leaves the tracks pending and ends the pass', () async {
    await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
    reader.accessLost.add(ssdTrack('a.mp3'));
    final serial = TagIndexer(
      repository: repository,
      reader: reader,
      volumes: volumes,
      parallelism: 1,
    );

    await serial.run();

    expect(
      repository.tracks.every((t) => t.tagsState == TagsState.pending),
      isTrue,
    );
    expect(reader.retained, isNull);
  });

  /// @verifies BR-006.6
  test(
    'a read that fails because the disk was unplugged stays pending',
    () async {
      await repository.applyScan(ssd, [info('a.mp3'), info('b.mp3')]);
      reader.throwing.add(ssdTrack('a.mp3'));
      volumes.available = {internalDisk};
      final start = FakeVolumeEvents({internalDisk, ssd});
      final unplugging = TagIndexer(
        repository: repository,
        reader: reader,
        volumes: start,
        parallelism: 1,
      );
      reader.onRead = (_) => start.available = {internalDisk};

      await unplugging.run();

      expect(
        repository.tracks.every((t) => t.tagsState == TagsState.pending),
        isTrue,
      );
    },
  );

  /// @verifies FR-007.3 only an explicit refresh retries the failed files.
  test('retryFailed gives the unreadable files another pass', () async {
    await repository.applyScan(ssd, [info('a.mp3')]);
    await indexer.run();
    reader
      ..reads.clear()
      ..tags[ssdTrack('a.mp3')] = const FileTags(title: 'A');

    await indexer.run();
    expect(reader.reads, isEmpty);

    await indexer.run(retryFailed: true);
    expect(reader.reads, [ssdTrack('a.mp3')]);
    expect(repository.tracks.single.tagsState, TagsState.done);
  });

  test('a failing store ends idle', () async {
    final broken = TagIndexer(
      repository: _BrokenStore(repository),
      reader: reader,
      volumes: volumes,
    );
    await repository.applyScan(ssd, [info('a.mp3')]);

    await expectLater(broken.run(), throwsException);

    expect(broken.progress.running, isFalse);
  });
}

class _BrokenStore extends FakeLibraryRepository {
  new(this._inner);

  final FakeLibraryRepository _inner;

  @override
  Future<int> countPending(Set<DiskId> disks) => _inner.countPending(disks);

  @override
  Future<List<PendingTrack>> pendingTracks(Set<DiskId> disks, int limit) =>
      _inner.pendingTracks(disks, limit);

  @override
  Future<void> applyFileTags(List<TagUpdate> updates) =>
      throw Exception('disk full');
}
