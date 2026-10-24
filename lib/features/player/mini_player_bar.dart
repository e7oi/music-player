import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/features/player/now_playing.dart';
import 'package:tuneshell/features/player/player_page.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/source_labels.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/mini_player.dart';

/// The mini player wired to the playback state: shown while the queue has a
/// current track, above the navigation (FR-016).
///
/// @implements FR-016
class MiniPlayerBar extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (track, playing) = ref.watch(
      playerStateProvider.select((s) {
        final state = s.value;
        return (state?.currentTrack, state?.playing ?? false);
      }),
    );
    if (track == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final player = ref.read(playerControllerProvider);
    final now = NowPlaying.of(track, ref.watch(trackIndexProvider));
    final disks = ref.watch(playerDisksProvider);
    final disk = disks.where((d) => d.id == track.disk).firstOrNull;
    final name = sourceName(disk, l10n);
    final cause = ref.watch(stopCauseProvider);
    final lost = cause is PlaybackStoppedByEjection && !playing;
    final lostName = lost
        ? sourceName(
                disks.where((d) => d.id == cause.disk).firstOrNull,
                l10n,
              ) ??
              cause.disk.value
        : null;
    final artist = now.artist ?? l10n.trackUnknownArtist;
    final artworkId = now.artwork;
    return MiniPlayer(
      title: now.title,
      subtitle: lostName == null ? artist : l10n.playerStoppedLost(lostName),
      mark: sourceMarkOf(
        disk,
        TsColors.of(context),
        size: TsSize.sourceMarkMini,
      ),
      artwork: artworkId == null
          ? null
          : ref.watch(artworkImageProvider(artworkId)),
      playing: playing,
      sourceLost: lost,
      progress: const _Progress(),
      openLabel: l10n.playerOpen,
      openSemanticsLabel: [
        now.title,
        artist,
        ?name == null ? null : l10n.trackSource(name),
      ].join(', '),
      previousLabel: l10n.playerPrevious,
      playLabel: l10n.playerPlay,
      pauseLabel: l10n.playerPause,
      nextLabel: l10n.playerNext,
      onOpen: () => unawaited(openPlayer(context, ref)),
      onPrevious: () => unawaited(player.previous()),
      onPlayPause: () => unawaited(playing ? player.pause() : player.play()),
      onNext: () => unawaited(player.next()),
    );
  }
}

/// Its own consumer: the position moves every few hundred milliseconds, the
/// rest of the mini player does not.
class _Progress extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(
      playerStateProvider.select((s) => s.value?.duration),
    );
    final total = duration?.inMilliseconds ?? 0;
    return MiniPlayerProgress(
      value: total <= 0 ? 0 : position.inMilliseconds / total,
    );
  }
}
