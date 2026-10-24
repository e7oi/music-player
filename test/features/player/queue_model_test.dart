import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/player/queue_model.dart';

const ssd = DiskId('ssd');

LibraryTrack library(
  String name, {
  DiskId disk = internalDisk,
  String? artist,
  int? seconds,
  String? title,
}) => LibraryTrack(
  id: name.hashCode,
  disk: disk,
  info: TrackInfo(
    relativePath: '$name.mp3',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
    artist: artist,
    duration: seconds == null ? null : Duration(seconds: seconds),
  ),
);

QueueModel build(
  List<LibraryTrack> tracks, {
  int? current,
  Set<DiskId> available = const {internalDisk, ssd},
  Iterable<LibraryTrack> known = const [],
}) => QueueModel.build(
  queue: [for (final t in tracks) t.track],
  currentIndex: current,
  lookup: {
    for (final t in [...tracks, ...known]) t.track: t,
  },
  disks: const [
    Disk.internal,
    Disk(id: ssd, label: 'T7 Shield', kind: DiskKind.removable, markIndex: 0),
  ],
  availableDisks: available,
);

void main() {
  /// @verifies FR-018.2
  group('QueueModel header', () {
    test('counts the whole queue and adds the known durations', () {
      final model = build([
        library('a', seconds: 60),
        library('b'),
        library('c', seconds: 125),
      ], current: 0);

      expect(model.total, 3);
      expect(model.totalDuration, const Duration(seconds: 185));
    });

    test('an empty queue is empty', () {
      final model = build(const []);

      expect(model.total, 0);
      expect(model.current, isNull);
      expect(model.upcomingCount, 0);
    });
  });

  /// @verifies FR-018.3
  /// @verifies FR-018.4
  group('QueueModel rows', () {
    test('the current track is apart; the upcoming ones follow it', () {
      final model = build([
        library('a'),
        library('b', title: 'Bee'),
        library('c'),
        library('d'),
      ], current: 1);

      expect(model.current!.title, 'Bee');
      expect(model.current!.queueIndex, 1);
      expect(model.upcomingCount, 2);
      expect(model.upcoming(0).title, 'c.mp3');
      expect(model.upcoming(0).queueIndex, 2);
      expect(model.upcoming(1).queueIndex, 3);
    });

    test('rows carry artist, duration, disk and cover', () {
      final track = LibraryTrack(
        id: 1,
        disk: ssd,
        artwork: 'cov',
        info: TrackInfo(
          relativePath: 'x.flac',
          size: 1,
          modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
          artist: 'Clara',
          duration: const Duration(seconds: 90),
        ),
      );
      final model = build([library('a'), track], current: 0);

      final row = model.upcoming(0);

      expect(row.artist, 'Clara');
      expect(row.duration, const Duration(seconds: 90));
      expect(row.disk!.label, 'T7 Shield');
      expect(row.artwork, 'cov');
      expect(row.available, isTrue);
    });

    test('a track of an absent disk is unavailable', () {
      final model = build(
        [library('a'), library('b', disk: ssd)],
        current: 0,
        available: {internalDisk},
      );

      expect(model.upcoming(0).available, isFalse);
      expect(model.upcoming(0).disk!.label, 'T7 Shield');
      expect(model.current!.available, isTrue);
    });

    test('a track the library lost still has a row', () {
      final lost = library('gone');
      final model = QueueModel.build(
        queue: [library('a').track, lost.track],
        currentIndex: 0,
        lookup: {library('a').track: library('a')},
        disks: const [Disk.internal],
        availableDisks: const {internalDisk},
      );

      expect(model.upcoming(0).title, 'gone.mp3');
      expect(model.upcoming(0).artist, isNull);
      expect(model.upcoming(0).duration, isNull);
    });

    test('the last track has no upcoming one', () {
      final model = build([library('a'), library('b')], current: 1);

      expect(model.upcomingCount, 0);
    });

    test('the past tracks are not listed', () {
      final model = build([
        library('a'),
        library('b'),
        library('c'),
      ], current: 2);

      expect(model.total, 3);
      expect(model.upcomingCount, 0);
    });
  });

  /// @verifies FR-018.10
  test('a queue of 7 500 tracks is read without building every row', () {
    final tracks = [
      for (var i = 0; i < 7500; i++) library('t$i', seconds: 200),
    ];
    final watch = Stopwatch()..start();

    final model = build(tracks, current: 10);

    expect(model.total, 7500);
    expect(model.upcomingCount, 7489);
    expect(model.totalDuration, const Duration(seconds: 1500000));
    expect(model.upcoming(7488).queueIndex, 7499);
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
