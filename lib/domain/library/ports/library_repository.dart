import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/model/track.dart';

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

/// The stored library (ADR-004).
abstract interface class LibraryRepository {
  /// Null when the disk was never registered.
  Future<Disk?> disk(DiskId id);

  /// Registers [disk] if needed; keeps the stored one otherwise.
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
}
