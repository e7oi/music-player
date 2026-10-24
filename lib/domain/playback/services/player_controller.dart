import 'dart:async';
import 'dart:math';

import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/engine_issue.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/ports/audio_engine.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';

/// Plays a queue of tracks through any [AudioEngine].
///
/// Commands and events run one at a time, in arrival order, so that an
/// engine event never interleaves with a command half-way through. An engine
/// event is tied to the load it belongs to: an end of track or a failure
/// that arrives after the user already moved on is ignored.
///
/// The controller does not own the engine: whoever created the engine
/// disposes it.
///
/// @decision D2
/// @implements FR-001
/// @implements FR-002
/// @implements BR-001
/// @implements BR-002
/// @implements BR-003
/// @implements BR-009
class PlayerController {
  new({
    required this._engine,
    required this._opener,
    required this._volumes,
    Random? random,
  }) : _random = random ?? Random();

  /// FR-001: "previous" restarts the track after this much playback.
  static const restartThreshold = Duration(seconds: 3);

  /// BR-003: playback stops after this many failures in a row.
  static const maxConsecutiveFailures = 3;

  final AudioEngine _engine;
  final TrackSourceOpener _opener;
  final VolumeEvents _volumes;
  final Random _random;

  final _states = StreamController<PlayerState>.broadcast();
  final _notices = StreamController<PlaybackNotice>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  PlayerState _state = const PlayerState();
  Future<void> _tail = Future<void>.value();

  /// Incremented on every load and unload; see the class comment.
  int _load = 0;
  int _consecutiveFailures = 0;

  /// One identifier per queue entry, in queue order. A track may be in the
  /// queue twice, so the original order of the shuffle is kept in entries.
  List<int> _ids = const [];
  int _nextId = 0;

  /// The entries in their order before the shuffle (BR-009); null when the
  /// shuffle is off.
  List<int>? _origin;

  PlayerState get state => _state;

  /// Broadcast.
  Stream<PlayerState> get states => _states.stream;

  /// Broadcast.
  Stream<PlaybackNotice> get notices => _notices.stream;

  /// Reads the available disks and starts following the engine and the
  /// volumes. Volume events are queued behind the initial read, so none is
  /// lost between the two.
  Future<void> start() {
    _subscriptions.addAll([
      _volumes.events.listen((event) => _enqueueEvent(() => _onVolume(event))),
      _engine.completedStream.listen((_) {
        final load = _load;
        _enqueueEvent(() => _onCompleted(load));
      }),
      _engine.issueStream.listen(_onIssue),
      _engine.positionStream.listen(
        (position) => _emit(_state.copyWith(position: position)),
      ),
      _engine.durationStream.listen(
        (duration) => _emit(_state.copyWith(duration: () => duration)),
      ),
    ]);
    return _serial(() async {
      final disks = await _volumes.availableDisks();
      _emit(_state.copyWith(availableDisks: disks));
    });
  }

