import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/player_bar.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// Temporary library screen until the MPL-016 mock-ups exist.
///
/// @implements UC-001
class LibraryPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final AppLifecycleListener _lifecycle;

  LibraryController get _controller =>
      ref.read(libraryControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_controller.onResumed()),
    );
    // The controller starts once the first frame has a provider scope.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_controller.start()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(libraryControllerProvider);
    ref.listen(playbackNoticesProvider, (_, next) {
      final notice = next.value;
      if (notice != null) _showNotice(context, notice);
    });
    final ready = state is LibraryReady;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (ready) ...[
            IconButton(
              tooltip: l10n.libraryFolders,
              icon: const Icon(Icons.folder_outlined),
              onPressed: state.indexing
                  ? null
                  : () => unawaited(_controller.openFolderChoice()),
            ),
            IconButton(
              tooltip: l10n.libraryRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: state.indexing
                  ? null
                  : () => unawaited(_controller.refresh()),
            ),
          ],
        ],
      ),
      body: switch (state) {
        LibraryStarting() => const Center(child: CircularProgressIndicator()),
        LibraryPermissionNeeded(:final permanent) => _Message(
          text: l10n.permissionExplanation,
          action: permanent
              ? l10n.permissionOpenSettings
              : l10n.permissionRetry,
          onAction: () => unawaited(_controller.requestPermission()),
        ),
        LibraryLoadFailed() => _Message(
          text: l10n.libraryLoadFailed,
          action: l10n.libraryRetry,
          onAction: () => unawaited(_controller.retry()),
        ),
        LibraryFolderChoice() => FolderChoiceView(
          key: ValueKey(state),
          choice: state,
          onConfirm: (folders) =>
              unawaited(_controller.confirmFolders(folders)),
        ),
        LibraryReady() => _TrackList(state: state),
      },
      // Playback goes on while the folders are open.
      bottomNavigationBar: ready || state is LibraryFolderChoice
          ? const PlayerBar()
          : null,
    );
  }

  void _showNotice(BuildContext context, PlaybackNotice notice) {
    final l10n = AppLocalizations.of(context);
    final tracks = ref.read(libraryTracksProvider).value ?? const [];
    final text = switch (notice) {
      TracksSkipped(:final count) => l10n.noticeTracksSkipped(count),
      TrackFailed(:final track) => l10n.noticeTrackFailed(
        tracks.where((t) => t.track == track).firstOrNull?.displayTitle ??
            track.relativePath,
      ),
      PlaybackStoppedAfterFailures(:final consecutiveFailures) =>
        l10n.noticeStoppedAfterFailures(consecutiveFailures),
      PlaybackStoppedByEjection() => l10n.noticeStoppedByEjection,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Message extends StatelessWidget {
  const new({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

/// FR-003: top-level folders that hold audio, with their file counts.
class FolderChoiceView extends StatefulWidget {
  const new({required this.choice, required this.onConfirm, super.key});

  final LibraryFolderChoice choice;
  final ValueChanged<Set<String>> onConfirm;

  @override
  State<FolderChoiceView> createState() => _FolderChoiceViewState();
}

class _FolderChoiceViewState extends State<FolderChoiceView> {
  late final Set<String> _selected = {...widget.choice.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folders = widget.choice.folders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.foldersTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.foldersExplanation),
            ],
          ),
        ),
        Expanded(
          child: folders.isEmpty
              ? _Message(text: l10n.foldersNone)
              : ListView(
                  children: [
                    for (final FolderSummary folder in folders)
                      CheckboxListTile(
                        value: _selected.contains(folder.path),
                        title: Text(
                          folder.path.isEmpty ? l10n.foldersRoot : folder.path,
                        ),
                        subtitle: Text(l10n.folderFileCount(folder.fileCount)),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(folder.path);
                          } else {
                            _selected.remove(folder.path);
                          }
                        }),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => widget.onConfirm({..._selected}),
            child: Text(l10n.foldersConfirm),
          ),
        ),
      ],
    );
  }
}

class _TrackList extends ConsumerWidget {
  const new({required this.state});

  final LibraryReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tracks =
        ref.watch(libraryTracksProvider).value ?? const <LibraryTrack>[];
    final controller = ref.read(libraryControllerProvider.notifier);
    return Column(
      children: [
        if (state.indexing) const LinearProgressIndicator(),
        if (state.indexFailed)
          MaterialBanner(
            content: Text(l10n.libraryIndexFailed),
            actions: [
              TextButton(
                onPressed: () => unawaited(controller.refresh()),
                child: Text(l10n.libraryRefresh),
              ),
            ],
          ),
        Expanded(
          child: tracks.isEmpty && !state.indexing
              ? _Message(
                  text: state.hasFolders
                      ? l10n.libraryEmpty
                      : l10n.libraryNoFolders,
                  action: l10n.libraryChooseFolders,
                  onAction: () => unawaited(controller.openFolderChoice()),
                )
              : ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      title: Text(track.displayTitle),
                      subtitle: track.info.artist == null
                          ? null
                          : Text(track.info.artist!),
                      onTap: () => unawaited(_play(ref, tracks, index)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// UC-001: the queue is the whole list, in the displayed order.
  Future<void> _play(
    WidgetRef ref,
    List<LibraryTrack> tracks,
    int index,
  ) async {
    final player = ref.read(playerControllerProvider);
    await player.setQueue([for (final t in tracks) t.track], startIndex: index);
    await player.play();
  }
}
