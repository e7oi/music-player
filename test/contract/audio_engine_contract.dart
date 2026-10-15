import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/playback/model/engine_issue.dart';
import 'package:musicplayer/domain/playback/model/engine_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_engine.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

typedef SourceFactory = Future<MediaSource> Function();

/// The executable contract of [AudioEngine] (see its dartdoc).
///
/// Run against `FakeAudioEngine` in CI and against the `media_kit` adapter
/// on a device (`integration_test/`).
///
/// [playableSource] must be a track shorter than [timeout].
/// [descriptorSourceFor], when given, wraps a playable track in a
/// [DescriptorMediaSource] whose `release` calls the given callback; without
/// it the descriptor checks are skipped.
///
/// @decision D2
void runAudioEngineContract({
  required String description,
  required AudioEngine Function() createEngine,
  required SourceFactory playableSource,
  required SourceFactory unreadableSource,
  Future<MediaSource> Function(void Function() onRelease)? descriptorSourceFor,
  Duration timeout = const Duration(seconds: 10),
  Duration quietPeriod = const Duration(milliseconds: 500),
}) {
  group('AudioEngine contract ($description)', () {
    late AudioEngine engine;

    setUp(() => engine = createEngine());

    tearDown(() => engine.dispose());

    Future<void> quiet() => Future<void>.delayed(quietPeriod);

    test('open loads without starting playback', () async {
      var completed = 0;
      final sub = engine.completedStream.listen((_) => completed++);

      await engine.open(await playableSource());
      await quiet();
      await sub.cancel();

      expect(engine.state.playing, isFalse);
      expect(engine.state.processing, EngineProcessing.ready);
      expect(completed, 0);
    });

    test('the duration arrives on durationStream', () async {
      final duration = engine.durationStream
          .firstWhere((d) => d != null && d > Duration.zero)
          .timeout(timeout);

      await engine.open(await playableSource());

      expect(await duration, greaterThan(Duration.zero));
    });

    test(
      'completed is emitted once per track and the intent to play stays true',
      () async {
        var completed = 0;
        final sub = engine.completedStream.listen((_) => completed++);
        final first = engine.completedStream.first.timeout(timeout);

        await engine.open(await playableSource());
        await engine.play();
        await first;
        await quiet();
        await sub.cancel();

        expect(completed, 1);
        expect(engine.state.playing, isTrue);
      },
    );

    test('pause drops the intent to play', () async {
      await engine.open(await playableSource());
      await engine.play();
      await engine.pause();

      expect(engine.state.playing, isFalse);
    });

    test('stop unloads and is idempotent', () async {
      await engine.open(await playableSource());
      await engine.play();

      await engine.stop();
      await engine.stop();

      expect(engine.state, EngineState.idle);
    });

    test(
      'an unreadable source reports one failure, without throwing',
      () async {
        final failures = <EngineFailure>[];
        final sub = engine.issueStream.listen((issue) {
          if (issue is EngineFailure) failures.add(issue);
        });
        final first = engine.issueStream
            .firstWhere((issue) => issue is EngineFailure)
            .timeout(timeout);

        await engine.open(await unreadableSource());
        await first;
        await quiet();
        await sub.cancel();

        expect(failures, hasLength(1));
      },
    );

    test('stop releases the descriptor before returning', () async {
      var released = 0;
      await engine.open(await descriptorSourceFor!(() => released++));
      await engine.play();

      await engine.stop();
      expect(released, 1);

      await engine.stop();
      expect(released, 1);
    }, skip: descriptorSourceFor == null ? 'no descriptor source' : false);

    test('open releases the previous descriptor', () async {
      var released = 0;
      await engine.open(await descriptorSourceFor!(() => released++));

      await engine.open(await playableSource());

      expect(released, 1);
    }, skip: descriptorSourceFor == null ? 'no descriptor source' : false);
  });
}
