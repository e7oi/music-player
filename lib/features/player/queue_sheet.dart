import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/queue_model.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// Opens the queue as a sheet over the player (FR-018.1).
Future<void> showQueueSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: TsSize.queueSheetInitial,
    minChildSize: TsSize.queueSheetMin,
    builder: (context, scroll) => QueueSheet(scroll: scroll),
  ),
);

/// The queue: the track playing, then what follows, which can be reordered,
/// removed by a swipe and cleared (FR-018).
///
/// @implements FR-018
class QueueSheet extends ConsumerWidget {
  const new({required this.scroll, super.key});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(
      playerStateProvider.select(
        (s) => (
          s.value?.queue,
          s.value?.currentIndex,
          s.value?.entryIds,
          s.value?.shuffle ?? false,
          s.value?.availableDisks,
        ),
      ),
    );
    final (queue, current, ids, shuffle, available) = state;
    if (queue == null || available == null) return const SizedBox.shrink();
    final model = QueueModel.build(
      queue: queue,
      currentIndex: current,
      lookup: ref.watch(trackIndexProvider),
      disks: ref.watch(playerDisksProvider),
      availableDisks: available,
      entryIds: ids ?? const [],
    );
    final player = ref.read(playerControllerProvider);
    final duration = formatClock(model.totalDuration);
    final summary = shuffle
        ? l10n.queueSummaryShuffled(model.total, duration)
        : l10n.queueSummary(model.total, duration);
    final now = model.current;

    void remove(QueueRow row) {
      unawaited(player.removeAt(row.queueIndex));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.queueRemoved(row.title))));
    }

    Widget header(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(
        TsSpace.screenMargin,
        TsSpace.m,
        TsSpace.screenMargin,
        TsSpace.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );

    return CustomScrollView(
      controller: scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TsSpace.screenMargin,
            ),
            // A Wrap: at large text the button goes under the title instead of
            // overflowing (FR-018.12).
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.queueTitle, style: text.titleLarge),
                    Text(
                      summary,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: model.upcomingCount == 0
                      ? null
                      : () => unawaited(player.clearUpcoming()),
                  child: Text(l10n.queueClear),
                ),
              ],
            ),
          ),
        ),
        if (now != null) ...[
          SliverToBoxAdapter(child: header(l10n.queueNow)),
          SliverToBoxAdapter(
            child: _QueueTile(row: now, current: true, onTap: null),
          ),
        ],
        if (model.upcomingCount > 0) ...[
          SliverToBoxAdapter(child: header(l10n.queueNext)),
          SliverReorderableList(
            itemCount: model.upcomingCount,
            onReorderItem: (from, to) {
              final base = (current ?? -1) + 1;
              unawaited(player.move(base + from, base + to));
            },
            itemBuilder: (context, n) {
              final row = model.upcoming(n);
              return Dismissible(
                key: ValueKey(row.id),
                resizeDuration: null,
                background: const _SwipeBackground(),
                onDismissed: (_) => remove(row),
                child: Semantics(
                  customSemanticsActions: {
                    CustomSemanticsAction(label: l10n.queueRemove): () =>
                        remove(row),
                  },
                  child: _QueueTile(
                    row: row,
                    index: n,
                    onTap: () => unawaited(player.skipTo(row.queueIndex)),
                  ),
                ),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(
          child: SizedBox(height: TsSize.listBottomInset),
        ),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.errorContainer,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
          child: Icon(
            Icons.remove_circle_outline_rounded,
            color: scheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const new({
    required this.row,
    required this.onTap,
    this.current = false,
    this.index,
  });

  final QueueRow row;
  final VoidCallback? onTap;
  final bool current;

  /// Position in the reorderable list; null for the current track.
  final int? index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final artist = row.artist ?? l10n.trackUnknownArtist;
    final name = sourceName(row.disk, l10n);
    final id = row.artwork;
    final duration = row.duration == null ? null : formatClock(row.duration!);
    final tile = TrackTile(
      title: row.title,
      artist: artist,
      duration: duration,
      state: !row.available
          ? TrackTileState.unavailable
          : current
          ? TrackTileState.playing
          : TrackTileState.normal,
      mark: sourceMarkOf(row.disk, TsColors.of(context)),
      artwork: id == null ? null : ref.watch(artworkImageProvider(id)),
      unavailableLabel: l10n.queueWillSkip(artist),
      playingLabel: l10n.trackPlaying,
      semanticsLabel: [
        row.title,
        artist,
        ?duration,
        if (current) l10n.trackPlaying,
        if (!row.available) l10n.queueWillSkip(artist),
        ?name == null ? null : l10n.trackSource(name),
      ].join(', '),
      onTap: onTap,
    );
    if (index == null) return tile;
    return Row(
      children: [
        Expanded(child: tile),
        ReorderableDragStartListener(
          index: index!,
          child: Semantics(
            container: true,
            button: true,
            label: l10n.queueMove(row.title),
            child: const SizedBox.square(
              dimension: TsSize.touchTarget,
              child: Icon(Icons.drag_handle_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
