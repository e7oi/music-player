import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/throttle.dart';
import 'package:tuneshell/domain/library/services/tag_indexer.dart';

final tagIndexerProvider = Provider<TagIndexer>(
  (ref) => TagIndexer(
    repository: ref.watch(libraryRepositoryProvider),
    reader: ref.watch(tagReaderProvider),
    volumes: ref.watch(volumeEventsProvider),
  ),
);

final tagProgressProvider = StreamProvider<TagProgress>((ref) async* {
  final indexer = ref.watch(tagIndexerProvider);
  yield indexer.progress;
  // FR-010.3: the banner is updated at most four times a second; the end
  // of the reading always passes.
  yield* throttle(
    indexer.progressStream,
    const Duration(milliseconds: 250),
    always: (progress) => !progress.running,
  );
});

/// Folder of the stored artwork images (FR-007.6).
final artworkDirectoryProvider = FutureProvider<String>(
  (ref) => ref.watch(fileTagsProvider).artworkDirectory(),
);

/// The image of an artwork identifier, null until the folder is known.
final Provider<ImageProvider?> Function(String) artworkImageProvider =
    Provider.family<ImageProvider?, String>((ref, artwork) {
      final directory = ref.watch(artworkDirectoryProvider).value;
      return directory == null
          ? null
          : FileImage(File('$directory/$artwork.jpg'));
    });
