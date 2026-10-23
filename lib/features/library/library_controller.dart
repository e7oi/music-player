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

/// FR-014.1 and .2: the first launch, before Android was ever asked. The
/// welcome first, then the explanation that leads to the dialog.
final class LibraryWelcome extends LibraryViewState {
  const new({this.explaining = false});

  /// Second step: why access is needed, and the button that asks for it.
  final bool explaining;
}

/// FR-014.6: the user chose "not now"; the library shows without access.
final class LibraryAccessDeclined extends LibraryViewState {
  const new();
}

/// FR-004: access to the audio files is missing. Not permanent: the
/// explanation with a refusal banner (FR-014.3); permanent: Android no longer
/// asks (FR-014.5).
final class LibraryPermissionNeeded extends LibraryViewState {
  const new({required this.permanent});

  /// Android no longer shows its dialog: only the app settings help.
  final bool permanent;
}

/// The folders of the phone could not be read; [LibraryController.start]
/// retries.
final class LibraryLoadFailed extends LibraryViewState {
  const new({this.whileChoosingFolders = false, this.cancelable = false});

  /// Retry reopens the folder choice rather than restarting.
  final bool whileChoosingFolders;

  /// The choice was opened from the library: Back returns to it.
  final bool cancelable;
}

/// FR-003: the user picks the folders to index.
@immutable
final class LibraryFolderChoice extends LibraryViewState {
  const new({
    required this.folders,
    required this.selected,
    this.cancelable = false,
    this.loading = false,
  });

  final List<FolderSummary> folders;

  /// The folders are being read: the screen shows skeletons (FR-015.3).
  final bool loading;
  final Set<String> selected;

  /// Opened from the library, so that Back returns to it; false on first
  /// launch, when a choice is required (FR-003.3).
  final bool cancelable;
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

/// The welcome, the explanation and the blocked screen fill the window
/// (FR-014.7); the library with its navigation does not.
bool isFirstLaunchScreen(LibraryViewState state) =>
    state is LibraryWelcome || state is LibraryPermissionNeeded;

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryViewState>(
      LibraryController.new,
    );

/// Permission, folder choice and indexing of the internal storage; each
/// index is followed by the removable disks and the tags.
///
/// @implements UC-001
/// @implements UC-006
/// @implements FR-003
/// @implements FR-004
/// @implements FR-014
/// @implements FR-015
class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryStarting();

  LibraryIndexer get _indexer => ref.read(libraryIndexerProvider);

  /// The permission dialog pauses and resumes the app: [onResumed] and
  /// [requestPermission] may both continue at once. They share this run.
  Future<void>? _continuing;

  AudioPermission get _permission => ref.read(audioPermissionProvider);

  /// The first launch shows the welcome and waits for the button: Android is
  /// asked only from there (FR-014.1, FR-014.2). Later launches show the
  /// library and reindex (FR-003).
  Future<void> start() async {
    _withoutAccess = false;
    final status = await _permission.status();
    if (status == AudioPermissionStatus.notRequested) {
      state = const LibraryWelcome();
      return;
    }
    await _continueWith(status);
  }

  /// "Commencer", or the offer after "Pas maintenant" (FR-014.2).
  void showExplanation() => state = const LibraryWelcome(explaining: true);

  /// Back from the explanation returns to the welcome (FR-014.2).
  void backToWelcome() => state = const LibraryWelcome();

  /// "Pas maintenant" (FR-014.6).
  void declineAccess() => state = const LibraryAccessDeclined();

  /// True once the library holds only what a disk folder gave, without
  /// access to the phone's audio (FR-014.5).
  bool _withoutAccess = false;

  /// "Choisir un dossier à la place" (FR-014.5): the Android picker for a
  /// folder of a removable disk; the phone's own folders stay with
  /// MediaStore (D25). From the blocked screen only: a folder that gives
  /// tracks leads to the library.
  Future<void> chooseFolderInstead() async {
    final removable = ref.read(removableControllerProvider.notifier);
    final before = _folderCount();
    await removable.addFolder();
    if (!ref.mounted || state is! LibraryPermissionNeeded) return;
    if (_folderCount() <= before) return;
    _withoutAccess = true;
    state = const LibraryReady(hasFolders: false);
  }

