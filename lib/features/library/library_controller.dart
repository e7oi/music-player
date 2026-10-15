import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:musicplayer/app/providers/library_providers.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/domain/library/services/library_indexer.dart';

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

/// Permission, folder choice and indexing of the internal storage.
///
/// @implements UC-001
/// @implements FR-003
/// @implements FR-004
class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryStarting();

  LibraryIndexer get _indexer => ref.read(libraryIndexerProvider);

  AudioPermission get _permission => ref.read(audioPermissionProvider);

  /// First launch asks for access once (FR-004.1), then offers the folders;
  /// later launches show the library and reindex (FR-003).
  Future<void> start() async {
    var status = await _permission.status();
    if (status == AudioPermissionStatus.denied) {
      status = await _permission.request();
    }
    await _continueWith(status);
  }

  Future<void> requestPermission() async {
    if (await _permission.status() == AudioPermissionStatus.permanentlyDenied) {
      await _permission.openAppSettings();
      return;
    }
    await _continueWith(await _permission.request());
  }

  /// FR-004.5: access may have changed in the settings while away.
  Future<void> onResumed() async {
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

  Future<void> openFolderChoice() async {
    state = LibraryFolderChoice(
      folders: await _indexer.availableFolders(),
      selected: await _indexer.chosenFolders(),
    );
  }

  Future<void> refresh() async {
    final folders = await _indexer.chosenFolders();
    await _runIndex(_indexer.index, hasFolders: folders.isNotEmpty);
  }

  Future<void> _continueWith(AudioPermissionStatus status) async {
    if (status != AudioPermissionStatus.granted) {
      state = LibraryPermissionNeeded(
        permanent: status == AudioPermissionStatus.permanentlyDenied,
      );
      return;
    }
    if (await _indexer.needsFolderChoice()) {
      final folders = await _indexer.availableFolders();
      state = LibraryFolderChoice(
        folders: folders,
        selected: LibraryIndexer.defaultSelection(folders),
      );
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
  }
}
