import 'package:meta/meta.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/domain/library/ports/library_repository.dart';

/// A folder of the internal storage that holds audio.
@immutable
final class FolderSummary {
  const new({required this.path, required this.fileCount});

  /// First segment of the relative path; empty for files at the root.
  final String path;

  /// Audio files in the folder and its subfolders.
  final int fileCount;
}

/// Indexes the folders of the internal storage chosen by the user.
///
/// Folders are offered at the top level only: choosing one includes all its
/// subfolders, which keeps the list short (an album folder each would make
/// it hundreds of lines long).
///
/// @implements FR-003
class LibraryIndexer {
  new({required this._repository, required this._source});

  /// Proposed on first launch when it exists (FR-003).
  static const defaultFolder = 'Music';

  final LibraryRepository _repository;
  final InternalAudioSource _source;
  Future<void> _tail = Future<void>.value();

  static Set<String> defaultSelection(List<FolderSummary> folders) => {
    for (final folder in folders)
      if (folder.path == defaultFolder) folder.path,
  };

  /// True until the user has confirmed a folder choice once, even an empty
  /// one.
  Future<bool> needsFolderChoice() async =>
      await _repository.disk(internalDisk) == null;

  Future<List<FolderSummary>> availableFolders() async {
    final counts = <String, int>{};
    for (final file in await _source.queryAudio()) {
      final folder = _topFolder(file.relativePath);
      counts[folder] = (counts[folder] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        FolderSummary(path: entry.key, fileCount: entry.value),
    ]..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
  }

  Future<Set<String>> chosenFolders() =>
      _repository.chosenFolders(internalDisk);

  /// Stores [folders] as the choice for the internal storage, then indexes.
  Future<IndexResult> chooseFolders(Set<String> folders) => _serial(() async {
    await _repository.ensureDisk(Disk.internal);
    await _repository.setChosenFolders(internalDisk, folders);
    return await _index();
  });

  /// Reindexes the chosen folders. Does nothing before the first choice.
  Future<IndexResult> index() => _serial(_index);

  Future<IndexResult> _index() async {
    if (await _repository.disk(internalDisk) == null) {
      return const IndexResult(added: 0, updated: 0, removed: 0);
    }
    final folders = await _repository.chosenFolders(internalDisk);
    final found = [
      for (final file in await _source.queryAudio())
        if (folders.contains(_topFolder(file.relativePath))) file,
    ];
    return await _repository.applyIndex(internalDisk, found);
  }

  static String _topFolder(String relativePath) {
    final slash = relativePath.indexOf('/');
    return slash < 0 ? '' : relativePath.substring(0, slash);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
