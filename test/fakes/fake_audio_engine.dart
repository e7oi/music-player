import 'dart:async';

import 'package:musicplayer/domain/playback/model/engine_issue.dart';
import 'package:musicplayer/domain/playback/model/engine_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_engine.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

/// In-memory [AudioEngine].
///
/// By default nothing happens on its own: tests drive the end of a track and
/// the issues. With [trackLength], a playing track completes by itself after
/// that time, which the contract suite needs.
class FakeAudioEngine implements AudioEngine {
  new({this.trackLength});

  /// A [FileMediaSource] with this path cannot be read.
  static const unreadablePath = 'fake://unreadable';

  final Duration? trackLength;

  /// Every source passed to [open], in order.
  final List<MediaSource> opened = [];

  /// Every call, in order: `open`, `play`, `pause`, `seek`, `stop`.
  final List<String> calls = [];

  int releasedSources = 0;

  final _state = StreamController<EngineState>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _issues = StreamController<EngineIssue>.broadcast();

  EngineState _current = EngineState.idle;
  MediaSource? _source;
  Timer? _endTimer;
  Completer<void>? _heldStop;
  bool _disposed = false;

  @override
  EngineState get state => _current;

  @override
  Stream<EngineState> get stateStream => _state.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Stream<EngineIssue> get issueStream => _issues.stream;

  MediaSource? get loadedSource => _source;

  int get stopCalls => calls.where((c) => c == 'stop').length;

  /// The next [stop] does not return until the returned completer completes.
  Completer<void> holdNextStop() => _heldStop = Completer<void>();

  /// Simulates the end of the current track.
  void completeTrack() {
    _endTimer?.cancel();
    _completed.add(null);
  }

  void emitIssue(EngineIssue issue) => _issues.add(issue);

  void emitPosition(Duration position) => _position.add(position);

  void emitDuration(Duration? duration) => _duration.add(duration);

  @override
  Future<void> open(MediaSource source) async {
    _checkNotDisposed();
    calls.add('open');
    await _unload();
    opened.add(source);
    _setState(
      EngineState(
        processing: EngineProcessing.loading,
        playing: _current.playing,
      ),
    );
    if (source is FileMediaSource && source.path == unreadablePath) {
      await _release(source);
      _setState(
        EngineState(
          processing: EngineProcessing.idle,
          playing: _current.playing,
        ),
      );
      _issues.add(
        const EngineFailure(EngineFailureKind.openFailed, 'unreadable'),
      );
      return;
    }
    _source = source;
    _setState(
      EngineState(
        processing: EngineProcessing.ready,
        playing: _current.playing,
      ),
    );
    _duration.add(trackLength);
    _position.add(Duration.zero);
    _scheduleEnd();
  }

  @override
  Future<void> play() async {
    _checkNotDisposed();
    calls.add('play');
    _setState(EngineState(processing: _current.processing, playing: true));
    _scheduleEnd();
  }

  @override
  Future<void> pause() async {
    _checkNotDisposed();
    calls.add('pause');
    _endTimer?.cancel();
    _setState(EngineState(processing: _current.processing, playing: false));
  }

  @override
  Future<void> seek(Duration position) async {
    _checkNotDisposed();
    calls.add('seek');
    _position.add(position);
  }

  @override
  Future<void> stop() async {
    _checkNotDisposed();
    calls.add('stop');
    final held = _heldStop;
    _heldStop = null;
    if (held != null) await held.future;
    await _unload();
    _setState(EngineState.idle);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await Future.wait([
      _state.close(),
      _position.close(),
      _duration.close(),
      _completed.close(),
      _issues.close(),
    ]);
  }

  Future<void> _unload() async {
    _endTimer?.cancel();
    final source = _source;
    _source = null;
    if (source != null) await _release(source);
  }

  Future<void> _release(MediaSource source) async {
    if (source is DescriptorMediaSource) await source.release();
    releasedSources++;
  }

  void _scheduleEnd() {
    final length = trackLength;
    if (length == null || !_current.playing || _source == null) return;
    _endTimer?.cancel();
    _endTimer = Timer(length, () => _completed.add(null));
  }

  void _setState(EngineState state) {
    _current = state;
    _state.add(state);
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('FakeAudioEngine disposed');
  }
}
