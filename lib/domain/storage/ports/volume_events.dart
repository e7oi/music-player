import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/storage/model/volume_event.dart';

/// Availability of the disks, as reported by the platform.
///
/// Implemented in `platform/` over an EventChannel and a native
/// `StorageVolumeCallback` (MPL-035); the controller never imports a channel.
abstract interface class VolumeEvents {
  /// Disks readable right now, the internal storage included.
  Future<Set<DiskId>> availableDisks();

  /// Changes after [availableDisks] was read. Broadcast.
  Stream<VolumeEvent> get events;
}
