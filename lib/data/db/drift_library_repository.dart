import 'package:drift/drift.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';

/// [LibraryRepository] over Drift (ADR-004).
class DriftLibraryRepository implements LibraryRepository {
  new(this._db);

  final LibraryDatabase _db;

  @override
  Future<Disk?> disk(DiskId id) async {
    final row = await _diskRow(id);
    return row == null ? null : _toDisk(row);
  }

  @override
  Future<void> ensureDisk(Disk disk) => _db
      .into(_db.disks)
      .insert(
        DisksCompanion.insert(
          key: disk.id.value,
          label: disk.label,
          kind: disk.kind.index,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  Future<Set<String>> chosenFolders(DiskId disk) async {
    final row = await _diskRow(disk);
    if (row == null) return {};
    final folders = await (_db.select(
      _db.diskFolders,
    )..where((f) => f.diskId.equals(row.id))).get();
    return {for (final f in folders) f.relativePath};
  }

  @override
  Future<void> setChosenFolders(Disk disk, Set<String> folders) =>
      _db.transaction(() async {
        await ensureDisk(disk);
        // The name Android gives a volume can change (FR-006.4).
        await (_db.update(_db.disks)..where((d) => d.key.equals(disk.id.value)))
            .write(DisksCompanion(label: Value(disk.label)));
        final row = await _requireDisk(disk.id);
        await (_db.delete(
          _db.diskFolders,
        )..where((f) => f.diskId.equals(row.id))).go();
        await _db.batch(
          (batch) => batch.insertAll(_db.diskFolders, [
            for (final folder in folders)
              DiskFoldersCompanion.insert(diskId: row.id, relativePath: folder),
          ]),
        );
      });

  @override
  Stream<List<LibraryTrack>> watchTracks() {
    final query = _db.select(_db.tracks).join([
      innerJoin(_db.disks, _db.disks.id.equalsExp(_db.tracks.diskId)),
    ]);
    return query.watch().map((rows) {
      final tracks = [
        for (final row in rows)
          _toTrack(
            row.readTable(_db.tracks),
            DiskId(row.readTable(_db.disks).key),
          ),
      ];
      // Sorted in Dart: the display title falls back to the file name.
      return tracks..sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        ),
      );
    });
  }

  /// @implements BR-004: a path still present keeps its row, hence its id.
  @override
  Future<IndexResult> applyIndex(
    DiskId disk,
    List<TrackInfo> found,
  ) => _db.transaction(() async {
    final diskRow = await _requireDisk(disk);
    final existing = {
      for (final row in await (_db.select(
        _db.tracks,
      )..where((t) => t.diskId.equals(diskRow.id))).get())
        row.relativePath: row,
    };
    final now = DateTime.now();
    var added = 0;
    var updated = 0;
    final seen = <String>{};
    for (final info in found) {
      if (!seen.add(info.relativePath)) continue;
      final row = existing[info.relativePath];
      if (row == null) {
        await _db.into(_db.tracks).insert(_companion(diskRow.id, info, now));
        added++;
      } else if (_toInfo(row) != info) {
        // The file itself changed: its artwork is read again (FR-007.8).
        final changed =
            row.size != info.size || row.modifiedAt != info.modifiedAt;
        await (_db.update(_db.tracks)..where((t) => t.id.equals(row.id))).write(
          _companion(diskRow.id, info, now).copyWith(
            tagsState: changed
                ? Value(TagsState.pending.index)
                : const Value.absent(),
          ),
        );
        updated++;
      }
    }
    final gone = [
      for (final row in existing.values)
        if (!seen.contains(row.relativePath)) row.id,
    ];
    if (gone.isNotEmpty) {
      await (_db.delete(_db.tracks)..where((t) => t.id.isIn(gone))).go();
    }
    return IndexResult(added: added, updated: updated, removed: gone.length);
  });

