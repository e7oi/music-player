import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';

/// Availability of the disks, as reported by the platform.
///
/// Implemented in `platform/` over an EventChannel and a native
/// `StorageVolumeCallback` (MPL-035); the controller never imports a channel.
abstract interface class VolumeEvents {
  /// Disks readable right now, the internal storage included.
  Future<Set<DiskId>> availableDisks();

  /// Changes after [availableDisks] was read. Broadcast.
  Stream<VolumeEvent> get events;

  /// Reads the availability again and announces what changed on [events].
  /// Called when the app comes back to the foreground (FR-006.10).
  Future<void> refresh();
}
