import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';

enum RemovableStatus {
  available,

  /// Not mounted: its tracks stay, greyed (BR-004, rule 5).
  absent,

  /// Mounted, but Android no longer grants the access (FR-006.11).
  accessLost,
}

@immutable
final class RemovableDisk {
  const new({required this.disk, required this.folders, required this.status});

  final Disk disk;
  final Set<String> folders;
  final RemovableStatus status;
}

enum AddFolderResult { added, cancelled, noAudio }

/// Adds, scans and removes the folders of removable disks.
///
/// @implements FR-006
/// @implements UC-003
class RemovableIndexer {
  new({required this._repository, required this._source});

  final LibraryRepository _repository;
  final RemovableAudioSource _source;
  Future<void> _tail = Future<void>.value();

  /// Every removable disk of the library with its state.
  Future<List<RemovableDisk>> disks() async {
    final mounted = {for (final v in await _source.mountedVolumes()) v.id};
    final granted = await _source.grantedFolders();
    return [
      for (final disk in await _repository.disks())
        if (disk.kind == DiskKind.removable)
          await _view(disk, mounted, granted),
    ];
  }

  /// Opens the picker, then registers and scans the folder. A folder without
  /// any audio file registers nothing (UC-003, 2b).
  Future<AddFolderResult> addFolder() => _serial(() async {
    final picked = await _source.pickFolder();
    if (picked == null) return AddFolderResult.cancelled;
    final scanned = await _source.scan(picked.disk, picked.path);
    if (scanned.isEmpty) {
      // Choosing an already used folder again (to renew it) keeps its access.
      final chosen = await _repository.chosenFolders(picked.disk);
      if (!chosen.contains(picked.path)) {
        await _release(picked.disk, picked.path);
      }
      return AddFolderResult.noAudio;
    }
    final disk = Disk(
      id: picked.disk,
      label: picked.diskLabel,
      kind: DiskKind.removable,
    );
    final folders = {...await _repository.chosenFolders(picked.disk)}
      ..add(picked.path);
    await _repository.setChosenFolders(disk, folders);
    await _apply(picked.disk, folders, first: {picked.path: scanned});
    return AddFolderResult.added;
  });

  /// Scans every available disk again (FR-006.8). A disk that fails does not
  /// stop the others; the first error is thrown at the end.
  Future<void> refreshAll() => _serial(() async {
    Exception? failure;
    for (final view in await disks()) {
      if (view.status != RemovableStatus.available) continue;
      try {
        await _apply(view.disk.id, view.folders);
      } on ScanCancelledException {
        // A stop ends the whole refresh, not just one folder (BR-006.5).
        rethrow;
      } on Exception catch (e) {
        failure ??= e;
      }
    }
    if (failure case final Exception error) throw error;
  });

  /// Stops the scan in progress; its tracks stay as they were (BR-006.6).
  Future<void> cancel() => _source.cancelScan();

  /// Unchecks [folder]: its tracks leave the library and the access is given
  /// up (FR-006.2).
  Future<void> removeFolder(DiskId disk, String folder) => _serial(() async {
    final folders = {...await _repository.chosenFolders(disk)}..remove(folder);
    final stored = await _repository.disk(disk);
    if (stored == null) return;
    // The tracks go first: a failed scan changes nothing, the folder stays
    // chosen and its access kept (FR-006.2).
    if (folders.isEmpty) {
      await _repository.applyScan(disk, const []);
    } else {
      await _apply(disk, folders);
    }
    await _repository.setChosenFolders(stored, folders);
    await _release(disk, folder);
  });

  Future<RemovableDisk> _view(
    Disk disk,
    Set<DiskId> mounted,
    Set<RemovableFolder> granted,
  ) async {
    final folders = await _repository.chosenFolders(disk.id);
    final RemovableStatus status;
    if (!mounted.contains(disk.id)) {
      status = RemovableStatus.absent;
    } else if (folders.every((f) => _covered(disk.id, f, granted))) {
      status = RemovableStatus.available;
    } else {
      status = RemovableStatus.accessLost;
    }
    return RemovableDisk(disk: disk, folders: folders, status: status);
  }

  /// A granted folder gives access to its subfolders.
  static bool _covered(
    DiskId disk,
    String folder,
    Set<RemovableFolder> granted,
  ) => granted.any(
    (g) =>
        g.disk == disk &&
        (g.path.isEmpty || folder == g.path || folder.startsWith('${g.path}/')),
  );

  /// Scans [folders] (reusing [first], already scanned), then applies the
  /// result.
  ///
  /// @implements FR-006.9: an empty result for a disk that has tracks is an
  /// error, never a deletion.
  Future<void> _apply(
    DiskId disk,
    Set<String> folders, {
    Map<String, List<TrackInfo>> first = const {},
  }) async {
    final found = <String, TrackInfo>{};
    for (final folder in folders) {
      final files = first[folder] ?? await _source.scan(disk, folder);
      for (final file in files) {
        found[file.relativePath] = file;
      }
    }
    if (found.isEmpty && await _repository.trackCount(disk) > 0) {
      throw const EmptySourceException();
    }
    await _repository.applyScan(disk, found.values.toList());
  }

  Future<void> _release(DiskId disk, String folder) async {
    try {
      await _source.releaseFolder(disk, folder);
    } on Exception {
      // The access stays granted; nothing else depends on it.
    }
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