  Future<DiskRow?> _diskRow(DiskId id) => (_db.select(
    _db.disks,
  )..where((d) => d.key.equals(id.value))).getSingleOrNull();

  Future<DiskRow> _requireDisk(DiskId id) async {
    final row = await _diskRow(id);
    if (row == null) throw StateError('Disk not registered: ${id.value}');
    return row;
  }

  static Disk _toDisk(DiskRow row) => Disk(
    id: DiskId(row.key),
    label: row.label,
    kind: DiskKind.values[row.kind],
  );

  static TracksCompanion _companion(int diskId, TrackInfo info, DateTime now) =>
      TracksCompanion.insert(
        diskId: diskId,
        relativePath: info.relativePath,
        title: Value(info.title),
        artist: Value(info.artist),
        album: Value(info.album),
        albumArtist: Value(info.albumArtist),
        trackNumber: Value(info.trackNumber),
        discNumber: Value(info.discNumber),
        year: Value(info.year),
        genre: Value(info.genre),
        durationMs: Value(info.duration?.inMilliseconds),
        size: info.size,
        modifiedAt: info.modifiedAt,
        indexedAt: now,
      );

  static TrackInfo _toInfo(TrackRow row) => TrackInfo(
    relativePath: row.relativePath,
    size: row.size,
    modifiedAt: row.modifiedAt,
    title: row.title,
    artist: row.artist,
    album: row.album,
    albumArtist: row.albumArtist,
    trackNumber: row.trackNumber,
    discNumber: row.discNumber,
    year: row.year,
    genre: row.genre,
    duration: row.durationMs == null
        ? null
        : Duration(milliseconds: row.durationMs!),
  );

  static LibraryTrack _toTrack(TrackRow row, DiskId disk) => LibraryTrack(
    id: row.id,
    disk: disk,
    info: _toInfo(row),
    artwork: row.artwork,
    tagsState: TagsState.values[row.tagsState],
  );

  @override
  Future<List<Disk>> disks() async => [
    for (final row in await _db.select(_db.disks).get()) _toDisk(row),
  ];

  /// @implements FR-006.8: tags and artwork are kept for an unchanged file,
  /// and for a changed one until it is read again.
  @override
  Future<IndexResult> applyScan(
    DiskId disk,
    List<TrackInfo> found,
  ) => _db.transaction(() async {
    final diskRow = await _requireDisk(disk);
    final existing = {
      for (final row in await (_db.select(
        _db.tracks,
      )..where((t) => t.diskId.equals(diskRow.id))).get())
        row.relativePath: row,
    };
    final now = DateTime.now();
    var added = 0;
    var updated = 0;
    final seen = <String>{};
    for (final info in found) {
      if (!seen.add(info.relativePath)) continue;
      final row = existing[info.relativePath];
      if (row == null) {
        await _db.into(_db.tracks).insert(_companion(diskRow.id, info, now));
        added++;
      } else if (row.size != info.size || row.modifiedAt != info.modifiedAt) {
        await (_db.update(_db.tracks)..where((t) => t.id.equals(row.id))).write(
          TracksCompanion(
            size: Value(info.size),
            modifiedAt: Value(info.modifiedAt),
            indexedAt: Value(now),
            tagsState: Value(TagsState.pending.index),
          ),
        );
        updated++;
      }
    }
    final gone = [
      for (final row in existing.values)
        if (!seen.contains(row.relativePath)) row.id,
    ];
    if (gone.isNotEmpty) {
      await (_db.delete(_db.tracks)..where((t) => t.id.isIn(gone))).go();
    }
    return IndexResult(added: added, updated: updated, removed: gone.length);
  });

