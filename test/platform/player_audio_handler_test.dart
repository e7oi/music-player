import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';
import 'package:musicplayer/platform/media_session/player_audio_handler.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_storage.dart';

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late PlayerAudioHandler handler;
  late DateTime now;

  final a = LibraryTrack(
    id: 1,
    disk: internalDisk,
    info: info('Music/a.flac', title: 'A'),
  );
  final b = LibraryTrack(id: 2, disk: internalDisk, info: info('Music/b.mp3'));
  final known = {
    for (final t in [a, b]) t.track: t,
  };

  Future<void> settle() => pumpEventQueue();

  PlaybackState playback() => handler.playbackState.value;

  setUp(() async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internalDisk}),
    );
    await controller.start();
    now = DateTime(2026, 10, 21, 12);
    handler = PlayerAudioHandler(
      controller,
      describe: (track) => known[track],
      clock: () => now,
    );
    await controller.setQueue([a.track, b.track]);
  });

  tearDown(() async {
    await handler.dispose();
    await controller.dispose();
  });

  group('FR-005 state shown by the system', () {
    /// @verifies FR-005
    test('shows the current track with its information', () async {
      await controller.play();
      await settle();

      final item = handler.mediaItem.value!;
      expect(item.title, 'A');
      expect(playback().playing, isTrue);
      expect(playback().processingState, AudioProcessingState.ready);
      expect(playback().queueIndex, 0);
    });

    /// @verifies FR-005
    test('falls back to the file name without a title', () async {
      await controller.next();
      await settle();

      expect(handler.mediaItem.value!.title, 'b.mp3');
    });

    /// @verifies FR-005
    test('offers previous, play or pause, stop, next and seek', () async {
      await controller.play();
      await settle();

      expect(playback().controls, [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ]);
      expect(playback().systemActions, contains(MediaAction.seek));

      await controller.pause();
      await settle();
      expect(playback().controls[1], MediaControl.play);
    });

    /// @verifies FR-005
    test('a stopped player releases the system controls', () async {
      await controller.play();
      await settle();

      await controller.stop();
      await settle();

      expect(playback().processingState, AudioProcessingState.idle);
    });

    /// @verifies FR-005
    test('a seek is shown, regular progress is extrapolated', () async {
      await controller.play();
      await settle();
      final shown = playback();

      now = now.add(const Duration(seconds: 1));
      engine.emitPosition(const Duration(seconds: 1));
      await settle();
      expect(playback(), same(shown));

      engine.emitPosition(const Duration(seconds: 40));
      await settle();
      expect(playback().updatePosition, const Duration(seconds: 40));
    });
  });

  group('FR-005 system commands', () {
    /// @verifies FR-005
    test('commands go through the controller', () async {
      await handler.play();
      await settle();
      expect(controller.state.playing, isTrue);

      await handler.skipToNext();
      await settle();
      expect(controller.state.currentIndex, 1);

      await handler.skipToPrevious();
      await settle();
      expect(controller.state.currentIndex, 0);

      await handler.pause();
      await settle();
      expect(controller.state.playing, isFalse);

      await handler.seek(const Duration(seconds: 12));
      await settle();
      expect(controller.state.position, const Duration(seconds: 12));
    });

    /// @verifies FR-005
    test('stop stops the controller', () async {
      await handler.play();
      await settle();

      await handler.stop();
      await settle();

      expect(controller.state.playing, isFalse);
      expect(playback().processingState, AudioProcessingState.idle);
    });

    /// @verifies FR-005
    test('removing the task keeps playback going', () async {
      await handler.play();
      await settle();

      await handler.onTaskRemoved();
      await settle();

      expect(controller.state.playing, isTrue);
    });

    /// @verifies FR-005
    test('removing the task while paused stops', () async {
      await handler.play();
      await settle();
      await handler.pause();
      await settle();

      await handler.onTaskRemoved();
      await settle();

      expect(playback().processingState, AudioProcessingState.idle);
    });
  });
}