  /// "Ajouter un dossier" of the folder choice (FR-015.7): the disk is
  /// registered for the disks screen; the choice stays as the user left it.
  Future<void> addRemovableFolder() =>
      ref.read(removableControllerProvider.notifier).addFolder();

  int _folderCount() => ref
      .read(removableControllerProvider)
      .disks
      .fold(0, (sum, disk) => sum + disk.folders.length);

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
    final current = state;
    final waiting =
        current is LibraryPermissionNeeded ||
        current is LibraryAccessDeclined ||
        current is LibraryWelcome;
    if (status == AudioPermissionStatus.granted) {
      if (waiting || (_withoutAccess && current is LibraryReady)) {
        _withoutAccess = false;
        await _continueWith(status);
      }
      return;
    }
    // Nothing was refused yet, or the user chose not to grant it for now.
    if (status == AudioPermissionStatus.notRequested) return;
    if (current is LibraryAccessDeclined) return;
    if (_withoutAccess && current is LibraryReady) return;
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
    // Without access the phone's folders cannot be listed: ask for it.
    if (_withoutAccess) {
      showExplanation();
      return;
    }
    // Remembered so that the user can leave the choice unchanged.
    if (current is LibraryReady) _beforeChoice = current;
    final cancelable = _beforeChoice != null;
    state = LibraryFolderChoice(
      folders: const [],
      selected: const {},
      cancelable: cancelable,
      loading: true,
    );
    final loading = state;
    try {
      final folders = await _indexer.availableFolders();
      final selected = await _indexer.chosenFolders();
      // Back may have left the choice while it loaded.
      if (!ref.mounted || !identical(state, loading)) return;
      state = LibraryFolderChoice(
        folders: folders,
        selected: selected,
        cancelable: cancelable,
      );
    } on Exception {
      if (!ref.mounted || !identical(state, loading)) return;
      state = LibraryLoadFailed(
        whileChoosingFolders: true,
        cancelable: cancelable,
      );
    }
  }

  /// The library the user left to choose folders; null on first launch, when
  /// a choice is required (FR-003.3).
  LibraryReady? _beforeChoice;

  /// Leaves the folder choice without changing it (FR-003.4).
  void cancelFolderChoice() {
    final before = _beforeChoice;
    final current = state;
    final cancelable = switch (current) {
      LibraryFolderChoice(:final cancelable) => cancelable,
      LibraryLoadFailed(:final cancelable) => cancelable,
      _ => false,
    };
    if (before == null || !cancelable) return;
    _beforeChoice = null;
    state = before;
  }

  /// "Actualiser" of an empty folder list (FR-015.5).
  Future<void> reloadFolders() =>
      _beforeChoice == null ? start() : openFolderChoice();

  Future<void> retry() async {
    final current = state;
    if (current is LibraryLoadFailed && current.whileChoosingFolders) {
      await openFolderChoice();
    } else {
      await start();
    }
  }

  /// The user's "Refresh": unreadable files get another chance (FR-007.3).
  Future<void> refresh() => _refresh(retryFailed: true);

  Future<void> _refresh({required bool retryFailed}) async {
    if (_withoutAccess) {
      // Only the disks can be read without access.
      await ref
          .read(removableControllerProvider.notifier)
          .refresh(retryFailed: retryFailed);
      return;
    }
    final folders = await _indexer.chosenFolders();
    await _runIndex(
      _indexer.index,
      hasFolders: folders.isNotEmpty,
      retryFailed: retryFailed,
    );
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
      state = const LibraryFolderChoice(
        folders: [],
        selected: {},
        loading: true,
      );
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
    await _refresh(retryFailed: false);
  }

  Future<void> _runIndex(
    Future<Object?> Function() index, {
    required bool hasFolders,
    bool retryFailed = false,
  }) async {
    _beforeChoice = null;
    state = LibraryReady(hasFolders: hasFolders, indexing: true);
    try {
      await index();
      state = LibraryReady(hasFolders: hasFolders);
    } on Exception {
      state = LibraryReady(hasFolders: hasFolders, indexFailed: true);
    }
    // The removable disks and the files' tags follow the internal index
    // (FR-006.8, FR-007).
    unawaited(
      ref
          .read(removableControllerProvider.notifier)
          .refresh(retryFailed: retryFailed),
    );
  }
}
