import 'dart:async';

import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';

/// Pauses and resumes the [PlayerController] when the system takes the audio
/// output, so that the controller itself knows nothing of the system.
///
/// @implements BR-005
class InterruptionPolicy {
  new({required this._controller, required this._interruptions});

  final PlayerController _controller;
  final AudioInterruptions _interruptions;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _wasPlaying = false;
  bool _wasActive = false;
  int? _lastIndex;

  /// Set when a transient loss paused playback; cleared by any command of the
  /// user in between, so that the end of the loss resumes only what it paused.
  bool _resumeAfter = false;

  void start() {
    final state = _controller.state;
    _wasPlaying = state.playing;
    _wasActive = _isActive(state);
    _lastIndex = state.currentIndex;
    _subscriptions.addAll([
      _controller.states.listen(_onState),
      _interruptions.events.listen((event) => unawaited(_onEvent(event))),
    ]);
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  static bool _isActive(PlayerState state) =>
      state.status == PlayerStatus.loading ||
      state.status == PlayerStatus.ready;

  void _onState(PlayerState state) {
    final startedPlaying = state.playing && !_wasPlaying;
    final active = _isActive(state);
    final stopped = _wasActive && !active;
    if (startedPlaying || state.currentIndex != _lastIndex || stopped) {
      _resumeAfter = false;
    }
    _wasPlaying = state.playing;
    _wasActive = active;
    _lastIndex = state.currentIndex;

    if (startedPlaying) unawaited(_activate());
    if (stopped) unawaited(_interruptions.deactivate());
  }

  Future<void> _activate() async {
    if (!await _interruptions.activate()) await _controller.pause();
  }

  Future<void> _onEvent(InterruptionEvent event) async {
    switch (event) {
      case InterruptionBegan(kind: InterruptionKind.transient):
        if (!_controller.state.playing) return;
        await _controller.pause();
        _resumeAfter = true;
      case InterruptionBegan(kind: InterruptionKind.permanent):
      case BecameNoisy():
        _resumeAfter = false;
        if (_controller.state.playing) await _controller.pause();
      case InterruptionEnded(kind: InterruptionKind.transient):
        if (!_resumeAfter) return;
        _resumeAfter = false;
        await _controller.play();
      case InterruptionBegan(kind: InterruptionKind.duck):
      case InterruptionEnded():
        // Android lowers the volume itself while ducking (BR-005, rule 4).
        break;
    }
  }
}
