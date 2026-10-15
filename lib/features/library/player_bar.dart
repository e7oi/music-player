import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/app/providers/library_providers.dart';
import 'package:musicplayer/app/providers/player_providers.dart';
import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/l10n/generated/app_localizations.dart';

/// Temporary playback bar until the MPL-016 mock-ups exist (UC-001).
class PlayerBar extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(playerStateProvider).value;
    final current = state?.currentTrack;
    if (state == null || current == null) return const SizedBox.shrink();
    final tracks = ref.watch(libraryTracksProvider).value ?? const [];
    final title =
        tracks.where((t) => t.track == current).firstOrNull?.displayTitle ??
        current.relativePath;
    final player = ref.read(playerControllerProvider);
    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: l10n.playerPrevious,
                icon: const Icon(Icons.skip_previous),
                onPressed: () => unawaited(player.previous()),
              ),
              if (state.playing)
                IconButton(
                  tooltip: l10n.playerPause,
                  icon: const Icon(Icons.pause),
                  onPressed: () => unawaited(player.pause()),
                )
              else
                IconButton(
                  tooltip: l10n.playerPlay,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: state.status == PlayerStatus.idle
                      ? null
                      : () => unawaited(player.play()),
                ),
              IconButton(
                tooltip: l10n.playerNext,
                icon: const Icon(Icons.skip_next),
                onPressed: () => unawaited(player.next()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
