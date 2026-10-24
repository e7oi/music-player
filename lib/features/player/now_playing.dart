import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// What the details line of the player says about a track (FR-017.4): the
/// tags it has, or, with none of the four, its format and folder.
@immutable
final class TrackDetails {
  const new({
    this.disc,
    this.number,
    this.year,
    this.genre,
    this.format,
    this.folder,
  });

  final int? disc;
  final int? number;
  final int? year;
  final String? genre;

  /// The extension in capitals; only when no tag is known.
  final String? format;

  /// The folder holding the file; only when no tag is known.
  final String? folder;

  bool get isEmpty =>
      disc == null &&
      number == null &&
      year == null &&
      genre == null &&
      format == null &&
      folder == null;
}

/// The track the player shows, ready for display (FR-016, FR-017).
///
/// @implements FR-016.3
/// @implements FR-017.4
@immutable
final class NowPlaying {
  const new({
    required this.track,
    required this.title,
    required this.known,
    this.artist,
    this.album,
    this.artwork,
    this.details = const TrackDetails(),
  });

  factory of(Track track, Map<Track, LibraryTrack> library) {
    final stored = library[track];
    if (stored == null) {
      return NowPlaying(
        track: track,
        title: _fileName(track.relativePath),
        known: false,
      );
    }
    final info = stored.info;
    final disc = _positive(info.discNumber);
    final number = _positive(info.trackNumber);
    final year = _positive(info.year);
    final genre = _text(info.genre);
    final tagged =
        disc != null || number != null || year != null || genre != null;
    return NowPlaying(
      track: track,
      title: stored.displayTitle,
      known: true,
      artist: _text(info.artist),
      album: _text(info.album),
      artwork: stored.artwork,
      details: TrackDetails(
        disc: disc,
        number: number,
        year: year,
        genre: genre,
        format: tagged ? null : _format(info.relativePath),
        folder: tagged ? null : _folder(info.relativePath),
      ),
    );
  }

  final Track track;
  final String title;

  /// Null when the tag is missing; the screen writes "Unknown artist".
  final String? artist;
  final String? album;
  final String? artwork;
  final TrackDetails details;

  /// False when the library has no entry for the track.
  final bool known;
}

int? _positive(int? value) => value != null && value > 0 ? value : null;

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

String _fileName(String path) => path.substring(path.lastIndexOf('/') + 1);

String? _format(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toUpperCase();
}

String? _folder(String path) {
  final slash = path.lastIndexOf('/');
  if (slash <= 0) return null;
  final parent = path.substring(0, slash);
  return parent.substring(parent.lastIndexOf('/') + 1);
}
