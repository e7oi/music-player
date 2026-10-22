import 'package:tuneshell/domain/library/model/track.dart';

/// A change in the availability of a removable disk.
sealed class VolumeEvent {
  const new(this.disk);

  final DiskId disk;
}

/// The disk is mounted and readable.
final class VolumeMounted extends VolumeEvent {
  const new(super.disk);
}

/// Android announced that the disk is about to be unmounted.
///
/// Android kills the app about one second later if a descriptor is still open
/// on the volume, so this event must stop the engine first (BR-002).
final class VolumeEjecting extends VolumeEvent {
  const new(super.disk);
}

/// The disk is gone, announced or not.
final class VolumeRemoved extends VolumeEvent {
  const new(super.disk);
}
