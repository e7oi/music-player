import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/now_playing.dart';

LibraryTrack library(
  String path, {
  String? title,
  String? artist,
  String? album,
  int? disc,
  int? number,
  int? year,
  String? genre,
  String? artwork,
  DiskId disk = internalDisk,
}) => LibraryTrack(
  id: 1,
  disk: disk,
  artwork: artwork,
  info: TrackInfo(
    relativePath: path,
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
    artist: artist,
    album: album,
    discNumber: disc,
    trackNumber: number,
    year: year,
    genre: genre,
  ),
);

void main() {
  /// @verifies FR-017.4
  group('NowPlaying', () {
    test('takes title, artist, album and cover from the library', () {
      final track = library(
        'Music/a.flac',
        title: 'Dawn',
        artist: 'Mists',
        album: 'Shore',
        artwork: 'abc',
      );

      final now = NowPlaying.of(track.track, {track.track: track});

      expect(now.title, 'Dawn');
      expect(now.artist, 'Mists');
      expect(now.album, 'Shore');
      expect(now.artwork, 'abc');
      expect(now.known, isTrue);
    });

    test('a track the library does not know shows its file name', () {
      const track = Track(disk: internalDisk, relativePath: 'Music/x/y.mp3');

      final now = NowPlaying.of(track, const {});

      expect(now.title, 'y.mp3');
      expect(now.artist, isNull);
      expect(now.known, isFalse);
      expect(now.details.isEmpty, isTrue);
    });

    test('no title shows the file name', () {
      final track = library('Music/01 - raw.flac');

      final now = NowPlaying.of(track.track, {track.track: track});

      expect(now.title, '01 - raw.flac');
    });

    test('blank artist and album count as missing', () {
      final track = library('a.mp3', artist: '', album: ' ');

      final now = NowPlaying.of(track.track, {track.track: track});

      expect(now.artist, isNull);
      expect(now.album, isNull);
    });

    test('keeps the tags it knows for the details line', () {
      final track = library(
        'a.flac',
        disc: 1,
        number: 3,
        year: 2019,
        genre: 'Ambient',
      );

      final details = NowPlaying.of(track.track, {track.track: track}).details;

      expect(details.disc, 1);
      expect(details.number, 3);
      expect(details.year, 2019);
      expect(details.genre, 'Ambient');
      expect(details.format, isNull);
      expect(details.folder, isNull);
    });

    test('without any of the four tags: format and folder', () {
      final track = library('Download/01 - untitled.flac');

      final details = NowPlaying.of(track.track, {track.track: track}).details;

      expect(details.format, 'FLAC');
      expect(details.folder, 'Download');
      expect(details.disc, isNull);
    });

    test('folder is the direct parent, none at the root', () {
      final deep = library('Music/Pop/Live/a.mp3');
      final root = library('a.m4a');

      expect(
        NowPlaying.of(deep.track, {deep.track: deep}).details.folder,
        'Live',
      );
      final rootDetails = NowPlaying.of(root.track, {root.track: root}).details;
      expect(rootDetails.folder, isNull);
      expect(rootDetails.format, 'M4A');
    });

    test('no extension, no format', () {
      final track = library('Music/noext');

      final details = NowPlaying.of(track.track, {track.track: track}).details;

      expect(details.format, isNull);
    });

    test('zero or negative numbers are not shown', () {
      final track = library('Music/a.mp3', disc: 0, number: -1, year: 0);

      final details = NowPlaying.of(track.track, {track.track: track}).details;

      expect(details.disc, isNull);
      expect(details.number, isNull);
      expect(details.year, isNull);
      expect(details.format, 'MP3');
    });
  });

  /// @verifies FR-017.6
  group('clock', () {
    test('formats minutes and seconds', () {
      expect(formatClock(Duration.zero), '0:00');
      expect(formatClock(const Duration(seconds: 98)), '1:38');
      expect(formatClock(const Duration(minutes: 12, seconds: 5)), '12:05');
    });

    test('formats hours', () {
      expect(
        formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('negative counts as zero', () {
      expect(formatClock(const Duration(seconds: -4)), '0:00');
    });
  });
}
