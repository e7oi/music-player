import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';

enum RemovableMessage { noAudio, addFailed, notRemovable, refreshFailed }

@immutable
final class RemovableViewState {
  const new({this.disks = const [], this.busy = false, this.message});

  final List<RemovableDisk> disks;

  /// A scan is running.
  final bool busy;

  /// Shown once, then cleared by [RemovableController.clearMessage].
  final RemovableMessage? message;

  RemovableViewState copyWith({
    List<RemovableDisk>? disks,
    bool? busy,
    RemovableMessage? message,
    bool clearMessage = false,
  }) => RemovableViewState(
    disks: disks ?? this.disks,
    busy: busy ?? this.busy,
    message: clearMessage ? null : message ?? this.message,
  );
}

final removableControllerProvider =
    NotifierProvider<RemovableController, RemovableViewState>(
      RemovableController.new,
    );

/// Removable disks: their folders, their state, the scans (UC-003).
///
/// @implements UC-003
/// @implements FR-006
class RemovableController extends Notifier<RemovableViewState> {
  @override
  RemovableViewState build() => const RemovableViewState();

  RemovableIndexer get _indexer => ref.read(removableIndexerProvider);

  Future<void> load() async {
    if (!ref.mounted) return;
    try {
      final disks = await _indexer.disks();
      _update(disks: disks);
    } on Exception {
      // The list keeps its last value; a refresh reports the failure.
    }
  }

  /// FR-006.10: the app is back in the foreground.
  Future<void> onResumed() async {
    try {
      await ref.read(volumeEventsProvider).refresh();
    } on Exception {
      // Availability stays as it was.
    }
    await load();
  }

  /// Scans the disks, then reads the tags and artwork of what is pending.
  Future<void> refresh() async {
    _update(busy: true);
    try {
      await ref.read(volumeEventsProvider).refresh();
      await _indexer.refreshAll();
    } on ScanCancelledException {
      // The user stopped it.
    } on Exception {
      _update(message: RemovableMessage.refreshFailed);
    }
    _update(busy: false);
    await load();
    unawaited(_readTags());
  }

  /// UC-003: the Android picker, then the scan of the chosen folder. Also
  /// the way to renew a lost access (FR-006.11).
  Future<void> addFolder() async {
    _update(busy: true);
    try {
      final result = await _indexer.addFolder();
      if (result == AddFolderResult.noAudio) {
        _update(message: RemovableMessage.noAudio);
      }
    } on NotRemovableException {
      _update(message: RemovableMessage.notRemovable);
    } on ScanCancelledException {
      // The user stopped it.
    } on Exception {
      _update(message: RemovableMessage.addFailed);
    }
    _update(busy: false);
    if (!ref.mounted) return;
    await ref.read(volumeEventsProvider).refresh();
    await load();
    unawaited(_readTags());
  }

  Future<void> removeFolder(DiskId disk, String folder) async {
    _update(busy: true);
    try {
      await _indexer.removeFolder(disk, folder);
    } on Exception {
      _update(message: RemovableMessage.refreshFailed);
    }
    _update(busy: false);
    await load();
    unawaited(_readTags());
  }

  /// BR-006.5: stops the scan and the tags in progress.
  Future<void> cancel() async {
    ref.read(tagIndexerProvider).cancel();
    await _indexer.cancel();
  }

  void clearMessage() => _update(clearMessage: true);

  /// The provider can go away while a scan runs (tests, hot restart).
  void _update({
    List<RemovableDisk>? disks,
    bool? busy,
    RemovableMessage? message,
    bool clearMessage = false,
  }) {
    if (!ref.mounted) return;
    state = state.copyWith(
      disks: disks,
      busy: busy,
      message: message,
      clearMessage: clearMessage,
    );
  }

  Future<void> _readTags() async {
    if (!ref.mounted) return;
    try {
      await ref.read(tagIndexerProvider).run();
    } on Exception {
      // The tracks stay pending; the next refresh reads them.
    }
  }
}
