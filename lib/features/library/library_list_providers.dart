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
/// illisible" (FR-011.6, BR-008 rule 7).
class UnreadableTracks extends Notifier<Set<Track>> {
  @override
  Set<Track> build() {
    ref.listen(playbackNoticesProvider, (_, next) {
      final notice = next.value;
      if (notice is TrackFailed) state = {...state, notice.track};
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
  String? build() => null;

  // ignore: use_setters_to_change_properties, the notifier API is a method
  void dismiss(String fingerprint) => state = fingerprint;
}

final dismissedBannerProvider = NotifierProvider<DismissedBanner, String?>(
  DismissedBanner.new,
);

/// What the list shows; null until the tracks are first read.
final libraryListModelProvider = Provider<LibraryListModel?>((ref) {
  final tracks = ref.watch(listedTracksProvider).value;
  if (tracks == null) return null;
  return LibraryListModel.build(
    tracks: tracks,
    disks: ref.watch(libraryDisksProvider).value ?? const [],
    unavailable: ref.watch(unavailableDisksProvider),
    unreadable: ref.watch(unreadableTracksProvider),
    current: ref.watch(
      playerStateProvider.select((s) => s.value?.currentTrack),
    ),
    lastPlayed: ref.watch(lastPlayedProvider),
    dismissedBanner: ref.watch(dismissedBannerProvider),
  );
});
