/// What happens at the end of a track or of the queue.
///
/// @implements BR-009
enum RepeatMode {
  /// The queue ends where it ends (FR-001).
  off,

  /// The queue starts again from its first available track.
  all,

  /// The track that ends starts again.
  one,
}
