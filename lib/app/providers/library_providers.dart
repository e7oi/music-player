import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/data/db/drift_library_repository.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
import 'package:tuneshell/domain/library/services/library_indexer.dart';
import 'package:tuneshell/platform/media_store_channel.dart';

final libraryDatabaseProvider = Provider<LibraryDatabase>((ref) {
  final db = LibraryDatabase();
  ref.onDispose(db.close);
  return db;
});

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => DriftLibraryRepository(ref.watch(libraryDatabaseProvider)),
);

final mediaStoreProvider = Provider<MediaStoreChannel>(
  (ref) => MediaStoreChannel(),
);

final internalAudioSourceProvider = Provider<InternalAudioSource>(
  (ref) => ref.watch(mediaStoreProvider),
);

final audioPermissionProvider = Provider<AudioPermission>(
  (ref) => ref.watch(mediaStoreProvider),
);

final libraryIndexerProvider = Provider<LibraryIndexer>(
  (ref) => LibraryIndexer(
    repository: ref.watch(libraryRepositoryProvider),
    source: ref.watch(internalAudioSourceProvider),
  ),
);

final libraryTracksProvider = StreamProvider<List<LibraryTrack>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchTracks(),
);

/// The library tracks by identity, for the system media session (FR-005).
final libraryTrackIndexProvider = Provider<Map<Track, LibraryTrack>>((ref) {
  final tracks =
      ref.watch(libraryTracksProvider).value ?? const <LibraryTrack>[];
  return {for (final t in tracks) t.track: t};
});
