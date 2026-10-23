import 'package:flutter/services.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/ports/tag_reader.dart';

/// Dart side of `FileTagsChannel.kt` (ADR-009).
class FileTagsChannel implements TagReader {
  new(this._internal, [MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'net.trtl3.tuneshell/tags';

  final MethodChannel _channel;

  /// Disk of the internal storage: read by path, not through a grant.
  final DiskId _internal;

  @override
  Future<FileTags?> read(Track track) async {
    try {
      final row = await _channel.invokeMapMethod<String, Object?>('readTags', {
        'uuid': track.disk == _internal ? null : track.disk.value,
        'path': track.relativePath,
      });
      return row == null ? null : fromRow(row);
    } on PlatformException catch (e) {
      if (e.code == 'access_lost') throw const RemovableAccessException();
      rethrow;
    }
  }

  @override
  Future<void> retainArtwork(Set<String> keep) =>
      _channel.invokeMethod<void>('pruneArtwork', {'keep': keep.toList()});

  /// Folder of the stored artwork images, named `<identifier>.jpg`.
  Future<String> artworkDirectory() async =>
      (await _channel.invokeMethod<String>('artworkDirectory'))!;

  static FileTags fromRow(Map<String, Object?> row) {
    final durationMs = (row['durationMs'] as num?)?.toInt();
    return FileTags(
      title: row['title'] as String?,
      artist: row['artist'] as String?,
      album: row['album'] as String?,
      albumArtist: row['albumArtist'] as String?,
      trackNumber: (row['track'] as num?)?.toInt(),
      discNumber: (row['disc'] as num?)?.toInt(),
      year: (row['year'] as num?)?.toInt(),
      genre: row['genre'] as String?,
      duration: durationMs == null || durationMs <= 0
          ? null
          : Duration(milliseconds: durationMs),
      artwork: row['artwork'] as String?,
    );
  }
}
