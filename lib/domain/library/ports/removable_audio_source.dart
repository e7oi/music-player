import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// The access to a removable disk is no longer valid: the user has to choose
/// the folder again (FR-006.11).
final class RemovableAccessException implements Exception {
  const new();

  @override
  String toString() => 'RemovableAccessException';
}

/// A scan was stopped by [RemovableAudioSource.cancelScan] (BR-006.5).
final class ScanCancelledException implements Exception {
  const new();

  @override
  String toString() => 'ScanCancelledException';
}

/// The user picked a folder of the phone's own storage, which MediaStore
/// already indexes (FR-006.1).
final class NotRemovableException implements Exception {
  const new();

  @override
  String toString() => 'NotRemovableException';
}

/// Removable disks reached through the Android folder picker (D25, ADR-008).
abstract interface class RemovableAudioSource {
  /// Opens the picker. Null when the user cancels. Throws
  /// [NotRemovableException] for a folder of the internal storage.
  Future<RemovableFolder?> pickFolder();

  /// Folders whose access Android still grants to the app.
  Future<Set<RemovableFolder>> grantedFolders();

  /// Removable volumes mounted right now.
  Future<List<MountedVolume>> mountedVolumes();

  /// Gives up the access to [path] (FR-006.2).
  Future<void> releaseFolder(DiskId disk, String path);

  /// Audio files of [folder] and its subfolders, without tags (FR-006.5).
  ///
  /// Throws [RemovableAccessException] when the access is gone,
  /// [ScanCancelledException] after [cancelScan], and any other exception
  /// when the scan could not finish: a partial list is never returned
  /// (FR-006.9).
  Future<List<TrackInfo>> scan(DiskId disk, String folder);

  /// Stops the scan in progress.
  Future<void> cancelScan();
}
