import 'package:flutter/services.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';

/// Dart side of `MediaStoreChannel.kt` (ADR-005).
class MediaStoreChannel implements InternalAudioSource, AudioPermission {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'net.trtl3.tuneshell/media_store';

  /// What MediaStore stores when a tag is missing.
  static const _unknown = '<unknown>';

  final MethodChannel _channel;

  @override
  Future<List<TrackInfo>> queryAudio() async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'queryInternalAudio',
    );
    return [
      for (final row in rows ?? const <Map<Object?, Object?>>[])
        if (fromRow(row) case final TrackInfo info) info,
    ];
  }

  /// Absolute path of the internal storage root; relative paths of the
  /// tracks start there.
  Future<String> internalStorageRoot() async =>
      (await _channel.invokeMethod<String>('internalStorageRoot'))!;

  @override
  Future<AudioPermissionStatus> status() async =>
      _status(await _channel.invokeMethod<String>('audioPermissionStatus'));

  @override
  Future<AudioPermissionStatus> request() async =>
      _status(await _channel.invokeMethod<String>('requestAudioPermission'));

  @override
  Future<void> openAppSettings() =>
      _channel.invokeMethod<void>('openAppSettings');

  static AudioPermissionStatus _status(String? value) => switch (value) {
    'granted' => AudioPermissionStatus.granted,
    'permanentlyDenied' => AudioPermissionStatus.permanentlyDenied,
    'notRequested' => AudioPermissionStatus.notRequested,
    _ => AudioPermissionStatus.denied,
  };

  /// Null for a row without a path: it cannot be identified (BR-004).
  static TrackInfo? fromRow(Map<Object?, Object?> row) {
    final folder = row['relativePath'] as String?;
    final name = row['displayName'] as String?;
    if (folder == null || name == null || name.isEmpty) return null;
    final dir = folder.endsWith('/') ? folder : '$folder/';
    // MediaStore encodes the disc in the thousands: 2003 is disc 2, track 3.
    final track = (row['track'] as num?)?.toInt();
    final year = (row['year'] as num?)?.toInt();
    final durationMs = (row['durationMs'] as num?)?.toInt();
    return TrackInfo(
      relativePath: dir == '/' ? name : '$dir$name',
      size: (row['size'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        ((row['dateModified'] as num?)?.toInt() ?? 0) * 1000,
      ),
      title: _text(row['title']),
      artist: _text(row['artist']),
      album: _text(row['album']),
      albumArtist: _text(row['albumArtist']),
      trackNumber: track == null || track % 1000 == 0 ? null : track % 1000,
      discNumber: track == null || track < 1000 ? null : track ~/ 1000,
      year: year == null || year == 0 ? null : year,
      genre: _text(row['genre']),
      duration: durationMs == null || durationMs <= 0
          ? null
          : Duration(milliseconds: durationMs),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty || text == _unknown ? null : text;
  }
}
