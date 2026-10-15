import 'package:meta/meta.dart';

/// A disk holding tracks: the internal storage or a removable volume.
///
/// @decision D23: a removable disk is identified by the UUID of its
/// filesystem, so that it is recognised again after being unplugged.
extension type const DiskId(String value);

/// A track of the library.
///
/// @decision D23: a track is identified by its disk and its path relative to
/// that disk, never by an absolute path or a content URI.
@immutable
final class Track {
  const new({required this.disk, required this.relativePath});

  final DiskId disk;
  final String relativePath;

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.disk == disk &&
      other.relativePath == relativePath;

  @override
  int get hashCode => Object.hash(disk, relativePath);

  @override
  String toString() => 'Track(${disk.value}, $relativePath)';
}
