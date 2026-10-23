import 'dart:io';

import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';

/// Opens the tracks of the internal storage by file path (D25, ADR-005).
class InternalTrackSourceOpener implements TrackSourceOpener {
  new(this._root);

  /// Resolves the internal storage root once, on first use.
  final Future<String> Function() _root;
  Future<String>? _rootPath;

  @override
  Future<MediaSource> open(Track track) async {
    if (track.disk != internalDisk) {
      throw TrackSourceException(
        'not on the internal storage: ${track.disk.value}',
      );
    }
    final root = await (_rootPath ??= _root());
    final path = '$root/${track.relativePath}';
    if (!File(path).existsSync()) {
      throw const TrackSourceException('file not found');
    }
    return FileMediaSource(path);
  }
}

/// Only the internal storage, always present. MPL-035 adds removable disks.
class InternalVolumeEvents implements VolumeEvents {
  @override
  Future<Set<DiskId>> availableDisks() async => {internalDisk};

  @override
  Stream<VolumeEvent> get events => const Stream.empty();

  @override
  Future<void> refresh() async {}
}
