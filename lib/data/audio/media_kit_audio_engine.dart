import 'dart:async';
import 'dart:developer' as developer;

import 'package:media_kit/media_kit.dart';
import 'package:musicplayer/domain/playback/model/engine_issue.dart';
import 'package:musicplayer/domain/playback/model/engine_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_engine.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

/// [AudioEngine] over `media_kit` (libmpv).
///
/// `media_kit` does not expose mpv's `end-file` event, so this adapter reads
/// the end of a file from the `idle-active` property: with `keep-open=yes`
/// (set by `media_kit`) mpv stays on a file that played to its end and only
/// goes idle when the file is unloaded or could not be played. Going idle
/// while a file is loaded and no stop was requested is the `end-file` with an
/// error reason, always a failure. Error logs that announce an unreadable
/// file are failures too, because mpv may go idle too fast for the property
/// change to be seen; every other log message of level `warn` or `error` is
/// an unclassified warning until MPL-010 classifies recorded real messages.
///
/// @decision D2
class MediaKitAudioEngine implements AudioEngine {
  new()
    : _player = Player(
        configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
      ) {
    _ready = _initialize();
  }

  /// Must run once before the first engine is created.
  static void ensureInitialized() => MediaKit.ensureInitialized();

  /// How long [stop] waits for mpv to report that it is idle. Beyond it the
  /// descriptor is released anyway and the delay is logged: waiting forever
  /// would block every later command.
  static const idleTimeout = Duration(seconds: 5);

  final Player _player;
  late final Future<void> _ready;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  final _state = StreamController<EngineState>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _issues = StreamController<EngineIssue>.broadcast();

  EngineState _current = EngineState.idle;
  bool _playing = false;

  /// The source mpv reads, or read last; released by [stop] and [open].
  MediaSource? _source;
  bool _opening = false;
  bool _loaded = false;
  bool _stopping = false;
  bool _completedReported = false;
  bool _failureReported = false;
  String _lastError = '';

  bool _idle = true;
  Completer<void>? _idleWaiter;

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

  Future<void> _initialize() async {
    final platform = _player.platform;
    if (platform is NativePlayer) {
      // Local files only: no network access from mpv (D15).
      await platform.setProperty('ytdl', 'no');
      await platform.observeProperty('idle-active', _onIdleActive);
    }
    final stream = _player.stream;
    _subscriptions.addAll([
      stream.completed.listen(_onCompleted),
      stream.position.listen(_position.add),
      stream.duration.listen(
        (d) => _duration.add(d > Duration.zero ? d : null),
      ),
      stream.log.listen(_onLog),
    ]);
  }

  @override
  Future<void> open(MediaSource source) async {
    await _ready;
    await _unload();
    _source = source;
    _completedReported = false;
    _failureReported = false;
    _lastError = '';
    _opening = true;
    _emit(EngineProcessing.loading);
    _duration.add(null);
    try {
      await _player.open(Media(_uriOf(source)), play: false);
    } finally {
      _opening = false;
    }
    if (_failureReported) return;
    _loaded = true;
    _emit(EngineProcessing.ready);
  }

  @override
  Future<void> play() async {
    await _ready;
    _playing = true;
    _emit(_current.processing);
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _ready;
    _playing = false;
    _emit(_current.processing);
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _ready;
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _ready;
    _playing = false;
    await _unload();
    _emit(EngineProcessing.idle);
  }

  @override
  Future<void> dispose() async {
    await stop();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await Future.wait([
      _state.close(),
      _position.close(),
      _duration.close(),
      _completed.close(),
      _issues.close(),
    ]);
  }

  /// Stops mpv, waits until it no longer reads the file, then releases the
  /// source. Never releases a descriptor mpv may still read (BR-002).
  Future<void> _unload() async {
    final source = _source;
    if (source == null && _idle) return;
    _stopping = true;
    try {
      await _player.stop();
      await _waitForIdle();
    } finally {
      _source = null;
      _loaded = false;
      _stopping = false;
    }
    if (source is DescriptorMediaSource) await source.release();
  }

  Future<void> _waitForIdle() async {
    if (_idle) return;
    final waiter = _idleWaiter ??= Completer<void>();
    try {
      await waiter.future.timeout(idleTimeout);
    } on TimeoutException {
      _log('mpv not idle ${idleTimeout.inSeconds} s after stop');
    }
  }

  Future<void> _onIdleActive(String value) async {
    _idle = value == 'yes';
    if (!_idle) return;
    _idleWaiter?.complete();
    _idleWaiter = null;
    if (_loaded && !_opening && !_stopping) {
      _loaded = false;
      _reportFailure(EngineFailureKind.playbackFailed, _lastError);
    }
  }

  void _onCompleted(bool completed) {
    if (!completed || !_loaded || _completedReported) return;
    _completedReported = true;
    _completed.add(null);
  }

  void _onLog(PlayerLog log) {
    final text = log.text.trim();
    _log('${log.level} ${log.prefix}: $text');
    if (log.level != 'error' && log.level != 'fatal' && log.level != 'warn') {
      return;
    }
    if (log.level != 'warn') _lastError = text;
    final reading = _source != null && !_stopping;
    if (reading && log.level != 'warn' && _announcesUnreadableFile(log)) {
      _reportFailure(EngineFailureKind.openFailed, text);
      return;
    }
    _issues.add(EngineWarning(EngineWarningKind.unclassified, text));
  }

  /// mpv messages that end the file before playback starts, for example
  /// "Cannot open file" (`file`) or "Failed to recognize file format."
  /// (`cplayer`).
  static bool _announcesUnreadableFile(PlayerLog log) =>
      log.prefix == 'file' ||
      log.prefix == 'stream' ||
      (log.prefix == 'cplayer' && log.text.startsWith('Failed to'));

  void _reportFailure(EngineFailureKind kind, String message) {
    if (_failureReported) return;
    _failureReported = true;
    _loaded = false;
    _emit(EngineProcessing.idle);
    _issues.add(EngineFailure(kind, message));
  }

  void _emit(EngineProcessing processing) {
    _current = EngineState(processing: processing, playing: _playing);
    if (!_state.isClosed) _state.add(_current);
  }

  static String _uriOf(MediaSource source) => switch (source) {
    FileMediaSource(:final path) => path,
    DescriptorMediaSource(:final fd) => 'fd://$fd',
  };

  /// Local log only (logcat): messages may contain file names, which never
  /// leave the device (D27).
  static void _log(String message) => developer.log(message, name: 'media_kit');
}
