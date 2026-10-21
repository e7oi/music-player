import 'dart:async';

import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';

/// Pauses and resumes the [PlayerController] when the system takes the audio
/// output, so that the controller itself knows nothing of the system.
///
/// Events and state changes are handled one at a time, in arrival order.
///
/// @implements BR-005
class InterruptionPolicy {
  new({
    required this._controller,
    required this._interruptions,
    this._stopGrace = const Duration(milliseconds: 500),
  });

  final PlayerController _controller;
  final AudioInterruptions _interruptions;

  /// Choosing another track goes through "stopped" for an instant: the
  /// output is given back only when the player stays stopped this long.
  final Duration _stopGrace;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Future<void> _tail = Future<void>.value();
  Timer? _release;

  bool _wasPlaying = false;
  bool _wasActive = false;
  int? _lastIndex;

  /// Set when a transient loss paused playback; cleared by any command of the
  /// user in between, so that the end of the loss resumes only what it paused.
  bool _resumeAfter = false;

  /// The system may no longer give the output to the app (refused request,
  /// transient loss) while the adapter still answers from its last request:
  /// the next request starts afresh.
  bool _mayNotHoldFocus = false;

  void start() {
    final state = _controller.state;
    _wasPlaying = state.playing;
    _wasActive = _isActive(state);
    _lastIndex = state.currentIndex;
    _subscriptions.addAll([
      _controller.states.listen((state) => _serial(() => _onState(state))),
      _interruptions.events.listen((event) => _serial(() => _onEvent(event))),
    ]);
  }

  Future<void> dispose() async {
    _release?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  static bool _isActive(PlayerState state) =>
      state.status == PlayerStatus.loading ||
      state.status == PlayerStatus.ready;

  /// An error of one action never stops the following ones.
  void _serial(Future<void> Function() action) {
    _tail = _tail.then((_) => action()).then<void>((_) {}, onError: (_) {});
  }

  Future<void> _onState(PlayerState state) async {
    final startedPlaying = state.playing && !_wasPlaying;
    final active = _isActive(state);
    final stopped = _wasActive && !active;
    if (startedPlaying || state.currentIndex != _lastIndex || stopped) {
      _resumeAfter = false;
    }
    _wasPlaying = state.playing;
    _wasActive = active;
    _lastIndex = state.currentIndex;

    if (active) _release?.cancel();
    if (stopped) {
      _release?.cancel();
      _release = Timer(_stopGrace, () => _serial(_releaseIfStopped));
    }
    if (startedPlaying) await _activate();
  }

  Future<void> _activate() async {
    bool granted;
    try {
      if (_mayNotHoldFocus) await _interruptions.deactivate();
      granted = await _interruptions.activate();
    } on Exception {
      // Unknown answer: never play over a call because a channel failed.
      granted = false;
    }
    _mayNotHoldFocus = !granted;
    if (!granted) await _controller.pause();
  }

  Future<void> _releaseIfStopped() async {
    if (_isActive(_controller.state)) return;
    _mayNotHoldFocus = false;
    await _interruptions.deactivate();
  }

  Future<void> _onEvent(InterruptionEvent event) async {
    switch (event) {
      case InterruptionBegan(kind: InterruptionKind.transient):
        _mayNotHoldFocus = true;
        if (!_controller.state.playing) return;
        _resumeAfter = true;
        await _controller.pause();
      case InterruptionBegan(kind: InterruptionKind.permanent):
      case BecameNoisy():
        _resumeAfter = false;
        if (_controller.state.playing) await _controller.pause();
      case InterruptionEnded(kind: InterruptionKind.transient):
        _mayNotHoldFocus = false;
        if (!_resumeAfter || _controller.state.playing) return;
        _resumeAfter = false;
        // The output came back with the end of the loss: no new request.
        _wasPlaying = true;
        await _controller.play();
      case InterruptionBegan(kind: InterruptionKind.duck):
      case InterruptionEnded():
        // Android lowers the volume itself while ducking (BR-005, rule 4).
        break;
    }
  }
}
