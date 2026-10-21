import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';
import 'package:musicplayer/domain/playback/services/interruption_policy.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_audio_interruptions.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');

Track t(String name) => Track(disk: internal, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late FakeAudioInterruptions system;
  late InterruptionPolicy policy;

  Future<void> settle() => pumpEventQueue();

  PlayerState state() => controller.state;

  setUp(() async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internal}),
    );
    await controller.start();
    system = FakeAudioInterruptions();
    policy = InterruptionPolicy(
      controller: controller,
      interruptions: system,
      stopGrace: const Duration(milliseconds: 20),
    )..start();
    await controller.setQueue([t('a'), t('b')]);
  });

  tearDown(() async {
    await policy.dispose();
    await controller.dispose();
  });

  Future<void> playing() async {
    await controller.play();
    await settle();
    expect(state().playing, isTrue);
  }

  group('BR-005 focus on start', () {
    /// @verifies BR-005
    test('starting playback asks for the audio output', () async {
      await playing();

      expect(system.requests, 1);
    });

    /// @verifies BR-005
    test('a refused audio output leaves playback paused', () async {
      system.grant = false;

      await controller.play();
      await settle();

      expect(state().playing, isFalse);
    });

    /// @verifies BR-005
    test('a second play during a call is refused too', () async {
      system.grant = false;
      await controller.play();
      await settle();

      await controller.play();
      await settle();

      expect(state().playing, isFalse);
      expect(system.requests, 2);
    });

    /// @verifies BR-005
    test('play during a transient loss asks the system again', () async {
      await playing();
      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();
      system.grant = false;

      await controller.play();
      await settle();

      expect(state().playing, isFalse);
      expect(system.requests, 2);
    });

    /// @verifies BR-005
    test('stopping gives the audio output back', () async {
      await playing();

      await controller.stop();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settle();

      expect(system.deactivations, 1);
    });

    /// @verifies BR-005
    test('choosing another track keeps the audio output', () async {
      await playing();

      await controller.setQueue([t('b'), t('a')]);
      await controller.play();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settle();

      expect(system.deactivations, 0);
      expect(system.requests, 1);
    });
  });

  group('BR-005 interruptions', () {
    /// @verifies BR-005
    test('a loss that ends before the pause completes still resumes', () async {
      await playing();

      system
        ..emit(const InterruptionBegan(InterruptionKind.transient))
        ..emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();

      expect(state().playing, isTrue);
    });

    /// @verifies BR-005
    test('a resume is not left over for a later loss', () async {
      await playing();
      system
        ..emit(const InterruptionBegan(InterruptionKind.transient))
        ..emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();
      await controller.pause();
      await settle();

      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();
      system.emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();

      expect(state().playing, isFalse);
    });

    /// @verifies BR-005
    test('a permanent loss pauses without resuming', () async {
      await playing();

      system.emit(const InterruptionBegan(InterruptionKind.permanent));
      await settle();
      system.emit(const InterruptionEnded(InterruptionKind.permanent));
      await settle();

      expect(state().playing, isFalse);
    });

    /// @verifies BR-005
    test('a transient loss pauses, then resumes when it ends', () async {
      await playing();

      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();
      expect(state().playing, isFalse);

      system.emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();
      expect(state().playing, isTrue);
      expect(state().currentIndex, 0);
    });

    /// @verifies BR-005
    test('a transient loss while paused does not start playback', () async {
      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();
      system.emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();

      expect(state().playing, isFalse);
    });

    /// @verifies BR-005
    test('a command during a transient loss cancels the resume', () async {
      await playing();
      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();

      await controller.next();
      await settle();
      system.emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();

      expect(state().playing, isFalse);
      expect(state().currentIndex, 1);
    });

    /// @verifies BR-005
    test('playing again during a transient loss is kept', () async {
      await playing();
      system.emit(const InterruptionBegan(InterruptionKind.transient));
      await settle();

      await playing();
      await controller.pause();
      await settle();
      system.emit(const InterruptionEnded(InterruptionKind.transient));
      await settle();

      expect(state().playing, isFalse);
    });

    /// @verifies BR-005
    test('a duck keeps playing', () async {
      await playing();

      system.emit(const InterruptionBegan(InterruptionKind.duck));
      await settle();

      expect(state().playing, isTrue);
    });

    /// @verifies BR-005
    test('unplugged headphones pause without resuming', () async {
      await playing();

      system.emit(const BecameNoisy());
      await settle();

      expect(state().playing, isFalse);
      expect(state().currentIndex, 0);
      expect(state().status, PlayerStatus.ready);
    });

    /// @verifies BR-005
    test(
      'a transient loss after headphones were unplugged does not resume',
      () async {
        await playing();
        system.emit(const BecameNoisy());
        await settle();

        system.emit(const InterruptionBegan(InterruptionKind.transient));
        await settle();
        system.emit(const InterruptionEnded(InterruptionKind.transient));
        await settle();

        expect(state().playing, isFalse);
      },
    );
  });
}
