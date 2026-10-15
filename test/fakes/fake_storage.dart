import 'dart:async';

import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';
import 'package:musicplayer/domain/storage/model/volume_event.dart';
import 'package:musicplayer/domain/storage/ports/track_source_opener.dart';
import 'package:musicplayer/domain/storage/ports/volume_events.dart';

class FakeVolumeEvents implements VolumeEvents {
  new(Set<DiskId> available) : _available = {...available};

  final Set<DiskId> _available;
  final _events = StreamController<VolumeEvent>.broadcast();

  @override
  Future<Set<DiskId>> availableDisks() async => {..._available};

  @override
  Stream<VolumeEvent> get events => _events.stream;

  void emit(VolumeEvent event) => _events.add(event);
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
