import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/artist_list_model.dart';
import 'package:tuneshell/features/browse/library_groups.dart';

LibraryTrack t(String? artist, String album, int id) => LibraryTrack(
  id: id,
  disk: internalDisk,
  info: TrackInfo(
    relativePath: '$id.mp3',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: 't$id',
    albumArtist: artist,
    album: album,
  ),
);

ArtistListModel model(List<LibraryTrack> tracks) => ArtistListModel.build(
  LibraryGroups.build(tracks: tracks, unavailableDisks: const {}).artists,
);

void main() {
  /// @verifies FR-021.3
  group('ArtistListModel', () {
    test('a header opens each letter, the unknown artist is under #', () {
      final m = model([
        t('Clara', 'a', 1),
        t(null, 'b', 2),
        t('Anouk', 'c', 3),
        t('Arpège', 'd', 4),
        t('10cc', 'e', 5),
      ]);

      expect(
        [
          for (final item in m.items)
            switch (item) {
              ArtistHeader(:final letter) => '[$letter]',
              ArtistEntry(:final artist) => artist.unknown ? '?' : artist.name,
            },
        ],
        ['[#]', '?', '10cc', '[A]', 'Anouk', 'Arpège', '[C]', 'Clara'],
      );
    });

    test('accents fold into their letter', () {
      final m = model([t('Émile', 'a', 1), t('Edgar', 'b', 2)]);

      final headers = m.items.whereType<ArtistHeader>().map((h) => h.letter);
      expect(headers, ['E']);
    });

    test('an empty library has no item', () {
      expect(model(const []).items, isEmpty);
    });

    /// @verifies FR-021.4
    test('the offset of a letter counts the headers and rows before it', () {
      final m = model([
        t('Anouk', 'a', 1),
        t('Arpège', 'b', 2),
        t('Clara', 'c', 3),
        t('Zed', 'd', 4),
      ]);

      expect(m.offsetOf('A', headerExtent: 40, rowExtent: 64), 0);
      expect(m.offsetOf('C', headerExtent: 40, rowExtent: 64), 40 + 2 * 64);
      expect(
        m.offsetOf('Z', headerExtent: 40, rowExtent: 64),
        40 + 2 * 64 + 40 + 64,
      );
      expect(m.offsetOf('B', headerExtent: 40, rowExtent: 64), isNull);
    });

    test('the position of a row alternates the avatar tint', () {
      final m = model([t('A', 'a', 1), t('B', 'b', 2), t('C', 'c', 3)]);

      final positions = m.items.whereType<ArtistEntry>().map((e) => e.position);
      expect(positions, [0, 1, 2]);
    });
  });
}
