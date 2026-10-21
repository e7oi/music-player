import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'library_database.g.dart';

/// Schema of ADR-004. Every change bumps [LibraryDatabase.schemaVersion],
/// adds a dump with `dart run drift_dev make-migrations` and a migration
/// test (CLAUDE.md, Tests).
@DataClassName('DiskRow')
class Disks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identifier (BR-004): fixed for the internal storage, filesystem
  /// UUID for a removable disk.
  TextColumn get key => text().unique()();

  TextColumn get label => text()();

  /// `DiskKind.index`.
  IntColumn get kind => integer()();
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

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {diskId, relativePath},
  ];
}

@DriftDatabase(tables: [Disks, DiskFolders, Tracks])
class LibraryDatabase extends _$LibraryDatabase {
  new([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Opened in a background isolate (ADR-004), in the app's private
  /// directory.
  static QueryExecutor _open() => driftDatabase(name: 'library');
}
