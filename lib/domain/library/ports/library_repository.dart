import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// Counts of one [LibraryRepository.applyIndex].
final class IndexResult {
  const new({
    required this.added,
    required this.updated,
    required this.removed,
  });

  final int added;
  final int updated;
  final int removed;

  @override
  String toString() => 'IndexResult(+$added ~$updated -$removed)';
}

/// A track whose file was not read yet (FR-007.3).
@immutable
final class PendingTrack {
  const new({required this.id, required this.track});

  final int id;
  final Track track;
}

/// What reading one file gave, to store (FR-007).
@immutable
final class TagUpdate {
  /// [writeTags] is false for the internal storage, whose tags stay those of
  /// MediaStore (FR-007.2): only the artwork is stored.
  const new read(this.trackId, FileTags this.tags, {required this.writeTags});

  const new failed(this.trackId) : tags = null, writeTags = false;

  final int trackId;

  /// Null when the file could not be read.
  final FileTags? tags;
  final bool writeTags;
}

/// The stored library (ADR-004).
abstract interface class LibraryRepository {
  /// Every registered disk.
  Future<List<Disk>> disks();

  /// The registered disks, emitted again whenever one changes (FR-012).
  Stream<List<Disk>> watchDisks();

  /// Null when the disk was never registered.
  Future<Disk?> disk(DiskId id);

  /// Registers [disk] if needed; keeps the stored one otherwise. A new
  /// removable disk gets the first free mark index (FR-012.2).
  Future<void> ensureDisk(Disk disk);

  /// Folders of [disk] chosen by the user, relative to the disk (FR-003).
  Future<Set<String>> chosenFolders(DiskId disk);

  /// Registers [disk] if needed and stores [folders] in one transaction, so
  /// that a first choice is never half saved.
  Future<void> setChosenFolders(Disk disk, Set<String> folders);

  /// Every track, sorted by display title. Emits on every change.
  Stream<List<LibraryTrack>> watchTracks();

  /// Makes the tracks of [disk] match [found], in one transaction: a track
  /// whose path is still there keeps its id (BR-004), its information is
  /// updated if it changed; paths not in [found] are removed.
  Future<IndexResult> applyIndex(DiskId disk, List<TrackInfo> found);

  /// Like [applyIndex] for a disk scanned without tags (FR-006.8): a file
  /// whose size and date are unchanged keeps its tags and artwork; a changed
  /// one keeps its old information until it is read again.
  Future<IndexResult> applyScan(DiskId disk, List<TrackInfo> found);

  /// Tracks of [disks] still to read, at most [limit].
  Future<List<PendingTrack>> pendingTracks(Set<DiskId> disks, int limit);

  Future<int> countPending(Set<DiskId> disks);

  /// Puts the tracks of [disks] whose reading failed back to pending, so the
  /// next pass tries them again (FR-007.3).
  Future<void> resetFailedTags(Set<DiskId> disks);

  /// Number of tracks stored for [disk].
  Future<int> trackCount(DiskId disk);

  /// Stores [updates] in one transaction.
  Future<void> applyFileTags(List<TagUpdate> updates);

  /// Artwork identifiers still used by a track.
  Future<Set<String>> artworkInUse();
}
