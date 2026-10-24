import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/features/library/folder_choice_model.dart';

void main() {
  const folders = <FolderSummary>[
    FolderSummary(path: 'Music', fileCount: 1842),
    FolderSummary(path: 'Download', fileCount: 214),
    FolderSummary(path: 'Podcasts', fileCount: 96),
  ];

  /// @verifies FR-015.1
  group('the summary under the list', () {
    test('counts the checked folders and their files', () {
      final summary = FolderChoiceSummary.of(folders, const {
        'Music',
        'Podcasts',
      });

      expect((summary.folders, summary.files), (2, 1938));
    });

    test('follows the selection, with files of unknown folders ignored', () {
      final summary = FolderChoiceSummary.of(folders, const {'Music', 'Gone'});

      expect((summary.folders, summary.files), (1, 1842));
    });

    /// @verifies FR-015.4
    test('nothing checked: the choice cannot continue', () {
      final summary = FolderChoiceSummary.of(folders, const {});

      expect(summary.none, isTrue);
      expect(summary.folders, 0);
    });

    test('an empty list has nothing to choose', () {
      expect(FolderChoiceSummary.of(const [], const {}).none, isTrue);
    });
  });
}
