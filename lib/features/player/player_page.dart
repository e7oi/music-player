import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/now_playing.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/queue_sheet.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/artwork_tile.dart';
import 'package:tuneshell/ui/widgets/mini_player.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/toggle_icon_button.dart';

/// Step of the position slider for the keyboard and TalkBack (FR-017.6).
const _seekStep = Duration(seconds: 5);

/// Opens the full-screen player over the application (FR-017.1). The cover
/// travels from the mini player to the large size.
Future<void> openPlayer(BuildContext context, WidgetRef ref) async {
  if (ref.read(playerOpenProvider)) return;
  // Kept before the push: the caller may be unmounted while the player is
  // open, and the flag must come back down all the same.
  final open = ref.read(playerOpenProvider.notifier)..set(open: true);
  ref.read(playerFailureProvider.notifier).clear();
  final still = MediaQuery.disableAnimationsOf(context);
  final navigator = Navigator.of(context);
  await navigator.push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => const PlayerPage(),
      transitionDuration: still ? Duration.zero : TsMotion.long,
      reverseTransitionDuration: still ? Duration.zero : TsMotion.medium,
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: TsMotion.standard),
        child: child,
      ),
    ),
  );
  open.set(open: false);
}

/// The full-screen player (FR-017).
///
/// @implements FR-017
class PlayerPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(
      playerStateProvider.select((s) => s.value?.currentTrack),
    );
    // FR-017.1: with nothing to show, the player closes.
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > TsSize.closeFlingVelocity) {
              Navigator.of(context).maybePop();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              return landscape
                  ? _Landscape(track: track, constraints: constraints)
                  : _Portrait(track: track, constraints: constraints);
            },
          ),
        ),
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const new({required this.track, required this.constraints});

  final Track track;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final cover = math.min(
      TsSize.coverPlayer,
      constraints.maxWidth - 2 * TsSpace.screenMargin,
    );
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            const _Header(),
            _Cover(track: track, size: cover),
            const _Banners(),
            _Info(track: track),
            const _Controls(),
            const _UpNextButton(),
          ],
        ),
      ),
    );
  }
}

/// FR-017.11: the cover on one side, information and controls on the other.
class _Landscape extends StatelessWidget {
  const new({required this.track, required this.constraints});

  final Track track;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final cover = math.min(
      TsSize.coverPlayer,
      constraints.maxHeight - 2 * TsSpace.screenMargin,
    );
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(TsSpace.screenMargin),
          child: Align(
            child: _Cover(track: track, size: cover),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const _Header(),
                const _Banners(),
                _Info(track: track),
                const _Controls(),
                const _UpNextButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final origin = ref.watch(queueOriginProvider);
    final originText = switch (origin) {
      TracksByTitle() => '${l10n.navTracks} · ${l10n.librarySortTitle}',
      AlbumOrigin(:final title) => l10n.queueOriginAlbum(
        title.isEmpty ? l10n.albumUnknown : title,
      ),
      ArtistOrigin(:final name) => l10n.queueOriginArtist(
        name.isEmpty ? l10n.trackUnknownArtist : name,
      ),
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TsSpace.xs),
      child: Row(
        children: [
          SizedBox.square(
            dimension: TsSize.touchTarget,
            child: IconButton(
              tooltip: l10n.playerCollapse,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.playerPlayingFrom.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (originText != null)
                  Text(
                    originText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
              ],
            ),
          ),
          const SizedBox.square(dimension: TsSize.touchTarget),
        ],
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const new({required this.track, required this.size});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = NowPlaying.of(track, ref.watch(trackIndexProvider));
    final lost = ref.watch(stopCauseProvider) is PlaybackStoppedByEjection;
    final playing = ref.watch(
      playerStateProvider.select((s) => s.value?.playing ?? false),
    );
    final id = now.artwork;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TsSpace.s),
      child: Hero(
        tag: playerCoverHeroTag,
        child: ArtworkTile(
          size: size,
          image: id == null ? null : ref.watch(artworkImageProvider(id)),
          fade: lost && !playing ? 0.5 : 1,
        ),
      ),
    );
  }
}

