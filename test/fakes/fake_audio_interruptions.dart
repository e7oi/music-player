import 'dart:async';

import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';

/// Answers like audio_session 0.2.4: once a request was made, even a refused
/// one, later requests answer true without asking the system again, until
/// the output is given back or permanently lost.
class FakeAudioInterruptions implements AudioInterruptions {
  final _events = StreamController<InterruptionEvent>.broadcast();

  /// What the system answers to the next real request.
  bool grant = true;

  /// The next request throws, as a failing platform channel would.
  bool failNext = false;

  /// Requests that reached the system.
  int requests = 0;
  int deactivations = 0;
  bool _requested = false;

  @override
  Future<bool> activate() async {
    if (failNext) {
      failNext = false;
      throw Exception('channel failure');
    }
    if (_requested) return true;
    _requested = true;
    requests++;
    return grant;
  }

  @override
  Future<void> deactivate() async {
    deactivations++;
    _requested = false;
  }

  @override
  Stream<InterruptionEvent> get events => _events.stream;

  void emit(InterruptionEvent event) {
    if (event case InterruptionBegan(kind: InterruptionKind.permanent)) {
      _requested = false;
    }
    _events.add(event);
  }
}
