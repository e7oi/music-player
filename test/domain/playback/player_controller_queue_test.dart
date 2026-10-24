import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/engine_issue.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');
const ssd = DiskId('ssd');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late FakeTrackSourceOpener opener;
  late PlayerController controller;
  late List<PlaybackNotice> notices;

  final a = t('a');
  final b = t('b');
  final c = t('c');
  final d = t('d');
  final e = t('e');

  Future<void> settle() => pumpEventQueue();

  String? loadedPath() {
    final source = engine.loadedSource;
    return source is FileMediaSource ? source.path : null;
  }

  String pathOf(Track track) => '${track.disk.value}/${track.relativePath}';

  List<Track> many(int count) => [for (var i = 0; i < count; i++) t('t$i')];

  Future<void> createController({
    Set<DiskId> available = const {internal, ssd},
  }) async {
    engine = FakeAudioEngine();
    opener = FakeTrackSourceOpener();
    controller = PlayerController(
      engine: engine,
      opener: opener,
      volumes: FakeVolumeEvents(available),
      random: Random(7),
    );
    notices = [];
    controller.notices.listen(notices.add);
    await controller.start();
  }

  setUp(createController);

  tearDown(() => controller.dispose());

  /// @verifies BR-009
  group('BR-009 shuffle', () {
    test(
      'rule 1: keeps the current track and mixes only what follows',
      () async {
        final tracks = many(50);
        await controller.setQueue(tracks, startIndex: 10);

        await controller.setShuffle(enabled: true);

        final queue = controller.state.queue;
        expect(controller.state.shuffle, isTrue);
        expect(controller.state.currentIndex, 10);
        expect(queue.sublist(0, 11), tracks.sublist(0, 11));
        expect(queue.sublist(11), isNot(tracks.sublist(11)));
        expect(queue.sublist(11), unorderedEquals(tracks.sublist(11)));
      },
    );

    test('rule 1: the engine is not touched', () async {
      await controller.setQueue(many(5));
      await controller.play();
      final calls = [...engine.calls];

      await controller.setShuffle(enabled: true);

      expect(engine.calls, calls);
      expect(controller.state.status, PlayerStatus.ready);
    });

    test('rule 2: turning it off restores the original order', () async {
      final tracks = many(30);
      await controller.setQueue(tracks, startIndex: 4);
      await controller.setShuffle(enabled: true);
      await controller.move(10, 20);

      await controller.setShuffle(enabled: false);

      expect(controller.state.shuffle, isFalse);
      expect(controller.state.queue, tracks);
      expect(controller.state.currentIndex, 4);
    });

    test('rule 2: follows the current track when it moved on', () async {
      final tracks = many(30);
      await controller.setQueue(tracks);
      await controller.play();
      await controller.setShuffle(enabled: true);
      await controller.next();
      final current = controller.state.currentTrack;

      await controller.setShuffle(enabled: false);

      expect(controller.state.currentTrack, current);
      expect(controller.state.currentIndex, tracks.indexOf(current!));
    });

    test('rule 2: tracks removed meanwhile stay removed', () async {
      final tracks = many(10);
      await controller.setQueue(tracks);
      await controller.setShuffle(enabled: true);
      final gone = controller.state.queue[5];
      await controller.removeAt(5);

      await controller.setShuffle(enabled: false);

      expect(controller.state.queue, [...tracks]..remove(gone));
    });

    test('rule 3: a new queue starts on the chosen track', () async {
      await controller.setShuffle(enabled: true);
      final tracks = many(30);

      await controller.setQueue(tracks, startIndex: 12);

      expect(controller.state.currentIndex, 0);
      expect(controller.state.currentTrack, tracks[12]);
      expect(controller.state.queue, unorderedEquals(tracks));
      expect(controller.state.queue, isNot(tracks));
      await controller.setShuffle(enabled: false);
      expect(controller.state.queue, tracks);
      expect(controller.state.currentTrack, tracks[12]);
    });

    test('rule 10: modes can be set on an empty queue', () async {
      await controller.setShuffle(enabled: true);
      await controller.setRepeat(RepeatMode.all);

      expect(controller.state.shuffle, isTrue);
      expect(controller.state.repeat, RepeatMode.all);
      expect(controller.state.status, PlayerStatus.idle);
    });

    test('shuffling a single track changes nothing', () async {
      await controller.setQueue([a]);

      await controller.setShuffle(enabled: true);

      expect(controller.state.queue, [a]);
      expect(controller.state.currentIndex, 0);
    });

    test('shuffling while stopped at the end keeps the track', () async {
      await controller.setQueue(many(10), startIndex: 9);
      await controller.play();
      engine.completeTrack();
      await settle();
      expect(controller.state.status, PlayerStatus.stopped);
      final opened = engine.opened.length;

      await controller.setShuffle(enabled: true);

      expect(controller.state.currentIndex, 9);
      expect(controller.state.status, PlayerStatus.stopped);
      expect(engine.opened.length, opened);
    });
  });

  /// @verifies BR-009
  group('BR-009 repeat', () {
    test('rule 4: all wraps to the first track at the end', () async {
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([a, b]);
      await controller.play();
      engine.completeTrack();
      await settle();

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 0);
      expect(loadedPath(), pathOf(a));
      expect(controller.state.playing, isTrue);
    });

    test('rule 4: all wraps on "next" from the last track', () async {
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([a, b], startIndex: 1);
      await controller.play();

      await controller.next();

      expect(controller.state.currentIndex, 0);
      expect(loadedPath(), pathOf(a));
    });

    test('rule 4: all skips unavailable tracks while wrapping', () async {
      await createController(available: {internal});
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([t('s', ssd), b, c], startIndex: 2);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
      expect(notices.whereType<TracksSkipped>().single.count, 1);
    });

    test('rule 4: all stops once when nothing is available', () async {
      await createController(available: {internal});
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([t('s1', ssd), t('s2', ssd)]);

      await controller.play();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(engine.opened, isEmpty);
      final skipped = notices.whereType<TracksSkipped>().single;
      expect(skipped.count, 2);
    });

    test('rule 4: all replays a one-track queue', () async {
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([a]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.status, PlayerStatus.ready);
      expect(engine.opened.length, 2);
    });

    test('rule 4: off still stops at the end of the queue', () async {
      await controller.setQueue([a]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
    });

    test('rule 4: one restarts the same track', () async {
      await controller.setRepeat(RepeatMode.one);
      await controller.setQueue([a, b]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 0);
      expect(engine.opened.length, 2);
      expect(loadedPath(), pathOf(a));
      expect(controller.state.playing, isTrue);
    });

    test('rule 4: one does not hold on an unavailable track', () async {
      await createController(available: {internal});
      await controller.setRepeat(RepeatMode.one);
      await controller.setQueue([t('s', ssd), b]);
      await controller.play();

      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
    });

    test('rule 4: one keeps its mode on next and previous', () async {
      await controller.setRepeat(RepeatMode.one);
      await controller.setQueue([a, b, c]);
      await controller.play();

      await controller.next();
      expect(controller.state.currentIndex, 1);
      engine.emitPosition(Duration.zero);
      await controller.previous();

      expect(controller.state.currentIndex, 0);
      expect(controller.state.repeat, RepeatMode.one);
    });

    test('rule 5: a failing track is not repeated', () async {
      await controller.setRepeat(RepeatMode.one);
      await controller.setQueue([a, b]);
      await controller.play();

      engine.emitIssue(
        const EngineFailure(EngineFailureKind.playbackFailed, 'x'),
      );
      await settle();

      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
    });

    test('rule 5: three failures in a row stop repeat all', () async {
      opener.failing.addAll([a, b, c, d]);
      await controller.setRepeat(RepeatMode.all);
      await controller.setQueue([a, b, c, d], startIndex: 2);

      await controller.play();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(notices.whereType<PlaybackStoppedAfterFailures>(), hasLength(1));
    });
  });

  /// @verifies BR-009
  group('BR-009 move', () {
    test('rule 6: moves a track inside the upcoming ones', () async {
      await controller.setQueue([a, b, c, d, e]);

      final moved = await controller.move(4, 2);

      expect(moved, isTrue);
      expect(controller.state.queue, [a, b, e, c, d]);
      expect(controller.state.currentIndex, 0);
    });

    test('rule 6: moves forward too', () async {
      await controller.setQueue([a, b, c, d, e]);

      await controller.move(1, 3);

      expect(controller.state.queue, [a, c, d, b, e]);
    });

    test('rule 6: the current track stays current', () async {
      await controller.setQueue([a, b, c, d], startIndex: 1);

      await controller.move(3, 2);

      expect(controller.state.currentTrack, b);
      expect(controller.state.currentIndex, 1);
    });

    test('rule 6: refuses the current track, the past and outside', () async {
      await controller.setQueue([a, b, c, d], startIndex: 1);
      final before = controller.state.queue;

      expect(await controller.move(1, 3), isFalse);
      expect(await controller.move(0, 2), isFalse);
      expect(await controller.move(2, 1), isFalse);
      expect(await controller.move(2, 4), isFalse);
      expect(await controller.move(-1, 2), isFalse);
      expect(await controller.move(9, 2), isFalse);

      expect(controller.state.queue, before);
    });
  });

  /// @verifies BR-009
  group('BR-009 clear the upcoming tracks', () {
    test('rule 7: keeps the current track and what came before', () async {
      await controller.setQueue([a, b, c, d], startIndex: 1);
      await controller.play();

      await controller.clearUpcoming();

      expect(controller.state.queue, [a, b]);
      expect(controller.state.currentIndex, 1);
      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isTrue);
    });

    test('rule 7: playback stops at the end of the current track', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();
      await controller.clearUpcoming();

      engine.completeTrack();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
    });

    test('rule 7: nothing to clear changes nothing', () async {
      await controller.setQueue([a, b], startIndex: 1);
      final states = <PlayerState>[];
      controller.states.listen(states.add);

      await controller.clearUpcoming();
      await settle();

      expect(controller.state.queue, [a, b]);
      expect(states, isEmpty);
    });

    test('rule 7: also drops them from the original order', () async {
      final tracks = many(10);
      await controller.setQueue(tracks, startIndex: 2);
      await controller.setShuffle(enabled: true);
      await controller.clearUpcoming();

      await controller.setShuffle(enabled: false);

      expect(controller.state.queue, tracks.sublist(0, 3));
    });
  });

  /// @verifies BR-009
  group('BR-009 skip to a track', () {
    test('rule 8: loads that track and plays it', () async {
      await controller.setQueue([a, b, c, d]);

      final skipped = await controller.skipTo(2);

      expect(skipped, isTrue);
      expect(controller.state.currentIndex, 2);
      expect(loadedPath(), pathOf(c));
      expect(controller.state.playing, isTrue);
      expect(controller.state.queue, [a, b, c, d]);
    });

    test('rule 8: goes forward past an unavailable track', () async {
      await createController(available: {internal});
      await controller.setQueue([a, t('s', ssd), c]);

      await controller.skipTo(1);

      expect(controller.state.currentIndex, 2);
      expect(loadedPath(), pathOf(c));
      expect(notices.whereType<TracksSkipped>().single.count, 1);
    });

    test('rule 8: refuses a position outside the queue', () async {
      await controller.setQueue([a, b]);

      expect(await controller.skipTo(2), isFalse);
      expect(await controller.skipTo(-1), isFalse);

      expect(controller.state.currentIndex, 0);
      expect(engine.opened, isEmpty);
    });

    test('rule 8: failures in a row start again from zero', () async {
      opener.failing.addAll([a, b]);
      await controller.setQueue([a, b, c, d, e]);
      await controller.play();
      await settle();
      expect(controller.state.currentTrack, c);

      await controller.skipTo(3);
      await controller.skipTo(0);
      await settle();

      expect(notices.whereType<PlaybackStoppedAfterFailures>(), isEmpty);
    });

    test('rule 8: works on a stopped player', () async {
      await controller.setQueue([a, b]);

      await controller.skipTo(1);

      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isTrue);
    });
  });

  /// @verifies BR-009
  group('BR-009 play next and enqueue', () {
    test('rule 11: play next goes right after the current track', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();

      await controller.playNext([d]);

      expect(controller.state.queue, [a, d, b, c]);
      expect(controller.state.currentIndex, 0);
      expect(engine.opened.length, 1);
    });

    test('rule 11: several "play next" come in reverse order', () async {
      await controller.setQueue([a, b]);

      await controller.playNext([c]);
      await controller.playNext([d]);

      expect(controller.state.queue, [a, d, c, b]);
    });

    test('rule 11: enqueue goes to the end', () async {
      await controller.setQueue([a, b, c], startIndex: 1);

      await controller.enqueue([d, e]);

      expect(controller.state.queue, [a, b, c, d, e]);
      expect(controller.state.currentIndex, 1);
    });

    test('rule 11: the same track may be there twice', () async {
      await controller.setQueue([a, b]);

      await controller.enqueue([a]);
      await controller.playNext([a]);

      expect(controller.state.queue, [a, a, b, a]);
      expect(controller.state.currentIndex, 0);
    });

    test('rule 11: an empty queue starts playing the track', () async {
      await controller.playNext([c]);

      expect(controller.state.queue, [c]);
      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isTrue);
      expect(loadedPath(), pathOf(c));
    });

    test('rule 11: enqueue on an empty queue starts too', () async {
      await controller.enqueue([c, d]);

      expect(controller.state.queue, [c, d]);
      expect(controller.state.playing, isTrue);
    });

    test('rule 11: nothing to add changes nothing', () async {
      await controller.setQueue([a]);

      await controller.playNext(const []);
      await controller.enqueue(const []);

      expect(controller.state.queue, [a]);
    });

    test('rule 11: an unavailable track may be added', () async {
      await createController(available: {internal});
      await controller.setQueue([a, b]);

      await controller.enqueue([t('s', ssd)]);

      expect(controller.state.queue, hasLength(3));
    });

    test('rule 11: play next while shuffled is the next one played', () async {
      final tracks = many(20);
      await controller.setQueue(tracks);
      await controller.setShuffle(enabled: true);

      await controller.playNext([d]);

      expect(controller.state.queue[1], d);
      await controller.setShuffle(enabled: false);
      expect(controller.state.queue.take(2), [tracks.first, d]);
    });

    test(
      'rule 11: enqueue while shuffled ends up last in both orders',
      () async {
        final tracks = many(10);
        await controller.setQueue(tracks);
        await controller.setShuffle(enabled: true);

        await controller.enqueue([d]);
        expect(controller.state.queue.last, d);
        await controller.setShuffle(enabled: false);

        expect(controller.state.queue, [...tracks, d]);
      },
    );
  });

  /// @verifies FR-002
  group('FR-002 with duplicates', () {
    test('removes only the track at that position', () async {
      await controller.setQueue([a, b, a, c]);

      await controller.removeAt(2);

      expect(controller.state.queue, [a, b, c]);
    });
  });
}
