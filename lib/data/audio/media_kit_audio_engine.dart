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
/// again after a file started loading, with no stop requested, is the
/// `end-file` with an error reason, always a failure. Until the duration of
/// the file is known, error logs that announce an unreadable file are
/// failures too, because mpv may go busy and idle again too fast for the
/// property change to be seen; every other log message of level `warn` or
/// `error` is an unclassified warning until MPL-010 classifies recorded real
/// messages.
///
/// `idle-active` turns true as soon as a stop is requested, before mpv closes
/// the file (`stop_play == PT_STOP` in mpv's `command.c`), so [stop] waits
/// for the `path` property instead: mpv clears it only after the demuxer,
/// and the stream it reads, are closed (`play_current_file` in
/// `loadfile.c`).
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

  /// How long [stop] waits for mpv to close the file. Beyond it [stop]
  /// returns so that later commands are not blocked, but a descriptor is only
  /// released once mpv has closed the file (BR-002).
  static const unloadTimeout = Duration(seconds: 5);

  static const _unloadPollInterval = Duration(milliseconds: 10);

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

  /// mpv reported busy since the current file started loading.
  bool _sawBusy = false;

  /// The duration of the current file is known: mpv has opened it.
  bool _started = false;

  /// Descriptors of sources mpv had not closed when [stop] returned; released
  /// after the next confirmed unload, or on [dispose].
  final List<DescriptorMediaSource> _pendingRelease = [];

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
      stream.duration.listen((d) {
        final known = d > Duration.zero;
        if (known && _source != null) _started = true;
        _duration.add(known ? d : null);
      }),
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
    _sawBusy = false;
    _started = false;
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
    // mpv is gone: nothing reads these descriptors any more.
    await _releasePending();
    await Future.wait([
      _state.close(),
      _position.close(),
      _duration.close(),
      _completed.close(),
      _issues.close(),
    ]);
  }

  /// Stops mpv, waits until it no longer reads the file, then releases the
  /// source.
  ///
  /// @implements BR-002: a descriptor is never released while mpv may still
  /// read it; if mpv has not closed the file in time, the release waits.
  Future<void> _unload() async {
    final source = _source;
    if (source == null && !_loaded) return;
    _stopping = true;
    var unloaded = false;
    try {
      await _player.stop();
      unloaded = await _waitUntilUnloaded();
    } finally {
      _source = null;
      _loaded = false;
      _stopping = false;
    }
    // A file closed now means every earlier one is closed too.
    if (unloaded) await _releasePending();
    if (source is! DescriptorMediaSource) return;
    if (unloaded) {
      await source.release();
    } else {
      _log('mpv still has a file open ${unloadTimeout.inSeconds} s after stop');
      _pendingRelease.add(source);
    }
  }

  Future<bool> _waitUntilUnloaded() async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return true;
    final deadline = DateTime.now().add(unloadTimeout);
    while (await platform.getProperty('path') != '') {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(_unloadPollInterval);
    }
    return true;
  }

  Future<void> _onIdleActive(String value) async {
    if (value != 'yes') {
      _sawBusy = true;
      return;
    }
    final current = _opening || _loaded;
    if (_sawBusy && current && !_stopping) {
      _reportFailure(
        _loaded
            ? EngineFailureKind.playbackFailed
            : EngineFailureKind.openFailed,
        _lastError,
      );
    }
    _sawBusy = false;
  }

  Future<void> _releasePending() async {
    final pending = [..._pendingRelease];
    _pendingRelease.clear();
    for (final source in pending) {
      await source.release();
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
    final loading = _source != null && !_started && !_stopping;
    if (loading && log.level != 'warn' && _announcesUnreadableFile(log)) {
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