/// FR-017.9 and FR-017.10: what went wrong, in the flow under the cover.
class _Banners extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final failed = ref.watch(playerFailureProvider);
    final cause = ref.watch(stopCauseProvider);
    final index = ref.watch(trackIndexProvider);
    final disks = ref.watch(playerDisksProvider);
    return Column(
      children: [
        if (failed != null)
          StatusBanner(
            kind: BannerKind.error,
            message: l10n.noticeTrackFailed(NowPlaying.of(failed, index).title),
            dismissTooltip: l10n.bannerDismiss,
            onDismiss: ref.read(playerFailureProvider.notifier).clear,
          ),
        switch (cause) {
          PlaybackStoppedByEjection(:final disk) => StatusBanner(
            kind: BannerKind.warning,
            icon: Icons.usb_off_rounded,
            message: l10n.playerStoppedBanner(
              sourceName(disks.where((d) => d.id == disk).firstOrNull, l10n) ??
                  disk.value,
            ),
          ),
          PlaybackStoppedAfterFailures(:final consecutiveFailures) =>
            StatusBanner(
              kind: BannerKind.warning,
              message: l10n.noticeStoppedAfterFailures(consecutiveFailures),
            ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _Info extends ConsumerWidget {
  const new({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = NowPlaying.of(track, ref.watch(trackIndexProvider));
    final disk = ref
        .watch(playerDisksProvider)
        .where((d) => d.id == track.disk)
        .firstOrNull;
    final name = sourceName(disk, l10n);
    final mark = sourceMarkOf(disk, TsColors.of(context));
    final details = now.details;
    final line = [
      ?name,
      if (details.disc != null) l10n.playerDiscNumber(details.disc!),
      if (details.number != null) l10n.playerTrackNumber(details.number!),
      ?details.year?.toString(),
      ?details.genre,
      ?details.format,
      ?details.folder,
    ].join(' · ');
    final artistAlbum = [
      now.artist ?? l10n.trackUnknownArtist,
      ?now.album,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(
        left: TsSpace.screenMargin,
        top: TsSpace.s,
        right: TsSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  now.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TsText.playerTitle.copyWith(color: scheme.onSurface),
                ),
                Text(
                  artistAlbum,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: TsSpace.xs),
                    child: Row(
                      children: [
                        if (mark != null) ...[
                          mark,
                          const SizedBox(width: TsSpace.s),
                        ],
                        Expanded(
                          child: Text(
                            line,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: TsSize.touchTarget,
            child: IconButton(
              tooltip: l10n.playerFavoriteSoon,
              icon: const Icon(Icons.favorite_border_rounded),
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_Controls> createState() => _ControlsState();
}

class _ControlsState extends ConsumerState<_Controls> {
  /// The position under the thumb while it is dragged; the seek is sent when
  /// it is released (FR-017.6).
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final player = ref.read(playerControllerProvider);
    final state = ref.watch(
      playerStateProvider.select(
        (s) => (
          s.value?.playing ?? false,
          s.value?.shuffle ?? false,
          s.value?.repeat ?? RepeatMode.off,
          s.value?.duration,
          s.value?.status ?? PlayerStatus.idle,
        ),
      ),
    );
    final (playing, shuffle, repeat, duration, status) = state;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final total = duration?.inMilliseconds ?? 0;
    final known = total > 0 && status == PlayerStatus.ready;
    final shown = _dragging ?? position.inMilliseconds.toDouble();
    final clamped = shown.clamp(0, math.max(total, 1)).toDouble();
    final shownTime = Duration(milliseconds: clamped.round());
    final totalText = duration == null ? '' : formatClock(duration);
    final repeatState = switch (repeat) {
      RepeatMode.off => l10n.playerModeOff,
      RepeatMode.all => l10n.playerRepeatAll,
      RepeatMode.one => l10n.playerRepeatOne,
    };

    void seekBy(Duration delta) {
      final target = position + delta;
      final max = duration ?? Duration.zero;
      unawaited(
        player.seek(
          target < Duration.zero
              ? Duration.zero
              : (target > max ? max : target),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.s),
          child: Semantics(
            slider: true,
            label: l10n.playerSeek,
            value: l10n.playerPositionValue(formatClock(shownTime), totalText),
            increasedValue: known
                ? l10n.playerPositionValue(
                    formatClock(shownTime + _seekStep),
                    totalText,
                  )
                : null,
            decreasedValue: known
                ? l10n.playerPositionValue(
                    formatClock(shownTime - _seekStep),
                    totalText,
                  )
                : null,
            onIncrease: known ? () => seekBy(_seekStep) : null,
            onDecrease: known ? () => seekBy(-_seekStep) : null,
            child: ExcludeSemantics(
              child: Slider(
                value: clamped,
                max: math.max(total, 1).toDouble(),
                onChanged: known ? (v) => setState(() => _dragging = v) : null,
                onChangeEnd: known
                    ? (v) {
                        setState(() => _dragging = null);
                        unawaited(
                          player.seek(Duration(milliseconds: v.round())),
                        );
                      }
                    : null,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatClock(shownTime),
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                totalText,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TsSpace.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ToggleIconButton(
                icon: Icons.shuffle_rounded,
                selected: shuffle,
                label: l10n.playerShuffle,
                stateLabel: shuffle ? l10n.playerModeOn : l10n.playerModeOff,
                onPressed: () =>
                    unawaited(player.setShuffle(enabled: !shuffle)),
              ),
              SizedBox.square(
                dimension: TsSize.touchTarget,
                child: IconButton(
                  tooltip: l10n.playerPrevious,
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: TsSize.transportIcon,
                  onPressed: () => unawaited(player.previous()),
                ),
              ),
              SizedBox.square(
                dimension: TsSize.playButton,
                child: IconButton.filled(
                  tooltip: playing ? l10n.playerPause : l10n.playerPlay,
                  iconSize: TsSize.transportIcon,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TsRadius.xl),
                    ),
                  ),
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: () =>
                      unawaited(playing ? player.pause() : player.play()),
                ),
              ),
              SizedBox.square(
                dimension: TsSize.touchTarget,
                child: IconButton(
                  tooltip: l10n.playerNext,
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: TsSize.transportIcon,
                  onPressed: () => unawaited(player.next()),
                ),
              ),
              ToggleIconButton(
                icon: repeat == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                selected: repeat != RepeatMode.off,
                label: l10n.playerRepeat,
                stateLabel: repeatState,
                onPressed: () => unawaited(
                  player.setRepeat(switch (repeat) {
                    RepeatMode.off => RepeatMode.all,
                    RepeatMode.all => RepeatMode.one,
                    RepeatMode.one => RepeatMode.off,
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpNextButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final (queue, current) = ref.watch(
      playerStateProvider.select(
        (s) => (s.value?.queue ?? const <Track>[], s.value?.currentIndex),
      ),
    );
    final count = current == null ? 0 : queue.length - current - 1;
    final next = count > 0 ? queue[current! + 1] : null;
    final nextNow = next == null
        ? null
        : NowPlaying.of(next, ref.watch(trackIndexProvider));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TsSpace.screenMargin,
        TsSpace.xs,
        TsSpace.screenMargin,
        TsSpace.l,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(TsSize.buttonLarge),
            alignment: AlignmentDirectional.centerStart,
            shape: const RoundedRectangleBorder(borderRadius: TsRadius.card),
          ),
          onPressed: () => unawaited(showQueueSheet(context)),
          child: Row(
            children: [
              const Icon(Icons.queue_music_rounded),
              const SizedBox(width: TsSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.playerUpNext(count), style: text.labelLarge),
                    if (nextNow != null)
                      Text(
                        [nextNow.title, ?nextNow.artist].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_up_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
