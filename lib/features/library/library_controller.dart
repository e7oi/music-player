import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/features/library/removable_controller.dart';

sealed class LibraryViewState {
  const new();
}

final class LibraryStarting extends LibraryViewState {
  const new();
}

/// FR-004: access to the audio files is missing.
final class LibraryPermissionNeeded extends LibraryViewState {
  const new({required this.permanent});

  /// Android no longer shows its dialog: only the app settings help.
  final bool permanent;
}

/// The folders of the phone could not be read; [LibraryController.start]
/// retries.
final class LibraryLoadFailed extends LibraryViewState {
  const new({this.whileChoosingFolders = false});

  /// Retry reopens the folder choice rather than restarting.
  final bool whileChoosingFolders;
}

/// FR-003: the user picks the folders to index.
@immutable
final class LibraryFolderChoice extends LibraryViewState {
  const new({required this.folders, required this.selected});

  final List<FolderSummary> folders;
  final Set<String> selected;
}

final class LibraryReady extends LibraryViewState {
  const new({
    required this.hasFolders,
    this.indexing = false,
    this.indexFailed = false,
  });

  final bool hasFolders;
  final bool indexing;

  /// The last index failed; the stored library is still shown.
  final bool indexFailed;
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryViewState>(
      LibraryController.new,
    );

/// Permission, folder choice and indexing of the internal storage; each
/// index is followed by the removable disks and the tags.
///
/// @implements UC-001
/// @implements FR-003
/// @implements FR-004
class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryStarting();

  LibraryIndexer get _indexer => ref.read(libraryIndexerProvider);

  /// The permission dialog pauses and resumes the app: [onResumed] and
  /// [requestPermission] may both continue at once. They share this run.
  Future<void>? _continuing;

  AudioPermission get _permission => ref.read(audioPermissionProvider);

  /// The first launch asks for access once (FR-004.1), then offers the
  /// folders; later launches show the library and reindex (FR-003).
  Future<void> start() async {
    var status = await _permission.status();
    if (status == AudioPermissionStatus.notRequested) {
      status = await _permission.request();
    }
    await _continueWith(status);
  }

  /// FR-004.3 and .4. Android also reports "permanently denied" after a
  /// dismissed dialog that it would still show, so the dialog is tried
  /// first; the settings open only if it did not grant access.
  Future<void> requestPermission() async {
    try {
      final before = await _permission.status();
      final after = await _permission.request();
      if (before == AudioPermissionStatus.permanentlyDenied &&
          after != AudioPermissionStatus.granted) {
        await _permission.openAppSettings();
      }
      await _continueWith(after);
    } on Exception {
      // A request is already running: its own result will update the state.
    }
  }

  /// FR-004.5: access may have changed in the settings while away.
  Future<void> onResumed() async {
    unawaited(ref.read(removableControllerProvider.notifier).onResumed());
    final status = await _permission.status();
    final waiting = state is LibraryPermissionNeeded;
    if (status == AudioPermissionStatus.granted) {
      if (waiting) await _continueWith(status);
      return;
    }
    state = LibraryPermissionNeeded(
      permanent: status == AudioPermissionStatus.permanentlyDenied,
    );
  }

  Future<void> confirmFolders(Set<String> folders) => _runIndex(
    () => _indexer.chooseFolders(folders),
    hasFolders: folders.isNotEmpty,
  );

  /// Ignored while indexing: the end of the index would replace the choice
  /// being edited.
  Future<void> openFolderChoice() async {
    final current = state;
    if (current is LibraryReady && current.indexing) return;
    try {
      state = LibraryFolderChoice(
        folders: await _indexer.availableFolders(),
        selected: await _indexer.chosenFolders(),
      );
    } on Exception {
      state = const LibraryLoadFailed(whileChoosingFolders: true);
    }
  }

  Future<void> retry() async {
    final current = state;
    if (current is LibraryLoadFailed && current.whileChoosingFolders) {
      await openFolderChoice();
    } else {
      await start();
    }
  }

  Future<void> refresh() async {
    final folders = await _indexer.chosenFolders();
    await _runIndex(_indexer.index, hasFolders: folders.isNotEmpty);
  }

  Future<void> _continueWith(AudioPermissionStatus status) {
    final running = _continuing;
    if (running != null) return running;
    final run = _continueOnce(status);
    _continuing = run;
    return run.whenComplete(() => _continuing = null);
  }

  Future<void> _continueOnce(AudioPermissionStatus status) async {
    if (status != AudioPermissionStatus.granted) {
      state = LibraryPermissionNeeded(
        permanent: status == AudioPermissionStatus.permanentlyDenied,
      );
      return;
    }
    if (await _indexer.needsFolderChoice()) {
      try {
        final folders = await _indexer.availableFolders();
        state = LibraryFolderChoice(
          folders: folders,
          selected: LibraryIndexer.defaultSelection(folders),
        );
      } on Exception {
        state = const LibraryLoadFailed();
      }
      return;
    }
    await refresh();
  }

  Future<void> _runIndex(
    Future<Object?> Function() index, {
    required bool hasFolders,
  }) async {
    state = LibraryReady(hasFolders: hasFolders, indexing: true);
    try {
      await index();
      state = LibraryReady(hasFolders: hasFolders);
    } on Exception {
      state = LibraryReady(hasFolders: hasFolders, indexFailed: true);
    }
    // The removable disks and the files' tags follow the internal index
    // (FR-006.8, FR-007).
    unawaited(ref.read(removableControllerProvider.notifier).refresh());
  }
}
