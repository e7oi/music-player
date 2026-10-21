import 'dart:async';

import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';

class FakeAudioInterruptions implements AudioInterruptions {
  final _events = StreamController<InterruptionEvent>.broadcast();

  /// What the next [activate] answers.
  bool grant = true;
  int activations = 0;
  int deactivations = 0;
  bool active = false;

  @override
  Future<bool> activate() async {
    activations++;
    active = grant;
    return grant;
  }

  @override
  Future<void> deactivate() async {
    deactivations++;
    active = false;
  }

  @override
  Stream<InterruptionEvent> get events => _events.stream;

  void emit(InterruptionEvent event) => _events.add(event);
}
