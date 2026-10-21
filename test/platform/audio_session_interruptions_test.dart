import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/playback/ports/audio_interruptions.dart';
import 'package:musicplayer/platform/audio_session_interruptions.dart';

void main() {
  /// @verifies BR-005
  test('classifies Android focus changes', () {
    InterruptionEvent of(AudioInterruptionType type, {required bool begin}) =>
        AudioSessionInterruptions.eventOf(AudioInterruptionEvent(begin, type));

    expect(
      of(AudioInterruptionType.pause, begin: true),
      isA<InterruptionBegan>().having(
        (e) => e.kind,
        'kind',
        InterruptionKind.transient,
      ),
    );
    expect(
      of(AudioInterruptionType.duck, begin: true),
      isA<InterruptionBegan>().having(
        (e) => e.kind,
        'kind',
        InterruptionKind.duck,
      ),
    );
    expect(
      of(AudioInterruptionType.unknown, begin: true),
      isA<InterruptionBegan>().having(
        (e) => e.kind,
        'kind',
        InterruptionKind.permanent,
      ),
    );
    expect(
      of(AudioInterruptionType.pause, begin: false),
      isA<InterruptionEnded>().having(
        (e) => e.kind,
        'kind',
        InterruptionKind.transient,
      ),
    );
  });
}
