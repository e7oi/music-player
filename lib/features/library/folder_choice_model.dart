import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';

/// What the bar under the list of folders says (FR-015.1, FR-015.4).
@immutable
final class FolderChoiceSummary {
  const new _computed({required this.folders, required this.files});

  /// Summary of the folders of [all] whose path is in [selected].
  factory of(List<FolderSummary> all, Set<String> selected) {
    var folders = 0;
    var files = 0;
    for (final folder in all) {
      if (selected.contains(folder.path)) {
        folders++;
        files += folder.fileCount;
      }
    }
    return FolderChoiceSummary._computed(folders: folders, files: files);
  }

  /// Checked folders and the audio files in them.
  final int folders;
  final int files;

  /// Nothing is checked: the first choice cannot continue.
  bool get none => folders == 0;
}
