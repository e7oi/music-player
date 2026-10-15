import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/data/db/drift_library_repository.dart';
import 'package:musicplayer/data/db/library_database.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/domain/library/ports/library_repository.dart';
import 'package:musicplayer/domain/library/services/library_indexer.dart';
import 'package:musicplayer/platform/media_store_channel.dart';

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
