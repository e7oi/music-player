import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/playback/model/engine_issue.dart';

/// Something the user should be told about. The text lives in the ARB files;
/// the controller only states the facts.
sealed class PlaybackNotice {
  const new();
}

/// One run of consecutive tracks skipped because their disk is unavailable.
///
/// @implements BR-001: one notice per run, no total over the session.
final class TracksSkipped extends PlaybackNotice {
  const new({required this.count, required this.disks});

  final int count;
  final Set<DiskId> disks;

  @override
  String toString() => 'TracksSkipped($count, $disks)';
}

/// A track could not be played; the controller moved on.
///
/// @implements BR-003
final class TrackFailed extends PlaybackNotice {
  const new({required this.track, required this.failure});

  final Track track;
  final EngineFailure failure;

  @override
  String toString() => 'TrackFailed($track, $failure)';
}

/// Playback stopped after too many consecutive failures.
///
/// @implements BR-003
final class PlaybackStoppedAfterFailures extends PlaybackNotice {
  const new(this.consecutiveFailures);

  final int consecutiveFailures;

  @override
  String toString() => 'PlaybackStoppedAfterFailures($consecutiveFailures)';
}

/// Playback stopped because the disk of the current track was ejected.
///
/// @implements BR-002
final class PlaybackStoppedByEjection extends PlaybackNotice {
  const new(this.disk);

  final DiskId disk;

  @override
  String toString() => 'PlaybackStoppedByEjection($disk)';
}
