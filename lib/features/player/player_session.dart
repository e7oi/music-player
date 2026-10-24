import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';

/// The library by track identity for the player: the same map as the
/// notification's, but behind the throttled stream of the list (ADR-015), so
/// that tags read in batches do not rebuild it at each batch.
final trackIndexProvider = Provider<Map<Track, LibraryTrack>>((ref) {
  final tracks =
      ref.watch(listedTracksProvider).value ?? const <LibraryTrack>[];
  return {for (final t in tracks) t.track: t};
});

/// Where the queue was started from (FR-017.2, FR-022.6): the list of tracks,
/// an album or an artist.
@immutable
sealed class QueueOrigin {
  const new();

  static const tracksByTitle = TracksByTitle();
}

/// The Tracks list, sorted by title.
final class TracksByTitle extends QueueOrigin {
  const new();
}

/// An album; [title] is empty for the unknown album.
final class AlbumOrigin extends QueueOrigin {
  const new(this.title);

  final String title;

  @override
  bool operator ==(Object other) =>
      other is AlbumOrigin && other.title == title;

  @override
  int get hashCode => Object.hash(AlbumOrigin, title);
}

/// An artist; [name] is empty for the unknown artist.
final class ArtistOrigin extends QueueOrigin {
  const new(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is ArtistOrigin && other.name == name;

  @override
  int get hashCode => Object.hash(ArtistOrigin, name);
}

class QueueOriginNotifier extends Notifier<QueueOrigin?> {
  @override
  QueueOrigin? build() => null;

  // ignore: use_setters_to_change_properties, the notifier API is a method
  void set(QueueOrigin origin) => state = origin;

  void clear() => state = null;
}

final queueOriginProvider = NotifierProvider<QueueOriginNotifier, QueueOrigin?>(
  QueueOriginNotifier.new,
);

/// Why playback stopped on its own, until the user plays again: the mini
/// player and the player say it (FR-016.7, FR-017.10). The disk coming back
/// does not lift it (decided on 2026-10-15).
class StopCauseNotifier extends Notifier<PlaybackNotice?> {
  @override
  PlaybackNotice? build() {
    ref
      ..listen(playbackNoticesProvider, (_, next) {
        final notice = next.value;
        if (notice is PlaybackStoppedByEjection ||
            notice is PlaybackStoppedAfterFailures) {
          state = notice;
        }
      })
      ..listen(playerStateProvider.select((s) => s.value?.playing ?? false), (
        _,
        playing,
      ) {
        if (playing) state = null;
      });
    return null;
  }
}

final stopCauseProvider = NotifierProvider<StopCauseNotifier, PlaybackNotice?>(
  StopCauseNotifier.new,
);

/// The last track the engine failed on while the player was open; its banner
/// stays until it is closed (FR-017.9).
class PlayerFailureNotifier extends Notifier<Track?> {
  @override
  Track? build() {
    ref.listen(playbackNoticesProvider, (_, next) {
      final notice = next.value;
      if (notice is TrackFailed) state = notice.track;
    });
    return null;
  }

  void clear() => state = null;
}

final playerFailureProvider = NotifierProvider<PlayerFailureNotifier, Track?>(
  PlayerFailureNotifier.new,
);

/// Whether the full-screen player is open: it then shows the failure itself,
/// and the list does not repeat it in a snack bar (FR-017.9).
class PlayerOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties, the notifier API is a method
  void set({required bool open}) => state = open;
}

final playerOpenProvider = NotifierProvider<PlayerOpenNotifier, bool>(
  PlayerOpenNotifier.new,
);

/// The disks the player can name, for the ejection texts.
final playerDisksProvider = Provider<List<Disk>>(
  (ref) => ref.watch(libraryDisksProvider).value ?? const [],
);