  /// Replaces the queue. Nothing is loaded until [play].
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) {
    if (tracks.isNotEmpty) RangeError.checkValidIndex(startIndex, tracks);
    return _serial(() => _setQueue(tracks, startIndex));
  }

  Future<void> play() => _serial(_play);

  Future<void> _setQueue(List<Track> tracks, int startIndex) async {
    if (_isEngaged) await _unload();
    _consecutiveFailures = 0;
    final ids = [for (var i = 0; i < tracks.length; i++) _nextId++];
    var queue = tracks;
    var queueIds = ids;
    var current = startIndex;
    if (_state.shuffle && tracks.isNotEmpty) {
      // BR-009, rule 3: the chosen track first, the others mixed behind it.
      final others = [
        for (var i = 0; i < tracks.length; i++)
          if (i != startIndex) i,
      ]..shuffle(_random);
      final order = [startIndex, ...others];
      queue = [for (final i in order) tracks[i]];
      queueIds = [for (final i in order) ids[i]];
      current = 0;
      _origin = ids;
    } else {
      _origin = _state.shuffle ? ids : null;
    }
    _ids = queueIds;
    _emit(
      _state.copyWith(
        queue: List.unmodifiable(queue),
        currentIndex: () => tracks.isEmpty ? null : current,
        status: tracks.isEmpty ? PlayerStatus.idle : PlayerStatus.stopped,
        playing: false,
        position: Duration.zero,
        duration: () => null,
      ),
    );
  }

  Future<void> _play() async {
    final index = _state.currentIndex;
    if (index == null) return;
    _emit(_state.copyWith(playing: true));
    switch (_state.status) {
      case PlayerStatus.ready:
        await _engine.play();
      case PlayerStatus.stopped:
        // A new start by the user: earlier failures no longer count.
        _consecutiveFailures = 0;
        await _loadFrom(index, 1, wrap: true);
      case PlayerStatus.loading:
      case PlayerStatus.idle:
        break;
    }
  }

  Future<void> pause() => _serial(() async {
    _emit(_state.copyWith(playing: false));
    if (_state.status == PlayerStatus.ready) await _engine.pause();
  });

  Future<void> seek(Duration position) => _serial(() async {
    if (_state.status == PlayerStatus.ready) await _engine.seek(position);
  });

  Future<void> next() => _serial(() async {
    final index = _state.currentIndex;
    if (index == null) return;
    await _loadFrom(index + 1, 1, wrap: true);
  });

  /// @implements FR-001: restart after [restartThreshold], otherwise go to
  /// the previous available track.
  Future<void> previous() => _serial(() async {
    final index = _state.currentIndex;
    if (index == null) return;
    final loaded = _state.status == PlayerStatus.ready;
    if (index == 0 || (loaded && _state.position > restartThreshold)) {
      if (loaded) await _engine.seek(Duration.zero);
      return;
    }
    await _loadFrom(index - 1, -1);
  });

  Future<void> stop() => _serial(() async {
    if (_state.currentIndex == null) return;
    await _stopPlayback();
  });

  /// Removes the track at [index] from the queue (FR-002). Returns false,
  /// without any change, when [index] is outside the queue.
  Future<bool> removeAt(int index) => _serial(() async {
    final queue = _state.queue;
    final current = _state.currentIndex;
    if (current == null || index < 0 || index >= queue.length) return false;
    final remaining = List<Track>.unmodifiable([...queue]..removeAt(index));
    final removedId = _ids[index];
    _ids = [..._ids]..removeAt(index);
    _origin = _origin?.where((id) => id != removedId).toList();
    if (index != current) {
      _emit(
        _state.copyWith(
          queue: remaining,
          currentIndex: () => index < current ? current - 1 : current,
        ),
      );
      return true;
    }
    if (remaining.isEmpty) {
      await _unload();
      _emit(
        _state.copyWith(
          queue: remaining,
          currentIndex: () => null,
          status: PlayerStatus.idle,
          playing: false,
        ),
      );
      return true;
    }
    if (index == remaining.length) {
      _emit(_state.copyWith(queue: remaining, currentIndex: () => index - 1));
      await _stopPlayback();
      return true;
    }
    final engaged = _isEngaged;
    _emit(_state.copyWith(queue: remaining, currentIndex: () => index));
    if (engaged) await _loadFrom(index, 1);
    return true;
  });

  /// Turns the shuffle on or off (BR-009, rules 1 and 2). Nothing is loaded
  /// or stopped: only the order of the tracks after the current one changes.
  Future<void> setShuffle({required bool enabled}) => _serial(() async {
    if (enabled == _state.shuffle) return;
    final current = _state.currentIndex;
    if (current == null) {
      _emit(_state.copyWith(shuffle: enabled));
      return;
    }
    final queue = _state.queue;
    if (enabled) {
      _origin = [..._ids];
      final tail = [for (var i = current + 1; i < queue.length; i++) i]
        ..shuffle(_random);
      final order = [for (var i = 0; i <= current; i++) i, ...tail];
      _ids = [for (final i in order) _ids[i]];
      _emit(
        _state.copyWith(
          queue: List.unmodifiable([for (final i in order) queue[i]]),
          shuffle: true,
        ),
      );
      return;
    }
    final origin = _origin;
    _origin = null;
    if (origin == null) {
      _emit(_state.copyWith(shuffle: false));
      return;
    }
    final byId = {for (var i = 0; i < queue.length; i++) _ids[i]: queue[i]};
    final currentId = _ids[current];
    final ids = [
      for (final id in origin)
        if (byId.containsKey(id)) id,
    ];
    _ids = ids;
    _emit(
      _state.copyWith(
        queue: List.unmodifiable([for (final id in ids) byId[id]!]),
        currentIndex: () => ids.indexOf(currentId),
        shuffle: false,
      ),
    );
  });

  Future<void> setRepeat(RepeatMode mode) => _serial(() async {
    if (mode != _state.repeat) _emit(_state.copyWith(repeat: mode));
  });

  /// Moves the track at [from] to [to] (BR-009, rule 6). Both must be after
  /// the current track; otherwise nothing changes and false is returned.
  Future<bool> move(int from, int to) => _serial(() async {
    final current = _state.currentIndex;
    final length = _state.queue.length;
    if (current == null ||
        from <= current ||
        to <= current ||
        from >= length ||
        to >= length) {
      return false;
    }
    if (from == to) return true;
    final queue = [..._state.queue];
    final ids = [..._ids];
    queue.insert(to, queue.removeAt(from));
    ids.insert(to, ids.removeAt(from));
    _ids = ids;
    _emit(_state.copyWith(queue: List.unmodifiable(queue)));
    return true;
  });

  /// Removes every track after the current one (BR-009, rule 7).
  Future<void> clearUpcoming() => _serial(() async {
    final current = _state.currentIndex;
    if (current == null || current == _state.queue.length - 1) return;
    final kept = _ids.sublist(0, current + 1).toSet();
    _ids = _ids.sublist(0, current + 1);
    _origin = _origin?.where(kept.contains).toList();
    _emit(
      _state.copyWith(
        queue: List.unmodifiable(_state.queue.sublist(0, current + 1)),
      ),
    );
  });

  /// Makes the track at [index] the current one and plays it (BR-009,
  /// rule 8). Returns false, without any change, outside the queue.
  Future<bool> skipTo(int index) => _serial(() async {
    if (_state.currentIndex == null ||
        index < 0 ||
        index >= _state.queue.length) {
      return false;
    }
    _consecutiveFailures = 0;
    _emit(_state.copyWith(playing: true));
    await _loadFrom(index, 1, wrap: true);
    return true;
  });

  /// Puts [tracks] right after the current track (BR-009, rule 11). On an
  /// empty queue they become the queue and playback starts.
  Future<void> playNext(List<Track> tracks) =>
      _serial(() => _insert(tracks, next: true));

  /// Puts [tracks] at the end of the queue (BR-009, rule 11).
  Future<void> enqueue(List<Track> tracks) =>
      _serial(() => _insert(tracks, next: false));

  Future<void> _insert(List<Track> tracks, {required bool next}) async {
    if (tracks.isEmpty) return;
    final current = _state.currentIndex;
    if (current == null) {
      await _setQueue(tracks, 0);
      await _play();
      return;
    }
    final at = next ? current + 1 : _state.queue.length;
    final ids = [for (var i = 0; i < tracks.length; i++) _nextId++];
    _ids = [..._ids]..insertAll(at, ids);
    final origin = _origin;
    if (origin != null) {
      final after = next ? origin.indexOf(_ids[current]) + 1 : origin.length;
      _origin = [...origin]..insertAll(after, ids);
    }
    _emit(
      _state.copyWith(
        queue: List.unmodifiable([..._state.queue]..insertAll(at, tracks)),
      ),
    );
  }

  /// Stops following the engine and the volumes. Does not stop the engine.
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _states.close();
    await _notices.close();
  }

  bool get _isEngaged =>
      _state.status == PlayerStatus.ready ||
      _state.status == PlayerStatus.loading;

  /// Loads the first track that can be played, starting at [index] and
  /// moving by [step]. Plays it if the intent to play is set.
  ///
  /// With [wrap], and the repetition of all tracks, a forward search that
  /// reaches the end of the queue goes on from its start up to [index] - 1
  /// (BR-009, rule 4).
  ///
  /// @implements BR-001: tracks of an unavailable disk are never opened; each
  /// run of them produces one [TracksSkipped].
  Future<void> _loadFrom(int index, int step, {bool wrap = false}) async {
    final skipped = <Track>[];
    var wrapped = false;
    var i = index;
    while (true) {
      if (i < 0 || i >= _state.queue.length) {
        if (wrap &&
            !wrapped &&
            step > 0 &&
            _state.repeat == RepeatMode.all &&
            _state.queue.isNotEmpty) {
          wrapped = true;
          i = 0;
          continue;
        }
        break;
      }
      if (wrapped && i >= index) break;
      final track = _state.queue[i];
      if (!_state.availableDisks.contains(track.disk)) {
        skipped.add(track);
        i += step;
        continue;
      }
      _reportSkipped(skipped);
      _load++;
      _emit(
        _state.copyWith(
          currentIndex: () => i,
          status: PlayerStatus.loading,
          position: Duration.zero,
          duration: () => null,
        ),
      );
      final MediaSource source;
      try {
        source = await _opener.open(track);
      } on TrackSourceException catch (e) {
        final failure = EngineFailure(EngineFailureKind.openFailed, e.message);
        if (await _fail(track, failure)) return;
        i += step;
        continue;
      }
      await _engine.open(source);
      // A late position of the previous track must not count for "previous".
      _emit(
        _state.copyWith(status: PlayerStatus.ready, position: Duration.zero),
      );
      if (_state.playing) await _engine.play();
      return;
    }
    _reportSkipped(skipped);
    if (step < 0 && _state.status == PlayerStatus.ready) {
      // Nothing playable before and nothing attempted: restart the current
      // track. Once a load was attempted, the engine may still be playing
      // another track than the state says, so playback stops instead.
      await _engine.seek(Duration.zero);
      return;
    }
    await _stopPlayback();
  }

  void _reportSkipped(List<Track> skipped) {
    if (skipped.isEmpty) return;
    _notify(
      TracksSkipped(
        count: skipped.length,
        disks: {for (final track in skipped) track.disk},
      ),
    );
    skipped.clear();
  }

  /// Reports [failure] for [track]. Returns true when playback stopped
  /// because of too many failures in a row (BR-003).
  Future<bool> _fail(Track track, EngineFailure failure) async {
    _notify(TrackFailed(track: track, failure: failure));
    _consecutiveFailures++;
    if (_consecutiveFailures < maxConsecutiveFailures) return false;
    final count = _consecutiveFailures;
    _consecutiveFailures = 0;
    await _stopPlayback();
    _notify(PlaybackStoppedAfterFailures(count));
    return true;
  }

  Future<void> _stopPlayback() async {
    await _unload();
    _emit(_state.copyWith(status: PlayerStatus.stopped, playing: false));
  }

  Future<void> _unload() async {
    _load++;
    await _engine.stop();
  }

  Future<void> _onCompleted(int load) async {
    if (load != _load) return;
    _consecutiveFailures = 0;
    final index = _state.currentIndex;
    if (index == null) return;
    // BR-009, rule 4: the same track starts again; an unavailable one is
    // left behind by the usual skipping.
    if (_state.repeat == RepeatMode.one) {
      await _loadFrom(index, 1);
      return;
    }
    await _loadFrom(index + 1, 1, wrap: true);
  }

  void _onIssue(EngineIssue issue) {
    switch (issue) {
      case EngineWarning():
        _emit(_state.copyWith(warningCount: _state.warningCount + 1));
      case EngineFailure():
        final load = _load;
        _enqueueEvent(() => _onFailure(issue, load));
    }
  }

  Future<void> _onFailure(EngineFailure failure, int load) async {
    final track = _state.currentTrack;
    final index = _state.currentIndex;
    if (load != _load || track == null || index == null) return;
    if (await _fail(track, failure)) return;
    await _loadFrom(index + 1, 1, wrap: true);
  }

  /// @implements BR-002: the engine is stopped, and its stop awaited, before
  /// the disk of the current track is marked unavailable. Playback stays
  /// stopped and does not resume when the disk comes back.
  Future<void> _onVolume(VolumeEvent event) async {
    final available = _state.availableDisks;
    switch (event) {
      case VolumeMounted(:final disk):
        _emit(_state.copyWith(availableDisks: {...available, disk}));
      case VolumeEjecting(:final disk) || VolumeRemoved(:final disk):
        if (!available.contains(disk)) return;
        final playingFromDisk = _state.currentTrack?.disk == disk && _isEngaged;
        if (playingFromDisk) await _stopPlayback();
        _emit(_state.copyWith(availableDisks: {...available}..remove(disk)));
        if (playingFromDisk) _notify(PlaybackStoppedByEjection(disk));
    }
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Engine and volume events have no caller to report to: an error escapes
  /// to the zone, where the app logs it.
  void _enqueueEvent(Future<void> Function() action) =>
      unawaited(_serial(action));

  void _notify(PlaybackNotice notice) {
    if (!_notices.isClosed) _notices.add(notice);
  }

  void _emit(PlayerState state) {
    _state = state.copyWith(entryIds: _ids);
    if (!_states.isClosed) _states.add(state);
  }
}