  @override
  Future<List<PendingTrack>> pendingTracks(Set<DiskId> disks, int limit) async {
    final query =
        _db.select(_db.tracks).join([
            innerJoin(_db.disks, _db.disks.id.equalsExp(_db.tracks.diskId)),
          ])
          ..where(
            _db.tracks.tagsState.equals(TagsState.pending.index) &
                _db.disks.key.isIn([for (final d in disks) d.value]),
          )
          ..orderBy([OrderingTerm.asc(_db.tracks.id)])
          ..limit(limit);
    return [
      for (final row in await query.get())
        PendingTrack(
          id: row.readTable(_db.tracks).id,
          track: Track(
            disk: DiskId(row.readTable(_db.disks).key),
            relativePath: row.readTable(_db.tracks).relativePath,
          ),
        ),
    ];
  }

  @override
  Future<int> countPending(Set<DiskId> disks) async {
    final count = _db.tracks.id.count();
    final query =
        _db.selectOnly(_db.tracks).join([
            innerJoin(_db.disks, _db.disks.id.equalsExp(_db.tracks.diskId)),
          ])
          ..addColumns([count])
          ..where(
            _db.tracks.tagsState.equals(TagsState.pending.index) &
                _db.disks.key.isIn([for (final d in disks) d.value]),
          );
    final row = await query.getSingle();
    final pending = row.read(count);
    return pending ?? 0;
  }

  @override
  Future<void> resetFailedTags(Set<DiskId> disks) async {
    final ids = _db.selectOnly(_db.disks)
      ..addColumns([_db.disks.id])
      ..where(_db.disks.key.isIn([for (final d in disks) d.value]));
    await (_db.update(_db.tracks)..where(
          (t) =>
              t.tagsState.equals(TagsState.failed.index) &
              t.diskId.isInQuery(ids),
        ))
        .write(TracksCompanion(tagsState: Value(TagsState.pending.index)));
  }

  @override
  Future<int> trackCount(DiskId disk) async {
    final count = _db.tracks.id.count();
    final query =
        _db.selectOnly(_db.tracks).join([
            innerJoin(_db.disks, _db.disks.id.equalsExp(_db.tracks.diskId)),
          ])
          ..addColumns([count])
          ..where(_db.disks.key.equals(disk.value));
    final row = await query.getSingle();
    final total = row.read(count);
    return total ?? 0;
  }

  @override
  Future<void> applyFileTags(
    List<TagUpdate> updates,
  ) => _db.transaction(() async {
    for (final update in updates) {
      final tags = update.tags;
      final target = _db.update(_db.tracks)
        ..where((t) => t.id.equals(update.trackId));
      if (tags == null) {
        await target.write(
          TracksCompanion(tagsState: Value(TagsState.failed.index)),
        );
        continue;
      }
      await target.write(
        TracksCompanion(
          tagsState: Value(TagsState.done.index),
          artwork: Value(tags.artwork),
          // Written only for a removable disk: MediaStore keeps the
          // tags of the internal storage (FR-007.2).
          title: update.writeTags ? Value(tags.title) : const Value.absent(),
          artist: update.writeTags ? Value(tags.artist) : const Value.absent(),
          album: update.writeTags ? Value(tags.album) : const Value.absent(),
          albumArtist: update.writeTags
              ? Value(tags.albumArtist)
              : const Value.absent(),
          trackNumber: update.writeTags
              ? Value(tags.trackNumber)
              : const Value.absent(),
          discNumber: update.writeTags
              ? Value(tags.discNumber)
              : const Value.absent(),
          year: update.writeTags ? Value(tags.year) : const Value.absent(),
          genre: update.writeTags ? Value(tags.genre) : const Value.absent(),
          durationMs: update.writeTags
              ? Value(tags.duration?.inMilliseconds)
              : const Value.absent(),
        ),
      );
    }
  });

  @override
  Future<Set<String>> artworkInUse() async {
    final column = _db.tracks.artwork;
    final query = _db.selectOnly(_db.tracks, distinct: true)
      ..addColumns([column])
      ..where(column.isNotNull());
    return {for (final row in await query.get()) row.read(column)!};
  }
}
