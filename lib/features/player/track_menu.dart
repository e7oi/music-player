import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

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
  final messenger = ScaffoldMessenger.of(context);
  final player = ref.read(playerControllerProvider);
  final choice = await showModalBottomSheet<_Choice>(
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
            onTap: () => Navigator.of(context).pop(_Choice.next),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(l10n.menuAddToQueue),
            onTap: () => Navigator.of(context).pop(_Choice.last),
          ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  final title = track.displayTitle;
  switch (choice) {
    case _Choice.next:
      unawaited(player.playNext([track.track]));
    case _Choice.last:
      unawaited(player.enqueue([track.track]));
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          choice == _Choice.next
              ? l10n.menuPlayNextDone(title)
              : l10n.menuAddedDone(title),
        ),
      ),
    );
}

enum _Choice { next, last }
