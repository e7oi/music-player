import 'package:drift/drift.dart';
import 'package:musicplayer/data/db/library_database.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/library/ports/library_repository.dart';

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
        await (_db.update(_db.tracks)..where((t) => t.id.equals(row.id))).write(
          _companion(diskRow.id, info, now),
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

  static LibraryTrack _toTrack(TrackRow row, DiskId disk) =>
      LibraryTrack(id: row.id, disk: disk, info: _toInfo(row));
}
