// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/data/db/library_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = LibraryDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  /// ADR-008: tracks of a v1 library survive, pending, without artwork.
  test(
    'migration from v1 to v2 keeps the tracks and marks them pending',
    () async {
      final oldDisksData = [
        const v1.DisksData(id: 1, key: 'internal', label: 'Local', kind: 0),
      ];
      final expectedNewDisksData = [
        const v2.DisksData(id: 1, key: 'internal', label: 'Local', kind: 0),
      ];
      final oldDiskFoldersData = [
        const v1.DiskFoldersData(diskId: 1, relativePath: 'Music'),
      ];
      final expectedNewDiskFoldersData = [
        const v2.DiskFoldersData(diskId: 1, relativePath: 'Music'),
      ];
      final oldTracksData = [
        const v1.TracksData(
          id: 7,
          diskId: 1,
          relativePath: 'Music/a.mp3',
          title: 'A',
          size: 10,
          modifiedAt: 1000,
          indexedAt: 2000,
        ),
      ];
      final expectedNewTracksData = [
        const v2.TracksData(
          id: 7,
          diskId: 1,
          relativePath: 'Music/a.mp3',
          title: 'A',
          size: 10,
          modifiedAt: 1000,
          indexedAt: 2000,
          tagsState: 0,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: LibraryDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insertAll(oldDb.disks, oldDisksData)
            ..insertAll(oldDb.diskFolders, oldDiskFoldersData)
            ..insertAll(oldDb.tracks, oldTracksData);
        },
        validateItems: (newDb) async {
          expect(expectedNewDisksData, await newDb.select(newDb.disks).get());
          expect(
            expectedNewDiskFoldersData,
            await newDb.select(newDb.diskFolders).get(),
          );
          expect(expectedNewTracksData, await newDb.select(newDb.tracks).get());
        },
      );
    },
  );

  /// @verifies FR-012.3 removable disks get 0, 1, 2 by order of registration.
  test(
    'migration from v2 to v3 gives the removable disks their marks',
    () async {
      final oldDisksData = [
        const v2.DisksData(id: 1, key: 'internal', label: 'Local', kind: 0),
        const v2.DisksData(id: 2, key: 'AAAA-1111', label: 'SSD', kind: 1),
        const v2.DisksData(id: 5, key: 'BBBB-2222', label: 'Card', kind: 1),
      ];
      final expectedNewDisksData = [
        const v3.DisksData(id: 1, key: 'internal', label: 'Local', kind: 0),
        const v3.DisksData(
          id: 2,
          key: 'AAAA-1111',
          label: 'SSD',
          kind: 1,
          markIndex: 0,
        ),
        const v3.DisksData(
          id: 5,
          key: 'BBBB-2222',
          label: 'Card',
          kind: 1,
          markIndex: 1,
        ),
      ];
      final oldTracksData = [
        const v2.TracksData(
          id: 7,
          diskId: 2,
          relativePath: 'a.mp3',
          size: 10,
          modifiedAt: 1000,
          indexedAt: 2000,
          tagsState: 1,
        ),
      ];
      final expectedNewTracksData = [
        const v3.TracksData(
          id: 7,
          diskId: 2,
          relativePath: 'a.mp3',
          size: 10,
          modifiedAt: 1000,
          indexedAt: 2000,
          tagsState: 1,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: LibraryDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insertAll(oldDb.disks, oldDisksData)
            ..insertAll(oldDb.tracks, oldTracksData);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.disks).get(), expectedNewDisksData);
          expect(await newDb.select(newDb.tracks).get(), expectedNewTracksData);
        },
      );
    },
  );
}
