import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/services/library_indexer.dart';

import '../../fakes/fake_library.dart';

void main() {
  late FakeLibraryRepository repository;
  late FakeInternalAudioSource source;
  late LibraryIndexer indexer;

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/Album A/01.flac'),
        info('Music/Album A/02.flac'),
        info('Music/single.mp3'),
        info('Ringtones/ring.ogg'),
        info('Android/media/com.example.chat/Voice/note.opus'),
        info('root.mp3'),
      ];
    indexer = LibraryIndexer(repository: repository, source: source);
  });

  group('FR-003 folder choice', () {
    /// @verifies FR-003
    test('lists top-level folders with their file counts', () async {
      final folders = await indexer.availableFolders();

      expect(
        {for (final f in folders) f.path: f.fileCount},
        {'Music': 3, 'Ringtones': 1, 'Android': 1, '': 1},
      );
    });

    /// @verifies FR-003
    test('proposes Music by default when it exists', () async {
      final folders = await indexer.availableFolders();

      expect(LibraryIndexer.defaultSelection(folders), {'Music'});
    });

    test('proposes Music whatever its case', () async {
      source.files = [info('music/a.mp3')];
      final folders = await indexer.availableFolders();

      expect(LibraryIndexer.defaultSelection(folders), {'music'});
    });

    test('proposes nothing when there is no Music folder', () async {
      source.files = [info('Download/a.mp3')];
      final folders = await indexer.availableFolders();

      expect(LibraryIndexer.defaultSelection(folders), isEmpty);
    });

    /// @verifies FR-003
    test('asks for a folder choice until the user confirmed one', () async {
      expect(await indexer.needsFolderChoice(), isTrue);

      await indexer.chooseFolders({});

      expect(await indexer.needsFolderChoice(), isFalse);
    });

    /// @verifies FR-003
    test('indexes only the chosen folders, subfolders included', () async {
      final result = await indexer.chooseFolders({'Music'});

      expect(result.added, 3);
      expect(
        repository.tracks.map((t) => t.info.relativePath),
        unorderedEquals([
          'Music/Album A/01.flac',
          'Music/Album A/02.flac',
          'Music/single.mp3',
        ]),
      );
      expect(repository.tracks.map((t) => t.disk).toSet(), {internalDisk});
    });

    /// @verifies FR-003
    test('the root folder only holds files directly at the root', () async {
      await indexer.chooseFolders({''});

      expect(repository.tracks.map((t) => t.info.relativePath), ['root.mp3']);
    });

    /// @verifies FR-003
    test('a folder name is not a prefix match', () async {
      source.files = [info('Music/a.mp3'), info('Musicals/b.mp3')];

      await indexer.chooseFolders({'Music'});

      expect(repository.tracks.map((t) => t.info.relativePath), [
        'Music/a.mp3',
      ]);
    });

    /// @verifies FR-003
    test(
      'unchecking a folder removes its tracks and keeps the others',
      () async {
        await indexer.chooseFolders({'Music', 'Ringtones'});
        final kept = repository.tracks.firstWhere(
          (t) => t.info.relativePath == 'Music/single.mp3',
        );

        final result = await indexer.chooseFolders({'Music'});

        expect(result.removed, 1);
        expect(
          repository.tracks.any(
            (t) => t.info.relativePath.startsWith('Ringtones/'),
          ),
          isFalse,
        );
        expect(
          repository.tracks
              .firstWhere((t) => t.info.relativePath == 'Music/single.mp3')
              .id,
          kept.id,
        );
      },
    );

    test('the chosen folders are remembered', () async {
      await indexer.chooseFolders({'Music', 'Ringtones'});

      expect(await indexer.chosenFolders(), {'Music', 'Ringtones'});
    });
  });

  group('FR-003 reindexing', () {
    /// @verifies FR-003
    test('index adds new files and keeps the ids of the others', () async {
      await indexer.chooseFolders({'Music'});
      final before = {
        for (final t in repository.tracks) t.info.relativePath: t.id,
      };
      source.files = [...source.files, info('Music/new.mp3')];

      final result = await indexer.index();

      expect(result.added, 1);
      for (final t in repository.tracks) {
        if (before.containsKey(t.info.relativePath)) {
          expect(t.id, before[t.info.relativePath]);
        }
      }
    });

    /// @verifies FR-003
    test('index updates changed files and removes deleted ones', () async {
      await indexer.chooseFolders({'Music'});
      source.files = [
        info('Music/Album A/01.flac', title: 'New title', modified: 2),
        info('Music/single.mp3'),
      ];

      final result = await indexer.index();

      expect(result.updated, 1);
      expect(result.removed, 1);
      expect(
        repository.tracks
            .firstWhere((t) => t.info.relativePath == 'Music/Album A/01.flac')
            .displayTitle,
        'New title',
      );
    });

    /// @verifies BR-004
    test(
      'an empty MediaStore keeps the library instead of emptying it',
      () async {
        await indexer.chooseFolders({'Music'});
        source.files = [];

        await expectLater(
          indexer.index(),
          throwsA(isA<EmptySourceException>()),
        );

        expect(repository.tracks, hasLength(3));
      },
    );

    test('index does nothing before the folder choice', () async {
      final result = await indexer.index();

      expect(result.added, 0);
      expect(source.queries, 0);
    });

    /// @verifies FR-003
    test('concurrent indexing runs one after the other', () async {
      await indexer.chooseFolders({'Music'});

      final results = await Future.wait([indexer.index(), indexer.index()]);

      expect(results.map((r) => r.added), [0, 0]);
      expect(repository.tracks, hasLength(3));
    });
  });

  group('display title', () {
    /// @verifies FR-003
    test('falls back to the file name when the title is empty', () {
      final track = LibraryTrack(
        id: 1,
        disk: internalDisk,
        info: info('Music/Album/03 Song.flac', title: ''),
      );

      expect(track.displayTitle, '03 Song.flac');
    });
  });
}
