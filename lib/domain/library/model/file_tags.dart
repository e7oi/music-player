import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// What is read inside one audio file (FR-007).
@immutable
final class FileTags {
  const new({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.duration,
    this.artwork,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final Duration? duration;

  /// Identifier of the stored artwork image, null when the file has none
  /// (FR-007.7).
  final String? artwork;
}

/// A folder of a removable disk, chosen with the Android picker (FR-006).
@immutable
final class RemovableFolder {
  const new({required this.disk, required this.diskLabel, required this.path});

  final DiskId disk;
  final String diskLabel;

  /// Relative to the root of the volume, `/` separated; empty for the root.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is RemovableFolder && other.disk == disk && other.path == path;

  @override
  int get hashCode => Object.hash(disk, path);
}

/// A removable volume Android has mounted.
@immutable
final class MountedVolume {
  const new({required this.id, required this.label});

  final DiskId id;
  final String label;
}
