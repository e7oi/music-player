import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

/// Thrown when a track cannot be opened (file missing, permission revoked).
final class TrackSourceException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'TrackSourceException: $message';
}

/// Turns a track (disk, relative path) into something the engine can read.
abstract interface class TrackSourceOpener {
  /// Throws [TrackSourceException] when the track cannot be opened.
  Future<MediaSource> open(Track track);
}
