import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';

enum PlayerStatus {
  /// Empty queue.
  idle,

  /// A track is being opened.
  loading,

  /// A track is loaded, paused or playing.
  ready,

  /// The queue is kept but nothing is loaded: end of queue, stop command,
  /// ejection, too many failures.
  stopped,
}

@immutable
final class PlayerState {
  const new({
    this.queue = const [],
    this.currentIndex,
    this.status = PlayerStatus.idle,
    this.playing = false,
    this.position = Duration.zero,
    this.duration,
    this.availableDisks = const {},
    this.warningCount = 0,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
    this.entryIds = const [],
  });

  final List<Track> queue;
  final int? currentIndex;
  final PlayerStatus status;

  /// The intent to play (FR-001): stays true while the next track loads.
  final bool playing;

  final Duration position;

  /// Null while unknown.
  final Duration? duration;

  /// Disks whose tracks can be played; the others are skipped (BR-001).
  final Set<DiskId> availableDisks;

  /// Engine warnings since the controller started (BR-003).
  final int warningCount;

  /// The tracks after the current one were mixed (BR-009).
  final bool shuffle;

  final RepeatMode repeat;

  /// One stable identifier per queue entry, in queue order: a row keeps its
  /// identity when the queue is reordered, and a track queued twice has two.
  final List<int> entryIds;

  Track? get currentTrack {
    final index = currentIndex;
    return index == null ? null : queue[index];
  }

  PlayerState copyWith({
    List<Track>? queue,
    int? Function()? currentIndex,
    PlayerStatus? status,
    bool? playing,
    Duration? position,
    Duration? Function()? duration,
    Set<DiskId>? availableDisks,
    int? warningCount,
    bool? shuffle,
    RepeatMode? repeat,
    List<int>? entryIds,
  }) => PlayerState(
    queue: queue ?? this.queue,
    currentIndex: currentIndex == null ? this.currentIndex : currentIndex(),
    status: status ?? this.status,
    playing: playing ?? this.playing,
    position: position ?? this.position,
    duration: duration == null ? this.duration : duration(),
    availableDisks: availableDisks ?? this.availableDisks,
    warningCount: warningCount ?? this.warningCount,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    entryIds: entryIds ?? this.entryIds,
  );

  @override
  String toString() =>
      'PlayerState(${status.name}, index: $currentIndex/${queue.length}, '
      'playing: $playing)';
}
