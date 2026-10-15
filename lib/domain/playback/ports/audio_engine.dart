import 'package:musicplayer/domain/playback/model/engine_issue.dart';
import 'package:musicplayer/domain/playback/model/engine_state.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

/// The audio engine behind `PlayerController`.
///
/// @decision D2: `media_kit` is the only engine; this port keeps the
/// controller independent of it. The contract below is executable:
/// `test/contract/audio_engine_contract.dart` runs it against the fake in CI
/// and against the `media_kit` adapter on a device.
///
/// Contract:
/// - [open] loads without starting playback and may return before the
///   duration is known; the duration arrives on [durationStream]. The
///   `loading` state is not guaranteed.
/// - [open] does not throw for an unreadable source: it reports an
///   [EngineFailure] on [issueStream].
/// - [play] returns once playback is requested. `playing` is the intent and
///   stays true across tracks.
/// - [completedStream] emits once per track.
/// - [stop] returns only after the engine has stopped reading and released
///   every resource, descriptors included (`DescriptorMediaSource.release`).
///   It is idempotent. One exception (BR-002 rule 7): if the engine has not
///   closed the file within its timeout, [stop] returns with the descriptor
///   still open and releases it later, because a descriptor the engine may
///   still read is never closed.
abstract interface class AudioEngine {
  EngineState get state;

  /// Broadcast.
  Stream<EngineState> get stateStream;

  /// Broadcast.
  Stream<Duration> get positionStream;

  /// Null while unknown. Broadcast.
  Stream<Duration?> get durationStream;

  /// One event per track that played to its end. Broadcast.
  Stream<void> get completedStream;

  /// Broadcast.
  Stream<EngineIssue> get issueStream;

  /// Takes ownership of [source] (see `DescriptorMediaSource`). Unloads and
  /// releases the previous source first.
  Future<void> open(MediaSource source);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> stop();

  /// Stops, then frees the engine. The engine is unusable afterwards.
  Future<void> dispose();
}
