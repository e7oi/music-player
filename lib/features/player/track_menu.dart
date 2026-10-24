import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// What the menu of a track can do (FR-019.1).
enum MenuAction { next, last }

/// The menu of a track in the list: play it next, or add it to the end of the
/// queue (FR-019).
///
/// @implements FR-019
Future<void> showTrackMenu(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showModalBottomSheet<MenuAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_play_rounded),
            title: Text(l10n.menuPlayNext),
            onTap: () => Navigator.of(context).pop(MenuAction.next),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(l10n.menuAddToQueue),
            onTap: () => Navigator.of(context).pop(MenuAction.last),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  await applyTrackAction(context, ref, track, choice);
}

/// Does [action] and confirms it in a snack bar. Also the target of the
/// custom actions TalkBack offers on a row (FR-019.1).
Future<void> applyTrackAction(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
  MenuAction action,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final player = ref.read(playerControllerProvider);
  final title = track.displayTitle;
  // On an empty queue the track starts a queue of its own: no origin to name.
  if (player.state.queue.isEmpty) {
    ref.read(queueOriginProvider.notifier).clear();
  }
  switch (action) {
    case MenuAction.next:
      unawaited(player.playNext([track.track]));
    case MenuAction.last:
      unawaited(player.enqueue([track.track]));
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          action == MenuAction.next
              ? l10n.menuPlayNextDone(title)
              : l10n.menuAddedDone(title),
        ),
      ),
    );
}
