import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

import '../../fakes/fake_library.dart';

const _ssd = DiskId('SSD-1');
const _card = DiskId('CARD-2');

String _title(int i) {
  final letter = String.fromCharCode(65 + i % 26);
  return '$letter${i.toString().padLeft(3, '0')}';
}

LibraryTrack track(
  int id,
  String title, {
  DiskId disk = internalDisk,
  String path = '',
  String? artwork,
}) => LibraryTrack(
  id: id,
  disk: disk,
  info: info(path.isEmpty ? '$id.mp3' : path, title: title),
  artwork: artwork,
);

LibraryListModel build(
  List<LibraryTrack> tracks, {
  Map<DiskId, DiskIssue> unavailable = const {},
  Track? current,
  Track? lastPlayed,
  Set<Track> unreadable = const {},
  String? dismissedBanner,
}) => LibraryListModel.build(
  tracks: tracks,
  disks: const [
    Disk.internal,
    Disk(id: _ssd, label: 'SSD', kind: DiskKind.removable, markIndex: 0),
    Disk(id: _card, label: 'Card', kind: DiskKind.removable, markIndex: 1),
  ],
  unavailable: unavailable,
  current: current,
  lastPlayed: lastPlayed,
  unreadable: unreadable,
  dismissedBanner: dismissedBanner,
);

