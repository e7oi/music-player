import 'dart:async';

import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/engine_issue.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
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
class PlayerController {
  new({required this._engine, required this._opener, required this._volumes});

  /// FR-001: "previous" restarts the track after this much playback.
  static const restartThreshold = Duration(seconds: 3);

  /// BR-003: playback stops after this many failures in a row.
  static const maxConsecutiveFailures = 3;

  final AudioEngine _engine;
  final TrackSourceOpener _opener;
  final VolumeEvents _volumes;

  final _states = StreamController<PlayerState>.broadcast();
  final _notices = StreamController<PlaybackNotice>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  PlayerState _state = const PlayerState();
  Future<void> _tail = Future<void>.value();

  /// Incremented on every load and unload; see the class comment.
  int _load = 0;
  int _consecutiveFailures = 0;

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
    return _serial(() async {
      if (_isEngaged) await _unload();
      _consecutiveFailures = 0;
      _emit(
        _state.copyWith(
          queue: List.unmodifiable(tracks),
          currentIndex: () => tracks.isEmpty ? null : startIndex,
          status: tracks.isEmpty ? PlayerStatus.idle : PlayerStatus.stopped,
          playing: false,
          position: Duration.zero,
          duration: () => null,
        ),
      );
    });
  }

  Future<void> play() => _serial(() async {
    final index = _state.currentIndex;
    if (index == null) return;
    _emit(_state.copyWith(playing: true));
    switch (_state.status) {
      case PlayerStatus.ready:
        await _engine.play();
      case PlayerStatus.stopped:
        // A new start by the user: earlier failures no longer count.
        _consecutiveFailures = 0;
        await _loadFrom(index, 1);
      case PlayerStatus.loading:
      case PlayerStatus.idle:
        break;
    }
  });

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
    await _loadFrom(index + 1, 1);
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
  /// @implements BR-001: tracks of an unavailable disk are never opened; each
  /// run of them produces one [TracksSkipped].
  Future<void> _loadFrom(int index, int step) async {
    final skipped = <Track>[];
    for (var i = index; i >= 0 && i < _state.queue.length; i += step) {
      final track = _state.queue[i];
      if (!_state.availableDisks.contains(track.disk)) {
        skipped.add(track);
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
    await _loadFrom(index + 1, 1);
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
    await _loadFrom(index + 1, 1);
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
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}
