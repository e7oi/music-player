import 'package:flutter/foundation.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// An album: the tracks that share an album artist and a title (BR-010).
@immutable
final class AlbumGroup {
  const new({
    required this.key,
    required this.title,
    required this.artist,
    required this.unknownAlbum,
    required this.unknownArtist,
    required this.tracks,
    required this.duration,
    required this.discCount,
    required this.disks,
    required this.available,
    this.year,
    this.genre,
    this.artwork,
  });

  /// Folded identity: artist and title without case, accents or extra spaces.
  final String key;

  /// The most frequent spelling; empty when [unknownAlbum].
  final String title;

  /// The most frequent spelling; empty when [unknownArtist].
  final String artist;
  final bool unknownAlbum;
  final bool unknownArtist;

  /// In the order of BR-010, rule 6: disc, then track number. The one order
  /// of an album, shown, played and queued alike.
  final List<LibraryTrack> tracks;
  final Duration duration;
  final int discCount;

  /// The oldest known year.
  final int? year;

  /// The most frequent genre.
  final String? genre;

  /// The cover of the first track that has one.
  final String? artwork;

  /// The disks the tracks are on, in track order, without repeats.
  final List<DiskId> disks;

  /// False when every track is on an unavailable disk (BR-010, rule 9).
  final bool available;

  int get trackCount => tracks.length;
}

/// An artist: the albums that share an album artist (BR-010).
@immutable
final class ArtistGroup {
  const new({
    required this.key,
    required this.name,
    required this.unknown,
    required this.albums,
    required this.tracks,
    required this.duration,
    required this.available,
  });

  final String key;

  /// The most frequent spelling; empty when [unknown].
  final String name;
  final bool unknown;

  /// In the order of BR-010, rule 7.
  final List<AlbumGroup> albums;

  /// Every track, album by album, each in its own order.
  final List<LibraryTrack> tracks;
  final Duration duration;
  final bool available;

  int get trackCount => tracks.length;
}

/// The albums and the artists of the library, ready to show (BR-010).
///
/// @implements BR-010
@immutable
final class LibraryGroups {
  const new _({
    required this.albums,
    required this.artists,
    required this.albumLetters,
    required this.albumFirstIndex,
    required this.artistLetters,
    required this.artistFirstIndex,
  });

  /// Groups [tracks]; [unavailableDisks] are the disks that cannot be read.
  factory build({
    required List<LibraryTrack> tracks,
    required Set<DiskId> unavailableDisks,
  }) {
    final byAlbum = <String, List<LibraryTrack>>{};
    for (final track in tracks) {
      final artist = _albumArtist(track);
      final album = _text(track.info.album);
      final key =
          '${artist == null ? '' : _fold(artist)}\u0000'
          '${album == null ? '' : _fold(album)}';
      (byAlbum[key] ??= []).add(track);
    }

    final albums = [
      for (final entry in byAlbum.entries)
        _album(entry.key, entry.value, unavailableDisks),
    ]..sort(_compareAlbums);

    final byArtist = <String, List<AlbumGroup>>{};
    for (final album in albums) {
      (byArtist[album.key.split('\u0000').first] ??= []).add(album);
    }
    final artists = [
      for (final entry in byArtist.entries) _artist(entry.key, entry.value),
    ]..sort((a, b) => _artistSort(a).compareTo(_artistSort(b)));

    final albumNames = [for (final a in albums) a.artist];
    final artistNames = [for (final a in artists) a.name];
    return LibraryGroups._(
      albums: albums,
      artists: artists,
      albumLetters: buildLetters(albumNames),
      albumFirstIndex: firstIndexes(albumNames),
      artistLetters: buildLetters(artistNames),
      artistFirstIndex: firstIndexes(artistNames),
    );
  }

  /// In display order: artist, then year, then title.
  final List<AlbumGroup> albums;

  /// In display order: the unknown artist first, then by folded name.
  final List<ArtistGroup> artists;

