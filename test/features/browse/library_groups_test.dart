import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/library_groups.dart';

const ssd = DiskId('ssd');

var _id = 0;

LibraryTrack t(
  String title, {
  String? artist,
  String? albumArtist,
  String? album,
  int? disc,
  int? number,
  int? year,
  String? genre,
  int? seconds,
  String? artwork,
  DiskId disk = internalDisk,
  String? path,
}) => LibraryTrack(
  id: ++_id,
  disk: disk,
  artwork: artwork,
  info: TrackInfo(
    relativePath: path ?? 'Music/$title.mp3',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
    artist: artist,
    albumArtist: albumArtist,
    album: album,
    discNumber: disc,
    trackNumber: number,
    year: year,
    genre: genre,
    duration: seconds == null ? null : Duration(seconds: seconds),
  ),
);

LibraryGroups build(
  List<LibraryTrack> tracks, {
  Set<DiskId> unavailable = const {},
}) => LibraryGroups.build(tracks: tracks, unavailableDisks: unavailable);

List<String> titles(AlbumGroup album) => [
  for (final track in album.tracks) track.displayTitle,
];

void main() {
  /// @verifies BR-010
  group('BR-010 rule 1: artist of the album', () {
    test('the album artist wins, then the track artist, then unknown', () {
      final groups = build([
        t('a', albumArtist: 'Clara', artist: 'Clara feat. X', album: 'One'),
        t('b', artist: 'Nodal', album: 'Two'),
        t('c', album: 'Three'),
      ]);

      expect([
        for (final a in groups.albums) (a.artist, a.unknownArtist),
      ], containsAll([('Clara', false), ('Nodal', false), ('', true)]));
    });

    test('blank counts as missing and spaces are ignored', () {
      final groups = build([
        t('a', albumArtist: '  ', artist: ' Nodal ', album: 'One'),
      ]);

      expect(groups.albums.single.artist, 'Nodal');
    });

    test('a track artist that is only a feature has no entry of its own', () {
      final groups = build([
        t('a', albumArtist: 'Clara', artist: 'Clara feat. Theo', album: 'One'),
        t('b', albumArtist: 'Clara', artist: 'Theo', album: 'One'),
      ]);

      expect(groups.artists.map((a) => a.name), ['Clara']);
    });
  });

  /// @verifies BR-010
  group('BR-010 rules 2 and 3: albums and comparison', () {
    test('case, accents and spaces do not split an album', () {
      final groups = build([
        t('a', albumArtist: 'Clara Vey', album: 'Écrin'),
        t('b', albumArtist: 'clara  vey', album: 'ecrin '),
        t('c', albumArtist: 'CLARA VEY', album: 'ÉCRIN'),
      ]);

      expect(groups.albums, hasLength(1));
      expect(groups.artists, hasLength(1));
      expect(groups.albums.single.tracks, hasLength(3));
    });

    test('the most frequent spelling is shown, the first on a tie', () {
      final groups = build([
        t('a', albumArtist: 'Nodal', album: 'Azur'),
        t('b', albumArtist: 'NODAL', album: 'AZUR'),
        t('c', albumArtist: 'NODAL', album: 'AZUR'),
        t('d', albumArtist: 'Clara', album: 'Una'),
        t('e', albumArtist: 'CLARA', album: 'UNA'),
      ]);

      final nodal = groups.albums.firstWhere(
        (a) => a.artist.toLowerCase() == 'nodal',
      );
      final clara = groups.albums.firstWhere(
        (a) => a.artist.toLowerCase() == 'clara',
      );
      expect(nodal.artist, 'NODAL');
      expect(nodal.title, 'AZUR');
      expect(clara.artist, 'Clara');
      expect(clara.title, 'Una');
    });

    test('the same album title at two artists is two albums', () {
      final groups = build([
        t('a', albumArtist: 'Clara', album: 'Greatest Hits'),
        t('b', albumArtist: 'Nodal', album: 'Greatest Hits'),
      ]);

      expect(groups.albums, hasLength(2));
    });

    test('no album tag: one unknown album per album artist', () {
      final groups = build([
        t('a', albumArtist: 'Clara'),
        t('b', albumArtist: 'Clara'),
        t('c', albumArtist: 'Nodal'),
        t('d'),
        t('e'),
      ]);

      final unknown = groups.albums.where((a) => a.unknownAlbum).toList();
      expect(unknown, hasLength(3));
      expect(unknown.map((a) => a.tracks.length), unorderedEquals([2, 1, 2]));
    });

    test('a compilation without album artist splits by track artist', () {
      final groups = build([
        t('a', artist: 'One', album: 'Compil'),
        t('b', artist: 'Two', album: 'Compil'),
        t('c', albumArtist: 'Various Artists', artist: 'Three', album: 'Mix'),
        t('d', albumArtist: 'Various Artists', artist: 'Four', album: 'Mix'),
      ]);

      expect(groups.albums.where((a) => a.title == 'Compil'), hasLength(2));
      expect(groups.albums.where((a) => a.title == 'Mix'), hasLength(1));
    });
  });

  /// @verifies BR-010
  test('rule 4: one album over two sources keeps both', () {
    final groups = build([
      t('a', albumArtist: 'Clara', album: 'One', number: 1),
      t('b', albumArtist: 'Clara', album: 'One', number: 2, disk: ssd),
      t('c', albumArtist: 'Clara', album: 'One', number: 3, disk: ssd),
    ]);

    expect(groups.albums, hasLength(1));
    expect(groups.albums.single.disks, [internalDisk, ssd]);
  });

  /// @verifies BR-010
  /// @verifies FR-020.10
  /// @verifies FR-022.1
  group('rule 6: tracks by disc then track number', () {
    test('disc, then number, then the unnumbered by title', () {
      final groups = build([
        t('d2t1', albumArtist: 'C', album: 'A', disc: 2, number: 1),
        t('d1t3', albumArtist: 'C', album: 'A', disc: 1, number: 3),
        t('zeta', albumArtist: 'C', album: 'A', disc: 1),
        t('d1t1', albumArtist: 'C', album: 'A', disc: 1, number: 1),
        t('alpha', albumArtist: 'C', album: 'A', disc: 1),
        t('d1t2', albumArtist: 'C', album: 'A', disc: 1, number: 2),
        t('d2t2', albumArtist: 'C', album: 'A', disc: 2, number: 2),
      ]);

      expect(titles(groups.albums.single), [
        'd1t1',
        'd1t2',
        'd1t3',
        'alpha',
        'zeta',
        'd2t1',
        'd2t2',
      ]);
      expect(groups.albums.single.discCount, 2);
    });

    test('no disc number counts as disc 1; zero and negative too', () {
      final groups = build([
        t('b', albumArtist: 'C', album: 'A', number: 2),
        t('a', albumArtist: 'C', album: 'A', disc: 0, number: 1),
        t('c', albumArtist: 'C', album: 'A', disc: -1, number: 3),
        t('d', albumArtist: 'C', album: 'A', disc: 1, number: 4),
      ]);

      expect(titles(groups.albums.single), ['a', 'b', 'c', 'd']);
      expect(groups.albums.single.discCount, 1);
    });

    test('ties go to the title then the path', () {
      final groups = build([
        t('same', albumArtist: 'C', album: 'A', number: 1, path: 'z/b.mp3'),
        t('same', albumArtist: 'C', album: 'A', number: 1, path: 'z/a.mp3'),
      ]);

      expect(
        [for (final x in groups.albums.single.tracks) x.info.relativePath],
        ['z/a.mp3', 'z/b.mp3'],
      );
    });

    test('the order is the same wherever the album is read', () {
      final groups = build([
        t('t2', albumArtist: 'C', album: 'A', disc: 1, number: 2),
        t('t1', albumArtist: 'C', album: 'A', disc: 1, number: 1),
        t('u1', albumArtist: 'C', album: 'B', disc: 1, number: 1),
        t('t3', albumArtist: 'C', album: 'A', disc: 2, number: 1),
      ]);

      final album = groups.albums.firstWhere((a) => a.title == 'A');
      final artist = groups.artists.single;
      expect([
        for (final x in artist.tracks.take(3)) x.displayTitle,
      ], titles(album));
    });
  });

  /// @verifies BR-010
  group('rules 7 and 8: order and data of albums', () {
    test('albums by artist, then year with none last, then title', () {
      final groups = build([
        t('1', albumArtist: 'Nodal', album: 'Z', year: 2000),
        t('2', albumArtist: 'Clara', album: 'Late', year: 2020),
        t('3', albumArtist: 'Clara', album: 'Early', year: 2010),
        t('4', albumArtist: 'Clara', album: 'Undated'),
        t('5', albumArtist: 'Clara', album: 'Alpha'),
      ]);

      expect(groups.albums.map((a) => a.title), [
        'Early',
        'Late',
        'Alpha',
        'Undated',
        'Z',
      ]);
    });

    test('the unknown artist and digits lead, in the # group', () {
      final groups = build([
        t('1', albumArtist: 'Anouk', album: 'A'),
        t('2', albumArtist: '10cc', album: 'B'),
        t('3', album: 'C'),
      ]);

      expect(groups.artists.map((a) => a.unknown ? '?' : a.name), [
        '?',
        '10cc',
        'Anouk',
      ]);
      expect(groups.artistLetters.first.label, '#');
      expect(groups.artistLetters.first.count, 2);
    });

    test('year is the oldest known, cover the first one found', () {
      final groups = build([
        t('a', albumArtist: 'C', album: 'A', number: 1, year: 2005),
        t(
          'b',
          albumArtist: 'C',
          album: 'A',
          number: 2,
          year: 2003,
          artwork: 'two',
        ),
        t('c', albumArtist: 'C', album: 'A', number: 3, artwork: 'three'),
      ]);

      expect(groups.albums.single.year, 2003);
      expect(groups.albums.single.artwork, 'two');
    });

    test('duration sums the known ones; genre is the most frequent', () {
      final groups = build([
        t('a', albumArtist: 'C', album: 'A', seconds: 60, genre: 'Pop'),
        t('b', albumArtist: 'C', album: 'A', seconds: 90, genre: 'Rock'),
        t('c', albumArtist: 'C', album: 'A', genre: 'Rock'),
      ]);

      expect(groups.albums.single.duration, const Duration(seconds: 150));
      expect(groups.albums.single.genre, 'Rock');
    });
  });

  /// @verifies BR-010
  group('rule 9: availability', () {
    test('an album is unavailable when every track is', () {
      final groups = build(
        [
          t('a', albumArtist: 'C', album: 'Off', disk: ssd),
          t('b', albumArtist: 'C', album: 'Off', disk: ssd),
          t('c', albumArtist: 'C', album: 'Mixed'),
          t('d', albumArtist: 'C', album: 'Mixed', disk: ssd),
        ],
        unavailable: {ssd},
      );

      final off = groups.albums.firstWhere((a) => a.title == 'Off');
      final mixed = groups.albums.firstWhere((a) => a.title == 'Mixed');
      expect(off.available, isFalse);
      expect(mixed.available, isTrue);
      expect(groups.artists.single.available, isTrue);
    });

    test('an artist is unavailable when all its albums are', () {
      final groups = build(
        [t('a', albumArtist: 'Nodal', album: 'X', disk: ssd)],
        unavailable: {ssd},
      );

      expect(groups.artists.single.available, isFalse);
    });
  });

  /// @verifies FR-021.2
  test('an artist counts albums, tracks and duration', () {
    final groups = build([
      t('a', albumArtist: 'C', album: 'One', seconds: 100),
      t('b', albumArtist: 'C', album: 'One', seconds: 50),
      t('c', albumArtist: 'C', album: 'Two', seconds: 25),
    ]);

    final artist = groups.artists.single;
    expect(artist.albums, hasLength(2));
    expect(artist.trackCount, 3);
    expect(artist.duration, const Duration(seconds: 175));
  });

  /// @verifies FR-020.6
  /// @verifies FR-021.4
  group('index letters', () {
    test('albums by the letter of their artist', () {
      final groups = build([
        t('1', albumArtist: 'Anouk', album: 'A'),
        t('2', albumArtist: 'Anouk', album: 'B'),
        t('3', albumArtist: 'Émile', album: 'C'),
        t('4', albumArtist: 'Zed', album: 'D'),
      ]);

      expect(groups.albumFirstIndex['A'], 0);
      expect(groups.albumFirstIndex['E'], 2);
      expect(groups.albumFirstIndex['Z'], 3);
      expect(groups.albumLetters.firstWhere((l) => l.label == 'A').count, 2);
    });

    test('artists by their own letter', () {
      final groups = build([
        t('1', albumArtist: 'Anouk', album: 'A'),
        t('2', albumArtist: 'Zed', album: 'D'),
      ]);

      expect(groups.artistFirstIndex, {'A': 0, 'Z': 1});
    });
  });

  test('an empty library has no groups', () {
    final groups = build(const []);

    expect(groups.albums, isEmpty);
    expect(groups.artists, isEmpty);
    expect(groups.albumLetters.every((l) => !l.hasItems), isTrue);
  });

  /// @verifies BR-010
  test('rule 10: 7 500 tracks group quickly', () {
    final tracks = [
      for (var i = 0; i < 7500; i++)
        t(
          'Track $i',
          albumArtist: 'Artist ${i % 300}',
          album: 'Album ${i % 700}',
          number: i % 12,
        ),
    ];
    final watch = Stopwatch()..start();

    final groups = build(tracks);

    expect(groups.artists, hasLength(300));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
