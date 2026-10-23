import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/features/library/first_launch_pages.dart';
import 'package:tuneshell/features/library/folder_choice_view.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/library_header.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/library_track_list.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/library/removable_messages.dart';
import 'package:tuneshell/features/library/removable_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// The Tracks view: the library list, and the screens that lead to it (the
/// permission, the folder choice).
///
/// @implements UC-001
/// @implements FR-011
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
    ref.listen(removableControllerProvider.select((s) => s.message), (
      _,
      message,
    ) {
      // The disks screen shows its own messages; here only the first-launch
      // screens, where "Choisir un dossier à la place" can fail.
      if (message == null || state is LibraryReady) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removableMessageText(l10n, message))),
      );
      ref.read(removableControllerProvider.notifier).clearMessage();
    });
    final cancelable = switch (state) {
      LibraryFolderChoice(:final cancelable) => cancelable,
      LibraryLoadFailed(:final cancelable) => cancelable,
      _ => false,
    };
    // The first-launch screens have their own full-screen design (FR-014).
    final withBar = state is LibraryFolderChoice || state is LibraryLoadFailed;
    // FR-003.4: Back leaves the folder choice before it leaves the app.
    final explaining = state is LibraryWelcome && state.explaining;
    return PopScope(
      canPop: !cancelable && !explaining,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (explaining) {
          _controller.backToWelcome();
        } else {
          _controller.cancelFolderChoice();
        }
      },
      child: Scaffold(
        appBar: withBar
            ? AppBar(
                leading: cancelable
                    ? IconButton(
                        tooltip: l10n.foldersBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: _controller.cancelFolderChoice,
                      )
                    : null,
                title: Text(l10n.foldersTitle),
              )
            : null,
        body: switch (state) {
          LibraryStarting() => const Center(child: CircularProgressIndicator()),
          LibraryWelcome(:final explaining) =>
            explaining
                ? AccessExplanationPage(
                    refused: false,
                    onAllow: () => unawaited(_controller.requestPermission()),
                    onNotNow: _controller.declineAccess,
                  )
                : WelcomePage(onStart: _controller.showExplanation),
          LibraryPermissionNeeded(:final permanent) =>
            permanent
                ? AccessBlockedPage(
                    onOpenSettings: () =>
                        unawaited(_controller.requestPermission()),
                    onChooseFolder: () =>
                        unawaited(_controller.chooseFolderInstead()),
                  )
                : AccessExplanationPage(
                    refused: true,
                    onAllow: () => unawaited(_controller.requestPermission()),
                    onNotNow: _controller.declineAccess,
                  ),
          LibraryAccessDeclined() => AccessDeclinedView(
            onAllow: _controller.showExplanation,
          ),
          LibraryLoadFailed() => FolderLoadFailedView(
            onRetry: () => unawaited(_controller.retry()),
          ),
          LibraryFolderChoice() => FolderChoiceView(
            key: ValueKey(state),
            choice: state,
            onConfirm: (folders) =>
                unawaited(_controller.confirmFolders(folders)),
            onAddFolder: () => unawaited(_controller.addRemovableFolder()),
            onReload: () => unawaited(_controller.reloadFolders()),
          ),
          LibraryReady() => _ReadyView(
            state: state,
            onRefresh: () => unawaited(_controller.refresh()),
            onFolders: () => unawaited(_controller.openFolderChoice()),
          ),
        },
      ),
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

/// The ready library: header, chips, banners, count and list, in the flow
/// from top to bottom, nothing over the list (FR-011.3, BR-007 rule 2).
class _ReadyView extends ConsumerWidget {
  const new({
    required this.state,
    required this.onRefresh,
    required this.onFolders,
  });

  final LibraryReady state;
  final VoidCallback onRefresh;
  final VoidCallback onFolders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final model = ref.watch(libraryListModelProvider);
    final tagProgress = ref.watch(tagProgressProvider).value;
    final absent = ref.watch(
      unavailableDisksProvider.select((disks) => disks.length),
    );
    final searching = state.indexing && (model == null || model.total == 0);
    final empty = model != null && model.total == 0 && !state.indexing;
    final banner = model?.banner;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LibraryTitleBar(),
          LibraryActionChips(
            busy: state.indexing,
            absentDisks: absent,
            onRefresh: onRefresh,
            onFolders: onFolders,
            onDisks: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const RemovablePage()),
            ),
          ),
          if (searching)
            ProgressBanner(label: l10n.libraryScanning)
          else if (tagProgress != null && tagProgress.running)
            ProgressBanner(
              label: l10n.tagsProgress(tagProgress.done, tagProgress.total),
              value: tagProgress.done / tagProgress.total,
            ),
          if (state.indexFailed)
            StatusBanner(
              kind: BannerKind.error,
              message: l10n.libraryIndexFailed,
              actionLabel: l10n.libraryRefresh,
              onAction: onRefresh,
            ),
          if (banner != null)
            SourcesBanner(
              banner: banner,
              onSee: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const RemovablePage()),
              ),
              onDismiss: () => ref
                  .read(dismissedBannerProvider.notifier)
                  .dismiss(banner.fingerprint),
            ),
          if (!empty)
            LibraryCountRow(
              text: searching || model == null
                  ? l10n.libraryCountSearching
                  : l10n.libraryCount(model.total, model.unavailableCount),
              showSort: !searching && model != null,
            ),
          Expanded(
            child: model == null || searching
                ? const _Skeleton()
                : empty
                ? _EmptyLibrary(
                    hasFolders: state.hasFolders,
                    onChooseFolders: onFolders,
                    onRefresh: onRefresh,
                  )
                : LibraryTrackList(model: model),
          ),
        ],
      ),
    );
  }
}

/// Rows in skeleton while the first scan runs (FR-011.4).
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (var i = 0; i < 12; i++)
        const TrackTile(title: '', state: TrackTileState.loading),
    ],
  );
}

/// FR-011.9: an empty library, or no folder chosen.
class _EmptyLibrary extends StatelessWidget {
  const new({
    required this.hasFolders,
    required this.onChooseFolders,
    required this.onRefresh,
  });

  final bool hasFolders;
  final VoidCallback onChooseFolders;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: TsSize.coverPanel / 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: TsSpace.l),
            Text(
              hasFolders ? l10n.emptyLibraryTitle : l10n.emptyNoFoldersTitle,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TsSpace.s),
            Text(
              hasFolders ? l10n.emptyLibraryBody : l10n.emptyNoFoldersBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TsSpace.l),
            FilledButton(
              onPressed: onChooseFolders,
              child: Text(l10n.chooseFoldersAction),
            ),
            if (hasFolders) ...[
              const SizedBox(height: TsSpace.s),
              OutlinedButton(
                onPressed: onRefresh,
                child: Text(l10n.libraryRefresh),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