  /// "#" then A to Z, counted over the albums (by the letter of the artist).
  final List<AlphabetLetter> albumLetters;
  final Map<String, int> albumFirstIndex;
  final List<AlphabetLetter> artistLetters;
  final Map<String, int> artistFirstIndex;
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// BR-010, rule 1.
String? _albumArtist(LibraryTrack track) =>
    _text(track.info.albumArtist) ?? _text(track.info.artist);

/// BR-010, rule 3: case, accents and runs of spaces do not count.
String _fold(String text) =>
    sortKey(text.trim().replaceAll(RegExp(r'\s+'), ' '));

AlbumGroup _album(
  String key,
  List<LibraryTrack> found,
  Set<DiskId> unavailable,
) {
  final tracks = [...found]..sort(_compareTracks);
  final artist = _mostFrequent([for (final t in tracks) ?_albumArtist(t)]);
  final title = _mostFrequent([for (final t in tracks) ?_text(t.info.album)]);
  final years = [
    for (final t in tracks)
      if (t.info.year != null && t.info.year! > 0) t.info.year!,
  ]..sort();
  final discs = {for (final t in tracks) _disc(t)};
  final disks = <DiskId>[];
  for (final t in tracks) {
    if (!disks.contains(t.disk)) disks.add(t.disk);
  }
  var duration = Duration.zero;
  for (final t in tracks) {
    duration += t.info.duration ?? Duration.zero;
  }
  return AlbumGroup(
    key: key,
    title: title ?? '',
    artist: artist ?? '',
    unknownAlbum: title == null,
    unknownArtist: artist == null,
    tracks: List.unmodifiable(tracks),
    duration: duration,
    discCount: discs.length,
    year: years.isEmpty ? null : years.first,
    genre: _mostFrequent([for (final t in tracks) ?_text(t.info.genre)]),
    artwork: tracks.map((t) => t.artwork).nonNulls.firstOrNull,
    disks: List.unmodifiable(disks),
    available: tracks.any((t) => !unavailable.contains(t.disk)),
  );
}

ArtistGroup _artist(String key, List<AlbumGroup> albums) {
  final names = <String>[
    for (final album in albums)
      if (!album.unknownArtist)
        for (var i = 0; i < album.trackCount; i++) album.artist,
  ];
  var duration = Duration.zero;
  for (final album in albums) {
    duration += album.duration;
  }
  return ArtistGroup(
    key: key,
    name: _mostFrequent(names) ?? '',
    unknown: names.isEmpty,
    albums: List.unmodifiable(albums),
    tracks: List.unmodifiable([for (final a in albums) ...a.tracks]),
    duration: duration,
    available: albums.any((a) => a.available),
  );
}

/// The value that occurs most; the first one met on a tie. Null when empty.
String? _mostFrequent(List<String> values) {
  if (values.isEmpty) return null;
  final counts = <String, int>{};
  for (final value in values) {
    counts.update(value, (n) => n + 1, ifAbsent: () => 1);
  }
  var best = values.first;
  for (final value in values) {
    if (counts[value]! > counts[best]!) best = value;
  }
  return best;
}

/// A disc number below one counts as absent, which is disc one.
int _disc(LibraryTrack track) {
  final disc = track.info.discNumber;
  return disc == null || disc < 1 ? 1 : disc;
}

/// BR-010, rule 6: disc, then track number (none after the numbered), then
/// title, then path.
int _compareTracks(LibraryTrack a, LibraryTrack b) {
  final byDisc = _disc(a).compareTo(_disc(b));
  if (byDisc != 0) return byDisc;
  final an = a.info.trackNumber;
  final bn = b.info.trackNumber;
  final aNumber = an == null || an < 1 ? null : an;
  final bNumber = bn == null || bn < 1 ? null : bn;
  if (aNumber != bNumber) {
    if (aNumber == null) return 1;
    if (bNumber == null) return -1;
    return aNumber.compareTo(bNumber);
  }
  final byTitle = sortKey(a.displayTitle).compareTo(sortKey(b.displayTitle));
  if (byTitle != 0) return byTitle;
  return a.info.relativePath.compareTo(b.info.relativePath);
}

/// The unknown artist leads: its key is shorter than any other.
String _artistSort(ArtistGroup artist) => artist.unknown ? '0' : artist.key;

/// BR-010, rule 7: artist, then year (none last), then title (an unknown
/// album last).
int _compareAlbums(AlbumGroup a, AlbumGroup b) {
  final byArtist = _artistKey(a).compareTo(_artistKey(b));
  if (byArtist != 0) return byArtist;
  final ay = a.year;
  final by = b.year;
  if (ay != by) {
    if (ay == null) return 1;
    if (by == null) return -1;
    return ay.compareTo(by);
  }
  if (a.unknownAlbum != b.unknownAlbum) return a.unknownAlbum ? 1 : -1;
  return a.key.compareTo(b.key);
}

String _artistKey(AlbumGroup album) =>
    album.unknownArtist ? '0' : album.key.split('\u0000').first;
