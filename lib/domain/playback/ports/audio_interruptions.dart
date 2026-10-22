/// How long and how hard the system takes the audio output from the app.
enum InterruptionKind {
  /// A call, a voice assistant, an alarm: the output comes back.
  transient,

  /// Navigation guidance, a notification sound: playback may go on, quieter.
  duck,

  /// Another app started its own playback: the output does not come back.
  permanent,
}

sealed class InterruptionEvent {
  const new();
}

final class InterruptionBegan extends InterruptionEvent {
  const new(this.kind);

  final InterruptionKind kind;
}

final class InterruptionEnded extends InterruptionEvent {
  const new(this.kind);

  final InterruptionKind kind;
}

/// Headphones unplugged or a Bluetooth audio device disconnected: the sound
/// would come out of the speaker.
final class BecameNoisy extends InterruptionEvent {
  const new();
}

/// The system side of BR-005: audio focus and output changes.
abstract interface class AudioInterruptions {
  /// Asks for the audio output; false when the system refuses it, during a
  /// call for instance.
  Future<bool> activate();

  /// Gives the audio output back.
  Future<void> deactivate();

  /// Broadcast.
  Stream<InterruptionEvent> get events;
}
