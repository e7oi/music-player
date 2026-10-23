import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:tuneshell/data/db/library_database.steps.dart';

part 'library_database.g.dart';

/// Schema of ADR-004, version 2 of ADR-008. Every change bumps
/// [LibraryDatabase.schemaVersion], adds a dump with
/// `dart run drift_dev make-migrations` and a migration test (CLAUDE.md,
/// Tests).
@DataClassName('DiskRow')
@TableIndex(name: 'disks_mark_index', columns: {#markIndex}, unique: true)
class Disks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identifier (BR-004): fixed for the internal storage, filesystem
  /// UUID for a removable disk.
  TextColumn get key => text().unique()();

  TextColumn get label => text()();

  /// `DiskKind.index`.
  IntColumn get kind => integer()();

  /// Source mark of a removable disk (ADR-012); null for the internal
  /// storage. Unique through an index: SQLite accepts several nulls.
  IntColumn get markIndex => integer().nullable()();
}

@DataClassName('DiskFolderRow')
class DiskFolders extends Table {
  IntColumn get diskId => integer().references(Disks, #id)();

  TextColumn get relativePath => text()();

  @override
  Set<Column<Object>> get primaryKey => {diskId, relativePath};
}

@DataClassName('TrackRow')
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get diskId => integer().references(Disks, #id)();

  TextColumn get relativePath => text()();

  TextColumn get title => text().nullable()();

  TextColumn get artist => text().nullable()();

  TextColumn get album => text().nullable()();

  TextColumn get albumArtist => text().nullable()();

  IntColumn get trackNumber => integer().nullable()();

  IntColumn get discNumber => integer().nullable()();

  IntColumn get year => integer().nullable()();

  TextColumn get genre => text().nullable()();

  IntColumn get durationMs => integer().nullable()();

  IntColumn get size => integer()();

  DateTimeColumn get modifiedAt => dateTime()();

  DateTimeColumn get indexedAt => dateTime()();

  /// Identifier of the artwork image of the file (ADR-009), null for none.
  TextColumn get artwork => text().nullable()();

  /// `TagsState.index` (FR-007.3): every track starts pending.
  IntColumn get tagsState => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {diskId, relativePath},
  ];
}

@DriftDatabase(tables: [Disks, DiskFolders, Tracks])
class LibraryDatabase extends _$LibraryDatabase {
  new([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        // Existing tracks are pending: their artwork is still to be read.
        await migrator.addColumn(schema.tracks, schema.tracks.artwork);
        await migrator.addColumn(schema.tracks, schema.tracks.tagsState);
      },
      from2To3: (migrator, schema) async {
        await migrator.addColumn(schema.disks, schema.disks.markIndex);
        // Removable disks (`DiskKind.removable` is 1) get 0, 1, 2 by order of
        // registration; the internal storage keeps none.
        await migrator.database.customStatement(
          'UPDATE disks SET mark_index = '
          '(SELECT COUNT(*) FROM disks AS earlier '
          'WHERE earlier.kind = 1 AND earlier.id < disks.id) '
          'WHERE kind = 1',
        );
        await migrator.createIndex(schema.disksMarkIndex);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Opened in a background isolate (ADR-004), in the app's private
  /// directory.
  static QueryExecutor _open() => driftDatabase(name: 'library');
}
