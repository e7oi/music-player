import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/playback/model/engine_issue.dart';
import 'package:musicplayer/domain/playback/model/playback_notice.dart';
import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';
import 'package:musicplayer/domain/storage/model/volume_event.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');
const ssd = DiskId('ssd');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late FakeTrackSourceOpener opener;
  late FakeVolumeEvents volumes;
  late PlayerController controller;
  late List<PlaybackNotice> notices;

  final a = t('a');
  final b = t('b');
  final c = t('c');
  final d = t('d');

  Future<void> settle() => pumpEventQueue();

  String? loadedPath() {
    final source = engine.loadedSource;
    return source is FileMediaSource ? source.path : null;
  }

  String pathOf(Track track) => '${track.disk.value}/${track.relativePath}';

  Future<void> createController({
    Set<DiskId> available = const {internal, ssd},
  }) async {
    engine = FakeAudioEngine();
    opener = FakeTrackSourceOpener();
    volumes = FakeVolumeEvents(available);
    controller = PlayerController(
      engine: engine,
      opener: opener,
      volumes: volumes,
    );
    notices = [];
    controller.notices.listen(notices.add);
    await controller.start();
  }

  setUp(createController);

  tearDown(() => controller.dispose());

  /// @verifies FR-001
  group('FR-001 playback commands', () {
    test('setQueue keeps nothing loaded until play is requested', () async {
      await controller.setQueue([a, b]);

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.currentIndex, 0);
      expect(engine.opened, isEmpty);
    });

    test('play loads the current track and starts playback', () async {
      await controller.setQueue([a, b], startIndex: 1);
      await controller.play();

      expect(loadedPath(), pathOf(b));
      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isTrue);
      expect(engine.calls, ['open', 'play']);
    });

    /// @verifies FR-001
    test('chains to the next track and keeps the intent to play', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
      expect(controller.state.playing, isTrue);
      expect(engine.calls.last, 'play');
    });

    test('stops at the end of the queue and keeps the queue', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      engine.completeTrack();
      await settle();
      engine.completeTrack();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(controller.state.queue, [a, b]);
      expect(controller.state.currentIndex, 1);
      expect(engine.calls.last, 'stop');
    });

    test('pause keeps the track loaded and drops the intent', () async {
      await controller.setQueue([a]);
      await controller.play();
      await controller.pause();

      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isFalse);
      expect(engine.calls.last, 'pause');
    });

    test('play after pause resumes without reloading', () async {
      await controller.setQueue([a]);
      await controller.play();
      await controller.pause();
      await controller.play();

      expect(engine.calls, ['open', 'play', 'pause', 'play']);
    });

    test('seek goes to the engine', () async {
      await controller.setQueue([a]);
      await controller.play();
      await controller.seek(const Duration(seconds: 42));

      expect(engine.calls.last, 'seek');
    });

    test('position and duration come from the engine', () async {
      await controller.setQueue([a]);
      await controller.play();
      engine
        ..emitDuration(const Duration(minutes: 3))
        ..emitPosition(const Duration(seconds: 7));
      await settle();

      expect(controller.state.duration, const Duration(minutes: 3));
      expect(controller.state.position, const Duration(seconds: 7));
    });

    test('next loads the following track', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      await controller.next();

      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
    });

    test('next on the last track stops like the end of the queue', () async {
      await controller.setQueue([a]);
      await controller.play();
      await controller.next();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(engine.calls.last, 'stop');
    });

    test('stop unloads the engine and keeps the queue', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      await controller.stop();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(controller.state.queue, [a, b]);
      expect(engine.calls.last, 'stop');
    });

    test('a completion that arrives after next is ignored', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();
      engine.completeTrack();
      await controller.next();
      await settle();

      expect(controller.state.currentIndex, 1);
    });

    group('previous', () {
      /// @verifies FR-001
      test('restarts the track after more than 3 s', () async {
        await controller.setQueue([a, b], startIndex: 1);
        await controller.play();
        engine.emitPosition(const Duration(seconds: 4));
        await settle();

        await controller.previous();

        expect(controller.state.currentIndex, 1);
        expect(engine.calls.last, 'seek');
      });

      /// @verifies FR-001
      test('goes to the previous track within the first 3 s', () async {
        await controller.setQueue([a, b], startIndex: 1);
        await controller.play();
        engine.emitPosition(const Duration(seconds: 2));
        await settle();

        await controller.previous();

        expect(controller.state.currentIndex, 0);
        expect(loadedPath(), pathOf(a));
      });

      test('restarts the first track', () async {
        await controller.setQueue([a, b]);
        await controller.play();

        await controller.previous();

        expect(controller.state.currentIndex, 0);
        expect(engine.calls.last, 'seek');
      });

      /// @verifies FR-001
      /// @verifies BR-003
      test('stops when the previous track cannot be opened', () async {
        opener.failing.add(a);
        await controller.setQueue([a, b], startIndex: 1);
        await controller.play();

        await controller.previous();
        await settle();

        expect(controller.state.status, PlayerStatus.stopped);
        expect(controller.state.playing, isFalse);
        expect(engine.calls.last, 'stop');
        expect(notices, [isA<TrackFailed>()]);
      });

      test('skips unavailable tracks backwards', () async {
        final s = t('s', ssd);
        await createController(available: {internal});
        await controller.setQueue([a, s, b], startIndex: 2);
        await controller.play();

        await controller.previous();
        await settle();

        expect(controller.state.currentIndex, 0);
        expect(notices, [
          isA<TracksSkipped>().having((n) => n.count, 'count', 1),
        ]);
      });
    });
  });

  group('BR-001 tracks of an unavailable disk', () {
    /// @verifies BR-001
    test('skips a run of unavailable tracks with one notice', () async {
      final b2 = t('b', ssd);
      final c2 = t('c', ssd);
      await createController(available: {internal});
      await controller.setQueue([a, b2, c2, d]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 3);
      expect(loadedPath(), pathOf(d));
      expect(controller.state.playing, isTrue);
      expect(notices, hasLength(1));
      final notice = notices.single as TracksSkipped;
      expect(notice.count, 2);
      expect(notice.disks, {ssd});
      expect(opener.opened, isNot(contains(b2)));
      expect(opener.opened, isNot(contains(c2)));
    });

    /// @verifies BR-001
    test('each run of skipped tracks gets its own notice', () async {
      final s1 = t('s1', ssd);
      final s2 = t('s2', ssd);
      await createController(available: {internal});
      await controller.setQueue([a, s1, b, s2, c]);
      await controller.play();

      engine.completeTrack();
      await settle();
      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 4);
      expect(notices.map((n) => (n as TracksSkipped).count), [1, 1]);
    });

    /// @verifies BR-001
    test('stops with a notice when no available track remains', () async {
      final s1 = t('s1', ssd);
      await createController(available: {internal});
      await controller.setQueue([a, s1]);
      await controller.play();

      engine.completeTrack();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(notices, [
        isA<TracksSkipped>().having((n) => n.count, 'count', 1),
      ]);
    });

    /// @verifies BR-001
    test('loads nothing when the whole queue is unavailable', () async {
      await createController(available: {internal});
      await controller.setQueue([t('s1', ssd), t('s2', ssd)]);
      await controller.play();
      await settle();

      expect(engine.opened, isEmpty);
      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(notices, [
        isA<TracksSkipped>().having((n) => n.count, 'count', 2),
      ]);
    });
  });

  group('BR-002 ejection', () {
    /// @verifies BR-002
    test(
      'stops the engine before marking the current disk unavailable',
      () async {
        final s1 = t('s1', ssd);
        await controller.setQueue([s1, a]);
        await controller.play();
        final stop = engine.holdNextStop();

        volumes.emit(const VolumeEjecting(ssd));
        await settle();

        expect(engine.stopCalls, 1);
        expect(controller.state.availableDisks, contains(ssd));

        stop.complete();
        await settle();

        expect(controller.state.availableDisks, isNot(contains(ssd)));
        expect(engine.releasedSources, 1);
      },
    );

    /// @verifies BR-002
    test('stays stopped on the ejected track with a notice', () async {
      final s1 = t('s1', ssd);
      await controller.setQueue([s1, a]);
      await controller.play();

      volumes.emit(const VolumeEjecting(ssd));
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(controller.state.currentIndex, 0);
      expect(engine.opened, hasLength(1));
      expect(notices, [isA<PlaybackStoppedByEjection>()]);
    });

    /// @verifies BR-002
    test(
      'another disk is marked unavailable without touching the engine',
      () async {
        final s1 = t('s1', ssd);
        await controller.setQueue([a, s1, b]);
        await controller.play();

        volumes.emit(const VolumeEjecting(ssd));
        await settle();

        expect(engine.stopCalls, 0);
        expect(controller.state.playing, isTrue);
        expect(controller.state.availableDisks, isNot(contains(ssd)));

        engine.completeTrack();
        await settle();

        expect(controller.state.currentIndex, 2);
      },
    );

    /// @verifies BR-002
    test('a repeated ejection has no further effect', () async {
      final s1 = t('s1', ssd);
      await controller.setQueue([s1]);
      await controller.play();

      volumes
        ..emit(const VolumeEjecting(ssd))
        ..emit(const VolumeEjecting(ssd));
      await settle();

      expect(engine.stopCalls, 1);
      expect(notices, hasLength(1));
    });

    /// @verifies BR-002
    test(
      'a removal without announcement is handled like an ejection',
      () async {
        final s1 = t('s1', ssd);
        await controller.setQueue([s1]);
        await controller.play();

        volumes.emit(const VolumeRemoved(ssd));
        await settle();

        expect(engine.stopCalls, 1);
        expect(controller.state.availableDisks, isNot(contains(ssd)));
      },
    );

    /// @verifies BR-002
    test(
      'a disk coming back is available but playback does not resume',
      () async {
        final s1 = t('s1', ssd);
        await controller.setQueue([s1]);
        await controller.play();
        volumes.emit(const VolumeEjecting(ssd));
        await settle();
        final callsBefore = [...engine.calls];

        volumes.emit(const VolumeMounted(ssd));
        await settle();

        expect(controller.state.availableDisks, contains(ssd));
        expect(engine.calls, callsBefore);
        expect(controller.state.status, PlayerStatus.stopped);
      },
    );
  });

  group('BR-003 engine problems', () {
    /// @verifies BR-003
    test('a failure is reported and the next track plays', () async {
      await controller.setQueue([a, b]);
      await controller.play();

      engine.emitIssue(
        const EngineFailure(EngineFailureKind.playbackFailed, 'x'),
      );
      await settle();

      expect(notices, [isA<TrackFailed>().having((n) => n.track, 'track', a)]);
      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
      expect(engine.calls.last, 'play');
    });

    /// @verifies BR-003
    test('a track that cannot be opened is reported and skipped', () async {
      opener.failing.add(a);
      await controller.setQueue([a, b]);
      await controller.play();
      await settle();

      expect(notices, [
        isA<TrackFailed>()
            .having((n) => n.track, 'track', a)
            .having(
              (n) => n.failure.kind,
              'kind',
              EngineFailureKind.openFailed,
            ),
      ]);
      expect(loadedPath(), pathOf(b));
    });

    /// @verifies BR-003
    test('stops after 3 consecutive failures', () async {
      opener.failing.addAll([a, b, c]);
      await controller.setQueue([a, b, c, d]);
      await controller.play();
      await settle();

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.playing, isFalse);
      expect(controller.state.currentIndex, 2);
      expect(engine.opened, isEmpty);
      expect(notices.whereType<TrackFailed>(), hasLength(3));
      expect(notices.last, isA<PlaybackStoppedAfterFailures>());
    });

    /// @verifies BR-003
    test('stops after 3 consecutive engine failures', () async {
      await controller.setQueue([a, b, c, d]);
      await controller.play();

      for (var i = 0; i < 3; i++) {
        engine.emitIssue(
          const EngineFailure(EngineFailureKind.playbackFailed, 'x'),
        );
        await settle();
      }

      expect(controller.state.status, PlayerStatus.stopped);
      expect(controller.state.currentIndex, 2);
      expect(notices.whereType<TrackFailed>(), hasLength(3));
      expect(notices.last, isA<PlaybackStoppedAfterFailures>());
    });

    /// @verifies BR-003
    test('a failure while the track loads moves on like any failure', () async {
      engine.failNextOpen = true;
      await controller.setQueue([a, b]);
      await controller.play();
      await settle();

      expect(notices, [isA<TrackFailed>().having((n) => n.track, 'track', a)]);
      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(b));
      expect(controller.state.playing, isTrue);
    });

    /// @verifies BR-003
    test('play after an end-of-queue stop resets the failure count', () async {
      opener.failing.addAll([b, c]);
      await controller.setQueue([a, b, c]);
      await controller.play();
      engine.completeTrack();
      await settle();
      expect(controller.state.status, PlayerStatus.stopped);

      await controller.play();
      await settle();

      expect(notices.whereType<PlaybackStoppedAfterFailures>(), isEmpty);
    });

    /// @verifies BR-003
    test('a track played to its end resets the failure count', () async {
      final e = t('e');
      final f = t('f');
      opener.failing.addAll([a, b, d]);
      await controller.setQueue([a, b, c, d, e, f]);
      await controller.play();
      expect(controller.state.currentIndex, 2);

      engine.completeTrack();
      await settle();

      expect(controller.state.currentIndex, 4);
      expect(controller.state.playing, isTrue);
      expect(notices.whereType<PlaybackStoppedAfterFailures>(), isEmpty);
    });

    /// @verifies BR-003
    test(
      'fewer than 3 remaining failing tracks stop at the end of the queue',
      () async {
        opener.failing.addAll([b, c]);
        await controller.setQueue([a, b, c]);
        await controller.play();

        engine.completeTrack();
        await settle();

        expect(controller.state.status, PlayerStatus.stopped);
        expect(notices.whereType<TrackFailed>(), hasLength(2));
        expect(notices.whereType<PlaybackStoppedAfterFailures>(), isEmpty);
      },
    );

    /// @verifies BR-003
    test('a warning changes nothing and is counted', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      final callsBefore = [...engine.calls];

      engine.emitIssue(
        const EngineWarning(EngineWarningKind.unclassified, 'w'),
      );
      await settle();

      expect(controller.state.warningCount, 1);
      expect(controller.state.currentIndex, 0);
      expect(controller.state.playing, isTrue);
      expect(engine.calls, callsBefore);
      expect(notices, isEmpty);
    });
  });

  group('FR-002 removing a track from the queue', () {
    /// @verifies FR-002
    test('removing another track shifts the queue and keeps playing', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();

      expect(await controller.removeAt(1), isTrue);

      expect(controller.state.queue, [a, c]);
      expect(controller.state.currentIndex, 0);
      expect(engine.calls, ['open', 'play']);
    });

    /// @verifies FR-002
    test(
      'removing a track before the current one keeps the current track',
      () async {
        await controller.setQueue([a, b, c], startIndex: 2);
        await controller.play();

        await controller.removeAt(0);

        expect(controller.state.queue, [b, c]);
        expect(controller.state.currentIndex, 1);
        expect(controller.state.currentTrack, c);
      },
    );

    /// @verifies FR-002
    test('removing the playing track plays the next one', () async {
      await controller.setQueue([a, b, c], startIndex: 1);
      await controller.play();

      await controller.removeAt(1);

      expect(controller.state.queue, [a, c]);
      expect(controller.state.currentIndex, 1);
      expect(loadedPath(), pathOf(c));
      expect(controller.state.playing, isTrue);
      expect(engine.calls.last, 'play');
    });

    /// @verifies FR-002
    test('removing the paused track loads the next one paused', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      await controller.pause();

      await controller.removeAt(0);

      expect(loadedPath(), pathOf(b));
      expect(controller.state.status, PlayerStatus.ready);
      expect(controller.state.playing, isFalse);
      expect(engine.calls.last, 'open');
    });

    /// @verifies FR-002
    test(
      'removing the current last track stops like the end of the queue',
      () async {
        await controller.setQueue([a, b], startIndex: 1);
        await controller.play();

        await controller.removeAt(1);

        expect(controller.state.queue, [a]);
        expect(controller.state.status, PlayerStatus.stopped);
        expect(controller.state.playing, isFalse);
        expect(engine.calls.last, 'stop');
      },
    );

    /// @verifies FR-002
    test(
      'removing the only track stops the engine and empties the queue',
      () async {
        await controller.setQueue([a]);
        await controller.play();

        await controller.removeAt(0);

        expect(controller.state.queue, isEmpty);
        expect(controller.state.currentIndex, isNull);
        expect(controller.state.status, PlayerStatus.idle);
        expect(engine.calls.last, 'stop');
      },
    );

    /// @verifies FR-002
    test('a position outside the queue is refused without change', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      final before = controller.state;

      expect(await controller.removeAt(2), isFalse);
      expect(await controller.removeAt(-1), isFalse);

      expect(controller.state.queue, before.queue);
      expect(controller.state.currentIndex, before.currentIndex);
      expect(engine.calls, ['open', 'play']);
    });
  });

  test('states stream reports changes', () async {
    final states = <PlayerState>[];
    final sub = controller.states.listen(states.add);
    await controller.setQueue([a]);
    await controller.play();
    await settle();
    await sub.cancel();

    expect(states.map((s) => s.status), contains(PlayerStatus.ready));
  });

  test('start reads the disks available at startup', () async {
    await createController(available: {internal});

    expect(controller.state.availableDisks, {internal});
  });
}
