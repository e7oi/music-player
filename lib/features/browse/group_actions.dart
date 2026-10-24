import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// Makes [tracks] the queue, in the order given, and plays from [startIndex]
/// (FR-022). [shuffle] turns the shuffle on or off first; null leaves it as
/// it is. The queue then says where it came from ([origin]).
///
/// @implements FR-022
Future<void> playGroup(
  WidgetRef ref, {
  required List<LibraryTrack> tracks,
  required QueueOrigin origin,
  int? startIndex,
  bool? shuffle,
}) async {
  final player = ref.read(playerControllerProvider);
  // "Shuffle" starts on any track of the group, not always the first one.
  final start =
      startIndex ?? ((shuffle ?? false) ? Random().nextInt(tracks.length) : 0);
  if (shuffle != null) await player.setShuffle(enabled: shuffle);
  ref.read(queueOriginProvider.notifier).set(origin);
  await player.setQueue([for (final t in tracks) t.track], startIndex: start);
  await player.play();
}

/// Says what to do about a track that cannot play now, and starts nothing
/// (BR-008, rule 5).
void explainUnavailable(BuildContext context, WidgetRef ref, DiskId disk) {
  final l10n = AppLocalizations.of(context);
  final name = ref.read(disksByIdProvider)[disk]?.label ?? disk.value;
  final issue = ref.read(unavailableDisksProvider)[disk];
  final text = issue == DiskIssue.accessLost
      ? l10n.trackNeedsAccess(name)
      : l10n.trackNeedsDisk(name);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Plays [tracks] from [startIndex], or explains when that track cannot play
/// (FR-022.4): a group with nothing available starts nothing.
void playOrExplain(
  BuildContext context,
  WidgetRef ref, {
  required List<LibraryTrack> tracks,
  required QueueOrigin origin,
  int? startIndex,
  bool? shuffle,
}) {
  final unavailable = ref.read(unavailableDiskIdsProvider);
  final playable = tracks.any((t) => !unavailable.contains(t.disk));
  if (!playable) {
    explainUnavailable(context, ref, tracks[startIndex ?? 0].disk);
    return;
  }
  unawaited(
    playGroup(
      ref,
      tracks: tracks,
      origin: origin,
      startIndex: startIndex,
      shuffle: shuffle,
    ),
  );
}
