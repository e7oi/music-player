import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/throttle.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/features/library/removable_controller.dart';

/// The registered disks, with their source marks (FR-012).
final libraryDisksProvider = StreamProvider<List<Disk>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchDisks(),
);

/// The stored tracks, handed over at most twice a second: the database emits
/// by batch while tags are read, and the list is long (FR-011.11).
final listedTracksProvider = StreamProvider<List<LibraryTrack>>(
  (ref) => throttleLatest(
    ref.watch(libraryRepositoryProvider).watchTracks(),
    const Duration(milliseconds: 500),
  ),
);

/// Disks whose tracks cannot be played now: not mounted, or access lost
/// (BR-008, rule 1). Empty until the removable disks have been read.
final unavailableDisksProvider = Provider<Map<DiskId, DiskIssue>>((ref) {
  final disks = ref.watch(removableControllerProvider.select((s) => s.disks));
  return {
    for (final disk in disks)
      if (disk.status == RemovableStatus.absent)
        disk.disk.id: DiskIssue.absent
      else if (disk.status == RemovableStatus.accessLost)
        disk.disk.id: DiskIssue.accessLost,
  };
});

/// The last track the player had, for the "last played" button when nothing
/// plays. Kept for the session only (FR-013.4).
class LastPlayedTrack extends Notifier<Track?> {
  @override
  Track? build() {
    ref.listen(playerStateProvider.select((s) => s.value?.currentTrack), (
      _,
      track,
    ) {
      if (track != null) state = track;
    });
    return ref.read(playerStateProvider).value?.currentTrack;
  }
}

final lastPlayedProvider = NotifierProvider<LastPlayedTrack, Track?>(
  LastPlayedTrack.new,
);

/// Tracks the engine failed on in this session: their row says "Fichier
/// illisible" (FR-011.6, BR-008 rule 7). A change in the state of the disks
/// clears them: a failure while a disk was leaving or coming back says nothing
/// about the file.
class UnreadableTracks extends Notifier<Set<Track>> {
  @override
  Set<Track> build() {
    ref.listen(playbackNoticesProvider, (_, next) {
      final notice = next.value;
      if (notice is TrackFailed) state = {...state, notice.track};
    });
    ref.listen(unavailableDisksProvider, (previous, next) {
      if (!mapEquals(previous, next)) state = const {};
    });
    return const {};
  }
}

final unreadableTracksProvider = NotifierProvider<UnreadableTracks, Set<Track>>(
  UnreadableTracks.new,
);

/// Fingerprint of the sources banner the user closed (BR-008, rule 3).
class DismissedBanner extends Notifier<String?> {
  @override
  String? build() {
    // A disk that leaves, comes back or changes state ends the dismissal, even
    // if the state later returns to the one that was closed.
    ref.listen(unavailableDisksProvider, (previous, next) {
      if (!mapEquals(previous, next)) state = null;
    });
    return null;
  }

  // ignore: use_setters_to_change_properties, the notifier API is a method
  void dismiss(String fingerprint) => state = fingerprint;
}

final dismissedBannerProvider = NotifierProvider<DismissedBanner, String?>(
  DismissedBanner.new,
);

/// The tracks in display order. Apart from the model so that a change of
/// track or of source state does not sort the whole library again.
final sortedTracksProvider = Provider<List<LibraryTrack>?>((ref) {
  final tracks = ref.watch(listedTracksProvider).value;
  return tracks == null ? null : LibraryListModel.sortTracks(tracks);
});

/// What the list shows; null until the tracks and the disks are first read.
final libraryListModelProvider = Provider<LibraryListModel?>((ref) {
  final tracks = ref.watch(sortedTracksProvider);
  final disks = ref.watch(libraryDisksProvider).value;
  if (tracks == null || disks == null) return null;
  return LibraryListModel.build(
    tracks: tracks,
    presorted: true,
    disks: disks,
    unavailable: ref.watch(unavailableDisksProvider),
    unreadable: ref.watch(unreadableTracksProvider),
    current: ref.watch(
      playerStateProvider.select((s) => s.value?.currentTrack),
    ),
    lastPlayed: ref.watch(lastPlayedProvider),
    dismissedBanner: ref.watch(dismissedBannerProvider),
  );
});
