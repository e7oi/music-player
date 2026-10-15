/// A problem reported by the audio engine, classified by its adapter.
///
/// @decision D2: adapters classify, the controller switches exhaustively.
sealed class EngineIssue {
  const new(this.message);

  /// Raw engine message, for logs only: it may contain a file name.
  final String message;
}

enum EngineFailureKind {
  /// The source could not be opened or recognised.
  openFailed,

  /// Playback of a loaded track ended on an error.
  playbackFailed,
}

/// Fatal for the current track: the controller moves on (BR-003).
final class EngineFailure extends EngineIssue {
  const new(this.kind, super.message);

  final EngineFailureKind kind;

  @override
  String toString() => 'EngineFailure(${kind.name})';
}

enum EngineWarningKind {
  /// Not recognised yet; MPL-010 classifies recorded real messages.
  unclassified,
}

/// Never changes the playback state; logged by the adapter and counted.
final class EngineWarning extends EngineIssue {
  const new(this.kind, super.message);

  final EngineWarningKind kind;

  @override
  String toString() => 'EngineWarning(${kind.name})';
}
