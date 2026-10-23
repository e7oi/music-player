import 'dart:async';

import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';

class FakeVolumeEvents implements VolumeEvents {
  new(Set<DiskId> available) : _available = {...available};

  Set<DiskId> _available;

  /// Replaces the disks readable right now.
  // ignore: avoid_setters_without_getters
  set available(Set<DiskId> value) => _available = {...value};
  final _events = StreamController<VolumeEvent>.broadcast();

  @override
  Future<Set<DiskId>> availableDisks() async => {..._available};

  @override
  Stream<VolumeEvent> get events => _events.stream;

  void emit(VolumeEvent event) => _events.add(event);

  int refreshes = 0;

  @override
  Future<void> refresh() async => refreshes++;
}

/// Opens every track as a file named after its disk and path, except the
/// tracks listed in [failing].
class FakeTrackSourceOpener implements TrackSourceOpener {
  final Set<Track> failing = {};
  final List<Track> opened = [];

  @override
  Future<MediaSource> open(Track track) async {
    opened.add(track);
    if (failing.contains(track)) {
      throw const TrackSourceException('cannot open');
    }
    return FileMediaSource('${track.disk.value}/${track.relativePath}');
  }
}
