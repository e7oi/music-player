import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

/// Finds the library information of a track; null when it is not known.
typedef TrackDescriber = LibraryTrack? Function(Track track);

/// The media session of Android (notification, lock screen, media buttons)
/// over the [PlayerController] (ADR-006). It holds no playback logic: every
/// command goes to the controller, and the session shows the controller's
/// state.
///
/// @implements FR-005
class PlayerAudioHandler extends BaseAudioHandler with SeekHandler {
  new(
    this._controller, {
    required this._describe,
    this._clock = DateTime.now,
    this._stopGrace = const Duration(milliseconds: 500),
  }) {
    _subscription = _controller.states.listen(_show);
    _show(_controller.state);
  }

  /// A position this far from the one the system extrapolates is a seek or a
  /// jump: it is sent; regular progress is not.
  static const _positionTolerance = Duration(milliseconds: 1500);

  final PlayerController _controller;
  final TrackDescriber _describe;
  final DateTime Function() _clock;

  /// Choosing another track goes through "stopped" for an instant: the
  /// session is released only when the player stays stopped this long, so
  /// that the notification does not disappear and come back.
  final Duration _stopGrace;

  late final StreamSubscription<PlayerState> _subscription;
  Timer? _release;

  Track? _shownTrack;

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);

  @override
  Future<void> skipToNext() => _controller.next();

  @override
  Future<void> skipToPrevious() => _controller.previous();

  /// FR-005, requirement 8: playback outlives the task; a paused player
  /// does not.
  @override
  Future<void> onTaskRemoved() async {
    if (!_controller.state.playing) await stop();
  }

  Future<void> dispose() {
    _release?.cancel();
    return _subscription.cancel();
  }

  void _show(PlayerState state) {
    final stopped =
        state.status == PlayerStatus.stopped ||
        state.status == PlayerStatus.idle;
    if (!stopped) {
      _release?.cancel();
      _release = null;
    } else if (playbackState.value.processingState !=
        AudioProcessingState.idle) {
      _release ??= Timer(_stopGrace, () {
        _release = null;
        _showNow(_controller.state);
      });
      return;
    }
    _showNow(state);
  }

  void _showNow(PlayerState state) {
    final track = state.currentTrack;
    if (track != _shownTrack || _durationChanged(state)) {
      _shownTrack = track;
      mediaItem.add(track == null ? null : _itemOf(track, state));
    }
    final next = _playbackOf(state);
    if (_differs(playbackState.value, next)) playbackState.add(next);
  }

  bool _durationChanged(PlayerState state) =>
      state.duration != null && mediaItem.value?.duration != state.duration;

  MediaItem _itemOf(Track track, PlayerState state) {
    final known = _describe(track);
    final path = track.relativePath;
    return MediaItem(
      id: '${track.disk.value}/$path',
      title: known?.displayTitle ?? path.substring(path.lastIndexOf('/') + 1),
      artist: known?.info.artist,
      album: known?.info.album,
      duration: state.duration ?? known?.info.duration,
    );
  }

  PlaybackState _playbackOf(PlayerState state) => PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      if (state.playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      MediaControl.skipToNext,
    ],
    androidCompactActionIndices: const [0, 1, 3],
    systemActions: const {MediaAction.seek},
    processingState: switch (state.status) {
      PlayerStatus.idle || PlayerStatus.stopped => AudioProcessingState.idle,
      PlayerStatus.loading => AudioProcessingState.loading,
      PlayerStatus.ready => AudioProcessingState.ready,
    },
    playing: state.playing,
    updatePosition: state.position,
    updateTime: _clock(),
    queueIndex: state.currentIndex,
  );

  bool _differs(PlaybackState shown, PlaybackState next) {
    if (shown.playing != next.playing ||
        shown.processingState != next.processingState ||
        shown.queueIndex != next.queueIndex) {
      return true;
    }
    final elapsed = shown.playing
        ? next.updateTime.difference(shown.updateTime)
        : Duration.zero;
    final expected = shown.updatePosition + elapsed;
    return (next.updatePosition - expected).abs() > _positionTolerance;
  }
}