void main() {
  /// @verifies FR-011.7
  group('order', () {
    List<String> titles(LibraryListModel model) => [
      for (final e in model.entries) e.track.displayTitle,
    ];

    test('accents and case do not move a title out of its letter', () {
      final model = build([
        track(1, 'Zèbre'),
        track(2, 'Écris-moi'),
        track(3, 'eclipse'),
        track(4, 'Fanfare'),
        track(5, 'Echo'),
      ]);

      expect(titles(model), [
        'Echo',
        'eclipse',
        'Écris-moi',
        'Fanfare',
        'Zèbre',
      ]);
    });

    test('digits and symbols come first, as the # group', () {
      final model = build([
        track(1, 'Alpha'),
        track(2, '"Nemesis"'),
        track(3, '01 - piste'),
        track(4, '(Secret)'),
      ]);

      expect(titles(model).take(3).toSet(), {
        '"Nemesis"',
        '01 - piste',
        '(Secret)',
      });
      expect(titles(model).last, 'Alpha');
    });

    test(
      'equal titles are ordered by path, then id, so the list is stable',
      () {
        final model = build([
          track(9, 'Same', path: 'b.mp3'),
          track(3, 'Same', path: 'a.mp3'),
          track(7, 'Same', path: 'a.mp3', disk: _ssd),
        ]);

        expect([for (final e in model.entries) e.track.id], [3, 7, 9]);
      },
    );

    test('a track without a title is sorted by its file name', () {
      final model = build([
        track(1, 'Beta'),
        LibraryTrack(id: 2, disk: internalDisk, info: info('Music/Alpha.flac')),
      ]);

      expect(model.entries.first.track.id, 2);
    });
  });

  /// @verifies FR-011.6
  group('states', () {
    test('a normal track', () {
      final model = build([track(1, 'A', artwork: 'art')]);

      expect(model.entries.single.state, TrackTileState.normal);
    });

    test('no artwork', () {
      expect(
        build([track(1, 'A')]).entries.single.state,
        TrackTileState.noArtwork,
      );
    });

    test('playing', () {
      final tracks = [track(1, 'A', artwork: 'x'), track(2, 'B', artwork: 'x')];

      final model = build(tracks, current: tracks[1].track);

      expect(model.entries.map((e) => e.state), [
        TrackTileState.normal,
        TrackTileState.playing,
      ]);
    });

    test('unavailable beats every other state', () {
      final tracks = [track(1, 'A', disk: _ssd, artwork: 'x')];

      final model = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent},
        current: tracks.single.track,
        unreadable: {tracks.single.track},
      );

      expect(model.entries.single.state, TrackTileState.unavailable);
    });

    test('unreadable beats playing', () {
      final tracks = [track(1, 'A', artwork: 'x')];

      final model = build(
        tracks,
        current: tracks.single.track,
        unreadable: {tracks.single.track},
      );

      expect(model.entries.single.state, TrackTileState.unreadable);
    });

    test('every entry knows its disk, for the mark and the name', () {
      final model = build([
        track(1, 'A'),
        track(2, 'B', disk: _ssd),
        track(3, 'C', disk: _card),
      ]);

      expect(
        [for (final e in model.entries) (e.disk?.label, e.disk?.markIndex)],
        [('Local', null), ('SSD', 0), ('Card', 1)],
      );
    });

    test('an unknown disk gives no disk, not a crash', () {
      final model = build([track(1, 'A', disk: const DiskId('GONE'))]);

      expect(model.entries.single.disk, isNull);
    });
  });

  /// @verifies FR-011.5
  group('counts', () {
    test('total and unavailable', () {
      final model = build(
        [track(1, 'A'), track(2, 'B', disk: _ssd), track(3, 'C', disk: _ssd)],
        unavailable: {_ssd: DiskIssue.absent},
      );

      expect((model.total, model.unavailableCount), (3, 2));
    });

    test('none unavailable', () {
      expect(build([track(1, 'A')]).unavailableCount, 0);
    });
  });

  /// @verifies BR-008
  group('banner', () {
    final tracks = [
      track(1, 'A'),
      track(2, 'B', disk: _ssd),
      track(3, 'C', disk: _ssd),
      track(4, 'D', disk: _card),
    ];

    test('none when everything is available', () {
      expect(build(tracks).banner, isNull);
    });

    test('one absent disk: its name and the number of tracks', () {
      final banner = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent},
      ).banner!;

      expect(banner.tracks, 2);
      expect(
        [for (final d in banner.disks) (d.label, d.issue)],
        [('SSD', DiskIssue.absent)],
      );
    });

    test('several disks and a lost access are all listed', () {
      final banner = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent, _card: DiskIssue.accessLost},
      ).banner!;

      expect(banner.tracks, 3);
      expect(banner.disks, hasLength(2));
      expect(banner.disks.map((d) => d.issue).toSet(), {
        DiskIssue.absent,
        DiskIssue.accessLost,
      });
    });

    test('a disk without tracks gives no banner', () {
      final model = build(
        [track(1, 'A')],
        unavailable: {_ssd: DiskIssue.absent},
      );

      expect(model.banner, isNull);
    });

    /// @verifies BR-008.3
    test('dismissed until the state of the sources changes', () {
      final first = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent},
      ).banner!;

      final same = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent},
        dismissedBanner: first.fingerprint,
      );
      final changed = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent, _card: DiskIssue.absent},
        dismissedBanner: first.fingerprint,
      );

      expect(same.banner, isNull);
      expect(changed.banner, isNotNull);
    });

    test('the fingerprint does not depend on the order of the disks', () {
      final a = build(
        tracks,
        unavailable: {_ssd: DiskIssue.absent, _card: DiskIssue.absent},
      ).banner!;
      final b = build(
        tracks,
        unavailable: {_card: DiskIssue.absent, _ssd: DiskIssue.absent},
      ).banner!;

      expect(a.fingerprint, b.fingerprint);
    });
  });

  /// @verifies FR-013.1
  group('index', () {
    test('letters count the titles and first indexes point into the list', () {
      final model = build([
        track(1, 'Alpha'),
        track(2, 'Écris'),
        track(3, 'Echo'),
        track(4, '01'),
      ]);

      expect(model.letters.firstWhere((l) => l.label == 'E').count, 2);
      expect(model.letters.firstWhere((l) => l.label == '#').count, 1);
      expect(model.firstIndex['#'], 0);
      expect(model.firstIndex['A'], 1);
      expect(model.firstIndex['E'], 2);
      expect(model.firstIndex.containsKey('Z'), isFalse);
    });

    test('the first index of each letter is the first track of it', () {
      final tracks = [for (var i = 0; i < 60; i++) track(i, _title(i))];

      final model = build(tracks);

      for (final entry in model.firstIndex.entries) {
        final title = model.entries[entry.value].track.displayTitle;
        expect(
          title.toUpperCase().startsWith(entry.key),
          isTrue,
          reason: entry.key,
        );
        if (entry.value > 0) {
          final before = model.entries[entry.value - 1].track.displayTitle;
          expect(before.toUpperCase().startsWith(entry.key), isFalse);
        }
      }
    });
  });

  /// @verifies FR-013.3
  group('jump target', () {
    final tracks = [track(1, 'A'), track(2, 'B'), track(3, 'C')];

    test('the track being played', () {
      final model = build(tracks, current: tracks[2].track);

      expect(model.jumpTarget?.index, 2);
      expect(model.jumpTarget?.lastPlayed, isFalse);
    });

    /// @verifies FR-013.4
    test('the last played one when nothing plays', () {
      final model = build(tracks, lastPlayed: tracks[1].track);

      expect(model.jumpTarget?.index, 1);
      expect(model.jumpTarget?.lastPlayed, isTrue);
    });

    test('the current track wins over the last played', () {
      final model = build(
        tracks,
        current: tracks[0].track,
        lastPlayed: tracks[1].track,
      );

      expect(model.jumpTarget?.index, 0);
    });

    /// @verifies FR-013.5
    test('none when the track is not in the list', () {
      final model = build(
        tracks,
        current: const Track(disk: internalDisk, relativePath: 'gone.mp3'),
      );

      expect(model.jumpTarget, isNull);
    });

    test('none without a current or last played track', () {
      expect(build(tracks).jumpTarget, isNull);
    });
  });

  /// @verifies FR-013.3
  group('where the track is on the screen', () {
    const row = 64.0;
    const viewport = 640.0;

    test('inside the viewport: no button', () {
      expect(
        jumpDirection(
          index: 12,
          offset: 640,
          viewport: viewport,
          rowExtent: row,
        ),
        isNull,
      );
    });

    test('a row that shows even in part counts as visible', () {
      // Row 9 spans 576 to 640: the viewport starts at 600.
      expect(
        jumpDirection(
          index: 9,
          offset: 600,
          viewport: viewport,
          rowExtent: row,
        ),
        isNull,
      );
    });

    test('above the viewport: the button points up', () {
      expect(
        jumpDirection(
          index: 3,
          offset: 640,
          viewport: viewport,
          rowExtent: row,
        ),
        JumpDirection.up,
      );
    });

    test('below the viewport: the button points down', () {
      expect(
        jumpDirection(index: 40, offset: 0, viewport: viewport, rowExtent: row),
        JumpDirection.down,
      );
    });

    test('a row ending exactly at the top edge is out of view', () {
      expect(
        jumpDirection(
          index: 9,
          offset: 640,
          viewport: viewport,
          rowExtent: row,
        ),
        JumpDirection.up,
      );
    });

    test('the jump centres the row, within the scroll range', () {
      expect(
        jumpOffset(
          index: 20,
          viewport: viewport,
          rowExtent: row,
          maxScroll: 5000,
        ),
        20 * row - (viewport - row) / 2,
      );
      expect(
        jumpOffset(
          index: 0,
          viewport: viewport,
          rowExtent: row,
          maxScroll: 5000,
        ),
        0,
      );
      expect(
        jumpOffset(
          index: 90,
          viewport: viewport,
          rowExtent: row,
          maxScroll: 5000,
        ),
        5000,
      );
    });
  });
}
