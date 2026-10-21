import 'package:meta/meta.dart';
import 'package:musicplayer/domain/library/model/track.dart';

/// The disk of the internal storage.
///
/// @implements BR-004: a fixed identifier, tied to no serial number and no
/// volume UUID.
const internalDisk = DiskId('internal');

enum DiskKind { internal, removable }

@immutable
final class Disk {
  const new({required this.id, required this.label, required this.kind});

  /// The disk of the internal storage, named "Local" in the interface (FR-003).
  static const internal = Disk(
    id: internalDisk,
    label: 'Local',
    kind: DiskKind.internal,
  );

  final DiskId id;
  final String label;
  final DiskKind kind;
}

/// What an index reads about one audio file, before it is stored.
///
/// @implements FR-003: the information kept for each track.
@immutable
final class TrackInfo {
  const new({
    required this.relativePath,
    required this.size,
    required this.modifiedAt,
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.duration,
  });

  /// Path relative to the disk, `/` separated, without a leading `/`.
  final String relativePath;
  final int size;
  final DateTime modifiedAt;
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final Duration? duration;

  /// A file whose size or modification date changed is reindexed (FR-003).
  bool sameFileAs(TrackInfo other) =>
      other.size == size && other.modifiedAt == modifiedAt;

  @override
  bool operator ==(Object other) =>
      other is TrackInfo &&
      other.relativePath == relativePath &&
      other.size == size &&
      other.modifiedAt == modifiedAt &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.albumArtist == albumArtist &&
      other.trackNumber == trackNumber &&
      other.discNumber == discNumber &&
      other.year == year &&
      other.genre == genre &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(
    relativePath,
    size,
    modifiedAt,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    discNumber,
    year,
    genre,
    duration,
  );
}

/// A track stored in the library.
@immutable
final class LibraryTrack {
  const new({required this.id, required this.disk, required this.info});

  /// Internal identity, kept across reindexing (BR-004).
  final int id;
  final DiskId disk;
  final TrackInfo info;

  Track get track => Track(disk: disk, relativePath: info.relativePath);

  /// The title, or the file name when MediaStore has none (FR-003).
  String get displayTitle {
    final title = info.title;
    if (title != null && title.isNotEmpty) return title;
    final path = info.relativePath;
    return path.substring(path.lastIndexOf('/') + 1);
  }
}
