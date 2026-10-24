import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// One line of the queue sheet.
@immutable
final class QueueRow {
  const new({
    required this.track,
    required this.queueIndex,
    required this.title,
    required this.available,
    required this.id,
    this.artist,
    this.duration,
    this.disk,
    this.artwork,
  });

  final Track track;

  /// Stable identity of the entry in the queue (PlayerState.entryIds).
  final int id;

  /// Position in the player's queue.
  final int queueIndex;
  final String title;
  final String? artist;
  final Duration? duration;
  final Disk? disk;
  final String? artwork;

  /// False when the disk of the track is absent: the player will skip it.
  final bool available;
}

/// What the queue sheet shows (FR-018). The rows are made on demand: the
/// queue of a long library has thousands of them.
///
/// @implements FR-018
class QueueModel {
  new _(
    this._queue,
    this._currentIndex,
    this._lookup,
    this._disks,
    this._available,
    this._entryIds,
    this.totalDuration,
  );

  factory build({
    required List<Track> queue,
    required int? currentIndex,
    required Map<Track, LibraryTrack> lookup,
    required List<Disk> disks,
    required Set<DiskId> availableDisks,
    List<int> entryIds = const [],
  }) {
    var total = Duration.zero;
    for (final track in queue) {
      total += lookup[track]?.info.duration ?? Duration.zero;
    }
    return QueueModel._(
      queue,
      currentIndex,
      lookup,
      {for (final disk in disks) disk.id: disk},
      availableDisks,
      entryIds,
      total,
    );
  }

  final List<Track> _queue;
  final int? _currentIndex;
  final Map<Track, LibraryTrack> _lookup;
  final Map<DiskId, Disk> _disks;
  final Set<DiskId> _available;
  final List<int> _entryIds;

  /// The sum of the durations that are known (FR-018.2).
  final Duration totalDuration;

  int get total => _queue.length;

  QueueRow? get current {
    final index = _currentIndex;
    return index == null ? null : _row(index);
  }

  /// Tracks after the current one.
  int get upcomingCount {
    final index = _currentIndex;
    return index == null ? 0 : _queue.length - index - 1;
  }

  /// The [n]th track after the current one.
  QueueRow upcoming(int n) {
    RangeError.checkValidIndex(n, List<void>.filled(upcomingCount, null));
    return _row(_currentIndex! + 1 + n);
  }

  QueueRow _row(int index) {
    final track = _queue[index];
    final stored = _lookup[track];
    final path = track.relativePath;
    final artist = stored?.info.artist?.trim();
    return QueueRow(
      track: track,
      queueIndex: index,
      id: index < _entryIds.length ? _entryIds[index] : index,
      title: stored?.displayTitle ?? path.substring(path.lastIndexOf('/') + 1),
      artist: artist == null || artist.isEmpty ? null : artist,
      duration: stored?.info.duration,
      disk: _disks[track.disk],
      artwork: stored?.artwork,
      available: _available.contains(track.disk),
    );
  }
}
