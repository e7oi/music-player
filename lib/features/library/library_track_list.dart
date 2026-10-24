import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/player/player_page.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// The scrolling list of tracks with its alphabet index and its "now playing"
/// button (FR-011, FR-013, ADR-013).
///
/// @implements FR-011
/// @implements FR-013
class LibraryTrackList extends ConsumerStatefulWidget {
  const new({required this.model, super.key});

  final LibraryListModel model;

  @override
  ConsumerState<LibraryTrackList> createState() => _LibraryTrackListState();
}

class _LibraryTrackListState extends ConsumerState<LibraryTrackList> {
  /// The key of this view in the rectangles kept out of the Back gesture.
  static const _owner = 'library-tracks';

  final ScrollController _scroll = ScrollController();

  /// Bumped when the size of the list or of its content changes, so that the
  /// button re-reads the scroll position.
  final ValueNotifier<int> _layout = ValueNotifier(0);
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  final ValueNotifier<int?> _flash = ValueNotifier(null);
  Timer? _unfold;
  Timer? _flashTimer;
  Rect? _handle;

  /// Read in didChangeDependencies: the index reports its removal while the
  /// element is being unmounted, when the context can no longer be asked.
  double _ratio = 1;
  bool _inFront = true;

  /// Kept apart: a ref cannot be read in dispose.
  late final GestureRegions _regions = ref.read(gestureRegionsProvider);

  Future<void> _setRects(List<Rect> rects) => _regions.set(_owner, rects);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ratio = View.of(context).devicePixelRatio;
    // IndexedStack does not stop the tickers of the tabs it hides, but it
    // says which one is visible (ADR-016).
    _inFront = TickerMode.valuesOf(context).enabled && Visibility.of(context);
    _sendExclusion();
  }

  @override
  void didUpdateWidget(LibraryTrackList oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _layout.value++;
    });
  }

  @override
  void dispose() {
    _unfold?.cancel();
    _flashTimer?.cancel();
    unawaited(_setRects(const []));
    _scroll.dispose();
    _layout.dispose();
    _scrolling.dispose();
    _flash.dispose();
    super.dispose();
  }

  /// FR-013.2: the handle keeps the Back gesture out only while this view is
  /// in front (a view behind another stops its tickers).
  void _sendExclusion() {
    final rect = _handle;
    final ratio = _ratio;
    final shown = rect != null && _inFront;
    unawaited(
      _setRects([
        if (shown)
          Rect.fromLTRB(
            rect.left * ratio,
            rect.top * ratio,
            rect.right * ratio,
            rect.bottom * ratio,
          ),
      ]),
    );
  }

  /// Row height: 64 dp up to 1.3 times the text, proportional beyond so that
  /// large text is not cut and the jumps stay exact (BR-007 rule 9).
  double get _rowExtent {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return scale <= TsSize.fixedRowMaxTextScale
        ? TsSize.trackRow
        : TsSize.trackRow * scale;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _unfold?.cancel();
      _scrolling.value = true;
      _unfold = Timer(TsMotion.indexHideDelay, () => _scrolling.value = false);
    }
    if (notification is ScrollMetricsNotification) _layout.value++;
    return false;
  }

  void _toLetter(String letter) {
    final index = widget.model.firstIndex[letter];
    if (index == null || !_scroll.hasClients) return;
    _scroll.jumpTo(
      (index * _rowExtent).clamp(0, _scroll.position.maxScrollExtent),
    );
  }

  Future<void> _toCurrent() async {
    final target = widget.model.jumpTarget;
    if (target == null || !_scroll.hasClients) return;
    final position = _scroll.position;
    final offset = jumpOffset(
      index: target.index,
      viewport: position.viewportDimension,
      rowExtent: _rowExtent,
      maxScroll: position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(offset);
    } else {
      await _scroll.animateTo(
        offset,
        duration: TsMotion.long,
        curve: TsMotion.standard,
      );
    }
    if (!mounted) return;
    _flash.value = target.index;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 1), () => _flash.value = null);
  }

  Future<void> _play(int index) async {
    final player = ref.read(playerControllerProvider);
    ref.read(queueOriginProvider.notifier).set(QueueOrigin.tracksByTitle);
    // UC-001: the queue is the whole list, in the displayed order.
    await player.setQueue([
      for (final e in widget.model.entries) e.track.track,
    ], startIndex: index);
    await player.play();
  }

  void _onTap(int index) {
    final entry = widget.model.entries[index];
    if (entry.state != TrackTileState.unavailable) {
      unawaited(_play(index));
      return;
    }
    // BR-008, rule 5: say what to do, start nothing.
    final l10n = AppLocalizations.of(context);
    final name = entry.disk?.label ?? entry.track.disk.value;
    final issue = ref.read(unavailableDisksProvider)[entry.track.disk];
    final text = issue == DiskIssue.accessLost
        ? l10n.trackNeedsAccess(name)
        : l10n.trackNeedsDisk(name);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final model = widget.model;
    final list = CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverFixedExtentList(
          itemExtent: _rowExtent,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _row(index),
            childCount: model.entries.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: TsSize.listBottomInset),
        ),
      ],
    );
    return Stack(
      children: [
        AlphabetScroller(
          letters: model.letters,
          itemCount: model.total,
          onLetterSelected: _toLetter,
          countLabel: l10n.indexCount,
          letterSemantics: l10n.indexLetter,
          gridTitle: l10n.indexGoToLetter,
          onHandleRect: (rect) {
            _handle = rect;
            _sendExclusion();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: list,
          ),
        ),
        PositionedDirectional(
          end: TsSpace.l,
          bottom: TsSpace.l,
          child: ListenableBuilder(
            listenable: Listenable.merge([_scroll, _scrolling, _layout]),
            builder: (context, _) => _fab(l10n),
          ),
        ),
      ],
    );
  }

  Widget _fab(AppLocalizations l10n) {
    if (widget.model.currentOutsideList) {
      // FR-013.5: the track is not in this list; the player shows it.
      return JumpToCurrentFab(
        label: l10n.jumpCurrent,
        showArrow: false,
        folded: _scrolling.value,
        onPressed: () => unawaited(openPlayer(context, ref)),
      );
    }
    final target = widget.model.jumpTarget;
    JumpDirection? direction;
    if (target != null && _scroll.hasClients) {
      final position = _scroll.position;
      if (position.hasContentDimensions && position.hasViewportDimension) {
        direction = jumpDirection(
          index: target.index,
          offset: position.pixels,
          viewport: position.viewportDimension,
          rowExtent: _rowExtent,
        );
      }
    }
    final lastPlayed = target?.lastPlayed ?? false;
    return JumpToCurrentFab(
      label: lastPlayed ? l10n.jumpLastPlayed : l10n.jumpCurrent,
      lastPlayed: lastPlayed,
      direction: direction ?? JumpDirection.down,
      visible: direction != null,
      folded: _scrolling.value,
      onPressed: () => unawaited(_toCurrent()),
    );
  }

  Widget _row(int index) => ValueListenableBuilder<int?>(
    valueListenable: _flash,
    builder: (context, flash, _) => _TrackRow(
      entry: widget.model.entries[index],
      flashed: flash == index,
      onTap: () => _onTap(index),
      onLongPress: () => unawaited(
        showTrackMenu(context, ref, widget.model.entries[index].track),
      ),
    ),
  );
}

