import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';

/// [AudioInterruptions] over Android audio focus (ADR-006).
///
/// The music preset lets Android lower the volume itself on a duck
/// (BR-005, rule 4).
class AudioSessionInterruptions implements AudioInterruptions {
  new(this._session);

  /// Configures the shared session for music playback.
  static Future<AudioSessionInterruptions> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    return AudioSessionInterruptions(session);
  }

  final AudioSession _session;

  @override
  Future<bool> activate() => _session.setActive(true);

  @override
  Future<void> deactivate() => _session.setActive(false);

  @override
  Stream<InterruptionEvent> get events => _merge([
    _session.interruptionEventStream.map(eventOf),
    _session.becomingNoisyEventStream.map((_) => const BecameNoisy()),
  ]);

  static InterruptionEvent eventOf(AudioInterruptionEvent event) {
    final kind = switch (event.type) {
      AudioInterruptionType.pause => InterruptionKind.transient,
      AudioInterruptionType.duck => InterruptionKind.duck,
      AudioInterruptionType.unknown => InterruptionKind.permanent,
    };
    return event.begin ? InterruptionBegan(kind) : InterruptionEnded(kind);
  }
}

/// Merges broadcast streams into one broadcast stream.
Stream<T> _merge<T>(List<Stream<T>> streams) {
  final subscriptions = <StreamSubscription<T>>[];
  late final StreamController<T> merged;
  merged = StreamController<T>.broadcast(
    onListen: () => subscriptions.addAll([
      for (final stream in streams) stream.listen(merged.add),
    ]),
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    },
  );
  return merged.stream;
}
