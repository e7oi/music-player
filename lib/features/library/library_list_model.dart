import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// Why the tracks of a disk cannot be played (BR-008, rule 1).
enum DiskIssue { absent, accessLost }

/// A disk named by the banner of unavailable sources.
@immutable
final class DiskProblem {
  const new({required this.label, required this.issue});

  final String label;
  final DiskIssue issue;
}

/// The banner "12 pistes ignorées : SSD absent" (BR-008, rules 2 and 3).
@immutable
final class SourceBanner {
  const new({
    required this.tracks,
    required this.disks,
    required this.fingerprint,
  });

  /// Tracks of the unavailable disks.
  final int tracks;
  final List<DiskProblem> disks;

  /// Identifies the state of the sources: a dismissed banner stays hidden
  /// until this changes.
  final String fingerprint;
}

/// One row of the list, ready to draw.
@immutable
final class LibraryEntry {
  const new({required this.track, required this.state, required this.disk});

  final LibraryTrack track;
  final TrackTileState state;

  /// The disk the track belongs to, for its mark and its name; null if the
  /// disk is unknown.
  final Disk? disk;
}

/// The track the "now playing" button leads to.
@immutable
final class JumpTarget {
  const new({required this.index, required this.lastPlayed});

  final int index;

  /// Nothing plays: the track is the last one played in this session.
  final bool lastPlayed;
}

/// What the library list shows, computed from the stored tracks and the state
/// around them. A pure value: every rule of FR-011 to FR-013 and BR-008 that
/// is not drawing lives here (ADR-013).
///
/// @implements FR-011
/// @implements FR-013
/// @implements BR-008
@immutable
final class LibraryListModel {
  const new _computed({
    required this.entries,
    required this.total,
    required this.unavailableCount,
    required this.banner,
    required this.letters,
    required this.firstIndex,
    required this.jumpTarget,
  });

  /// Sorts [tracks] by title without regard to case or accents (FR-011.7).
  ///
  /// [unavailable] holds the disks that cannot be read; [current] is the
  /// track of the player, [lastPlayed] the last one played in the session,
  /// [unreadable] the tracks the engine failed on in the session.
  /// [dismissedBanner] is the fingerprint of the banner the user closed.
  /// [presorted] says [tracks] already come from [sortTracks].
  factory build({
    required List<LibraryTrack> tracks,
    required List<Disk> disks,
    required Map<DiskId, DiskIssue> unavailable,
    required Set<Track> unreadable,
    Track? current,
    Track? lastPlayed,
    String? dismissedBanner,
    bool presorted = false,
  }) {
    final ordered = presorted ? tracks : sortTracks(tracks);
    final byId = {for (final disk in disks) disk.id: disk};

    final entries = [
      for (final track in ordered)
        LibraryEntry(
          track: track,
          disk: byId[track.disk],
          state: _stateOf(
            track,
            unavailable: unavailable.containsKey(track.disk),
            unreadable: unreadable.contains(track.track),
            playing: current != null && track.track == current,
          ),
        ),
    ];
    final titles = [for (final e in entries) e.track.displayTitle];
    return LibraryListModel._computed(
      entries: entries,
      total: tracks.length,
      unavailableCount: [
        for (final e in entries)
          if (e.state == TrackTileState.unavailable) e,
      ].length,
      banner: _bannerOf(entries, unavailable, byId, dismissedBanner),
      letters: buildLetters(titles),
      firstIndex: firstIndexes(titles),
      jumpTarget: _jumpTarget(entries, current, lastPlayed),
    );
  }

  /// [tracks] in display order (FR-011.7): by title without case or accents,
  /// then path, then id.
  static List<LibraryTrack> sortTracks(List<LibraryTrack> tracks) {
    final keyed = [
      for (final track in tracks)
        (key: sortKey(track.displayTitle), track: track),
    ]..sort(_compare);
    return [for (final (key: _, :track) in keyed) track];
  }

  final List<LibraryEntry> entries;
  final int total;
  final int unavailableCount;

  /// Null when nothing is unavailable, or the user closed it.
  final SourceBanner? banner;

  /// "#" then A to Z, each with its count (FR-013.1).
  final List<AlphabetLetter> letters;

  /// First position of each letter that has titles.
  final Map<String, int> firstIndex;
  final JumpTarget? jumpTarget;

  static int _compare(
    ({String key, LibraryTrack track}) a,
    ({String key, LibraryTrack track}) b,
  ) {
    final byKey = a.key.compareTo(b.key);
    if (byKey != 0) return byKey;
    final byPath = a.track.info.relativePath.compareTo(
      b.track.info.relativePath,
    );
    return byPath != 0 ? byPath : a.track.id.compareTo(b.track.id);
  }

  static TrackTileState _stateOf(
    LibraryTrack track, {
    required bool unavailable,
    required bool unreadable,
    required bool playing,
  }) {
    if (unavailable) return TrackTileState.unavailable;
    if (unreadable) return TrackTileState.unreadable;
    if (playing) return TrackTileState.playing;
    if (track.artwork == null) return TrackTileState.noArtwork;
    return TrackTileState.normal;
  }

  static SourceBanner? _bannerOf(
    List<LibraryEntry> entries,
    Map<DiskId, DiskIssue> unavailable,
    Map<DiskId, Disk> byId,
    String? dismissed,
  ) {
    final counts = <DiskId, int>{};
    for (final e in entries) {
      if (unavailable.containsKey(e.track.disk)) {
        counts.update(e.track.disk, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    if (counts.isEmpty) return null;
    final ids = counts.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final fingerprint = [
      for (final id in ids) '${id.value}:${unavailable[id]!.name}',
    ].join(',');
    if (fingerprint == dismissed) return null;
    return SourceBanner(
      tracks: counts.values.fold(0, (sum, n) => sum + n),
      disks: [
        for (final id in ids)
          DiskProblem(
            label: byId[id]?.label ?? id.value,
            issue: unavailable[id]!,
          ),
      ],
      fingerprint: fingerprint,
    );
  }

  static JumpTarget? _jumpTarget(
    List<LibraryEntry> entries,
    Track? current,
    Track? lastPlayed,
  ) {
    final wanted = current ?? lastPlayed;
    if (wanted == null) return null;
    final index = entries.indexWhere((e) => e.track.track == wanted);
    return index < 0
        ? null
        : JumpTarget(index: index, lastPlayed: current == null);
  }
}

/// Toward which side the row [index] lies, or null when part of it shows
/// (FR-013.3). [offset] is the scroll offset, [viewport] the visible height.
JumpDirection? jumpDirection({
  required int index,
  required double offset,
  required double viewport,
  required double rowExtent,
}) {
  final top = index * rowExtent;
  final bottom = top + rowExtent;
  if (bottom <= offset) return JumpDirection.up;
  if (top >= offset + viewport) return JumpDirection.down;
  return null;
}

/// The scroll offset that centres the row [index], kept within the range.
double jumpOffset({
  required int index,
  required double viewport,
  required double rowExtent,
  required double maxScroll,
}) => (index * rowExtent - (viewport - rowExtent) / 2).clamp(0, maxScroll);