class _TrackRow extends ConsumerWidget {
  const new({
    required this.entry,
    required this.flashed,
    required this.onTap,
    required this.onLongPress,
  });

  final LibraryEntry entry;
  final bool flashed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = TsColors.of(context);
    final track = entry.track;
    final disk = entry.disk;
    final artworkId = track.artwork;
    final artist = track.info.artist ?? l10n.trackUnknownArtist;
    final duration = _formatDuration(track.info.duration);
    final source = switch (disk) {
      null => null,
      Disk(kind: DiskKind.internal) => l10n.sourceLocal,
      Disk(:final label) => label,
    };
    final mark = switch (disk) {
      null => null,
      Disk(kind: DiskKind.internal) => SourceMark.local(colors),
      Disk(markIndex: final index?) => SourceMark.disk(index, colors),
      Disk() => null,
    };
    final unavailableLabel = l10n.trackNotConnected(artist);
    final stateWord = switch (entry.state) {
      TrackTileState.playing => l10n.trackPlaying,
      TrackTileState.unavailable => unavailableLabel,
      TrackTileState.unreadable => l10n.trackUnreadable,
      _ => null,
    };
    final tile = TrackTile(
      title: track.displayTitle,
      artist: artist,
      duration: duration,
      state: entry.state,
      mark: mark,
      artwork: artworkId == null
          ? null
          : ref.watch(artworkImageProvider(artworkId)),
      unavailableLabel: unavailableLabel,
      unreadableLabel: l10n.trackUnreadable,
      playingLabel: l10n.trackPlaying,
      semanticsLabel: [
        track.displayTitle,
        artist,
        ?duration,
        ?stateWord,
        if (source != null) l10n.trackSource(source),
      ].join(', '),
      onTap: onTap,
      onLongPress: onLongPress,
    );
    final withActions = Semantics(
      // FR-019.1: the menu actions, for TalkBack too.
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.menuPlayNext): () => unawaited(
          applyTrackAction(context, ref, entry.track, MenuAction.next),
        ),
        CustomSemanticsAction(label: l10n.menuAddToQueue): () => unawaited(
          applyTrackAction(context, ref, entry.track, MenuAction.last),
        ),
      },
      child: tile,
    );
    if (!flashed) return withActions;
    // FR-013.5: the row the button led to is lit for a moment.
    return Stack(
      children: [
        withActions,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.16),
            ),
          ),
        ),
      ],
    );
  }
}

String? _formatDuration(Duration? duration) {
  if (duration == null) return null;
  final seconds = duration.inSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
