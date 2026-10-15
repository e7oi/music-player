import 'package:meta/meta.dart';

enum EngineProcessing {
  /// Nothing loaded.
  idle,

  /// `open` in progress. Not guaranteed to be observed.
  loading,

  /// A track is loaded, paused or playing.
  ready,
}

@immutable
final class EngineState {
  const new({required this.processing, required this.playing});

  static const idle = EngineState(
    processing: EngineProcessing.idle,
    playing: false,
  );

  final EngineProcessing processing;

  /// The intent to play, not the engine's momentary state: it stays true
  /// across the end of a track and the loading of the next one.
  final bool playing;

  @override
  bool operator ==(Object other) =>
      other is EngineState &&
      other.processing == processing &&
      other.playing == playing;

  @override
  int get hashCode => Object.hash(processing, playing);

  @override
  String toString() => 'EngineState(${processing.name}, playing: $playing)';
}
