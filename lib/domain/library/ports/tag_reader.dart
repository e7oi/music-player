import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// Reads the tags and the artwork inside an audio file (FR-007, ADR-009).
abstract interface class TagReader {
  /// Opens the file, reads it, closes it at once (BR-006.3). Null when the
  /// file has nothing readable.
  Future<FileTags?> read(Track track);

  /// Deletes the stored artwork images not listed in [keep] (FR-007.10).
  Future<void> retainArtwork(Set<String> keep);
}
