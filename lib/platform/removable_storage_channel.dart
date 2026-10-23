import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';

/// Dart side of `RemovableStorageChannel.kt` (ADR-008).
class RemovableStorageChannel implements RemovableAudioSource {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'net.trtl3.tuneshell/removable_storage';

  final MethodChannel _channel;

  /// The identifier is kept as Android gives it, case included: the native
  /// side compares without regard to case but builds document ids from the
  /// grant's own spelling.
  static DiskId diskId(String uuid) => DiskId(uuid);

  @override
  Future<RemovableFolder?> pickFolder() async {
    try {
      final row = await _channel.invokeMapMethod<String, Object?>('pickFolder');
      return row == null ? null : _folder(row);
    } on PlatformException catch (e) {
      if (e.code == 'not_removable') throw const NotRemovableException();
      rethrow;
    }
  }

  @override
  Future<Set<RemovableFolder>> grantedFolders() async => {
    for (final row
        in await _channel.invokeListMethod<Map<Object?, Object?>>(
              'grantedFolders',
            ) ??
            const <Map<Object?, Object?>>[])
      _folder(row.cast<String, Object?>()),
  };

  @override
  Future<List<MountedVolume>> mountedVolumes() async => [
    for (final row
        in await _channel.invokeListMethod<Map<Object?, Object?>>(
              'mountedVolumes',
            ) ??
            const <Map<Object?, Object?>>[])
      MountedVolume(
        id: diskId(row['uuid']! as String),
        label: row['label']! as String,
      ),
  ];

  @override
  Future<void> releaseFolder(DiskId disk, String path) => _channel
      .invokeMethod<void>('releaseFolder', {'uuid': disk.value, 'path': path});

  @override
  Future<List<TrackInfo>> scan(DiskId disk, String folder) async {
    try {
      final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'scan',
        {'uuid': disk.value, 'path': folder},
      );
      return [
        for (final row in rows ?? const <Map<Object?, Object?>>[])
          TrackInfo(
            relativePath: row['relativePath']! as String,
            size: (row['size']! as num).toInt(),
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(
              (row['modifiedMs']! as num).toInt(),
            ),
          ),
      ];
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'access_lost' => const RemovableAccessException(),
        'cancelled' => const ScanCancelledException(),
        _ => e,
      };
    }
  }

  @override
  Future<void> cancelScan() => _channel.invokeMethod<void>('cancelScan');

  /// Opens the file and detaches its descriptor: the caller owns it and must
  /// [closeFd] it (D25, BR-006.1).
  Future<int> openFd(DiskId disk, String relativePath) async =>
      (await _channel.invokeMethod<int>('openFd', {
        'uuid': disk.value,
        'path': relativePath,
      }))!;

  Future<void> closeFd(int fd) =>
      _channel.invokeMethod<void>('closeFd', {'fd': fd});

  static RemovableFolder _folder(Map<String, Object?> row) => RemovableFolder(
    disk: diskId(row['uuid']! as String),
    diskLabel: row['label']! as String,
    path: row['path']! as String,
  );
}

/// Opens the tracks of a removable disk by a detached descriptor.
///
/// @implements BR-006: `fd://N`, never a `content://` URI; the descriptor is
/// closed by the engine once it has stopped reading (BR-002).
class RemovableTrackSourceOpener implements TrackSourceOpener {
  new(this._channel);

  final RemovableStorageChannel _channel;

  @override
  Future<MediaSource> open(Track track) async {
    try {
      final fd = await _channel.openFd(track.disk, track.relativePath);
      return DescriptorMediaSource(fd: fd, release: () => _channel.closeFd(fd));
    } on PlatformException catch (e) {
      throw TrackSourceException('${e.code}: ${e.message}');
    }
  }
}

/// Sends each track to the opener of its disk.
class RoutingTrackSourceOpener implements TrackSourceOpener {
  new({
    required this.internal,
    required this.removable,
    required this.internalDisk,
  });

  final TrackSourceOpener internal;
  final TrackSourceOpener removable;
  final DiskId internalDisk;

  @override
  Future<MediaSource> open(Track track) =>
      track.disk == internalDisk ? internal.open(track) : removable.open(track);
}

/// Availability of the removable disks, read when asked: at the start and
/// when the app comes back to the foreground (FR-006.10). The live
/// announcement of an ejection is MPL-035.
class RemovableVolumeEvents implements VolumeEvents {
  new(this._channel, this._internal);

  final RemovableStorageChannel _channel;
  final DiskId _internal;
  final _events = StreamController<VolumeEvent>.broadcast();
  Set<DiskId>? _known;

  @override
  Future<Set<DiskId>> availableDisks() async {
    final disks = await _mounted();
    _known = disks;
    return {_internal, ...disks};
  }

  @override
  Stream<VolumeEvent> get events => _events.stream;

  @override
  Future<void> refresh() async {
    final before = _known;
    final now = await _mounted();
    _known = now;
    if (before == null) return;
    for (final disk in now.difference(before)) {
      _events.add(VolumeMounted(disk));
    }
    for (final disk in before.difference(now)) {
      _events.add(VolumeRemoved(disk));
    }
  }

  Future<Set<DiskId>> _mounted() async => {
    for (final volume in await _channel.mountedVolumes()) volume.id,
  };
}
