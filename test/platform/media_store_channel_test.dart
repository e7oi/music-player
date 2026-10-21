import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/domain/library/model/library_track.dart';
import 'package:musicplayer/domain/library/model/track.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';
import 'package:musicplayer/domain/storage/ports/track_source_opener.dart';
import 'package:musicplayer/platform/internal_storage.dart';
import 'package:musicplayer/platform/media_store_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MediaStoreChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  Object? reply;

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return reply;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('FR-003 MediaStore rows', () {
    Map<String, Object?> row({
      String? relativePath = 'Music/Album/',
      String? displayName = '01 Song.flac',
      Object? title = 'Song',
      Object? artist = 'Artist',
      Object? track = 2003,
      Object? year = 1999,
      Object? durationMs = 180500,
    }) => {
      'relativePath': relativePath,
      'displayName': displayName,
      'title': title,
      'artist': artist,
      'album': 'Album',
      'albumArtist': null,
      'track': track,
      'year': year,
      'genre': 'Genre',
      'durationMs': durationMs,
      'size': 4096,
      'dateModified': 1700000000,
    };

    /// @verifies FR-003
    test('maps every field', () {
      final info = MediaStoreChannel.fromRow(row())!;

      expect(info.relativePath, 'Music/Album/01 Song.flac');
      expect(info.title, 'Song');
      expect(info.artist, 'Artist');
      expect(info.album, 'Album');
      expect(info.albumArtist, isNull);
      expect(info.discNumber, 2);
      expect(info.trackNumber, 3);
      expect(info.year, 1999);
      expect(info.genre, 'Genre');
      expect(info.duration, const Duration(milliseconds: 180500));
      expect(info.size, 4096);
      expect(
        info.modifiedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    /// @verifies FR-003
    test('an unknown or empty tag is empty', () {
      final info = MediaStoreChannel.fromRow(
        row(
          artist: '<unknown>',
          title: '  ',
          year: 0,
          durationMs: 0,
          track: null,
        ),
      )!;

      expect(info.artist, isNull);
      expect(info.title, isNull);
      expect(info.year, isNull);
      expect(info.duration, isNull);
      expect(info.trackNumber, isNull);
      expect(info.discNumber, isNull);
    });

    test('a track number below 1000 has no disc', () {
      final info = MediaStoreChannel.fromRow(row(track: 7))!;

      expect(info.trackNumber, 7);
      expect(info.discNumber, isNull);
    });

    test('a file at the root has no folder', () {
      expect(
        MediaStoreChannel.fromRow(row(relativePath: '/'))!.relativePath,
        '01 Song.flac',
      );
    });

    test('a row without a path is skipped', () {
      expect(MediaStoreChannel.fromRow(row(relativePath: null)), isNull);
      expect(MediaStoreChannel.fromRow(row(displayName: '')), isNull);
    });

    test('queryAudio decodes the channel reply', () async {
      reply = [
        row(),
        {'relativePath': null},
      ];

      final result = await MediaStoreChannel().queryAudio();

      expect(calls, ['queryInternalAudio']);
      expect(result.map((i) => i.relativePath), ['Music/Album/01 Song.flac']);
    });
  });

  group('FR-004 permission', () {
    /// @verifies FR-004
    test('maps the native statuses', () async {
      final store = MediaStoreChannel();
      reply = 'granted';
      expect(await store.status(), AudioPermissionStatus.granted);
      reply = 'permanentlyDenied';
      expect(await store.request(), AudioPermissionStatus.permanentlyDenied);
      reply = 'denied';
      expect(await store.status(), AudioPermissionStatus.denied);

      expect(calls, [
        'audioPermissionStatus',
        'requestAudioPermission',
        'audioPermissionStatus',
      ]);
    });
  });

  group('internal storage', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('internal');
      await File('${root.path}/Music/a.mp3').create(recursive: true);
    });

    tearDown(() => root.delete(recursive: true));

    test('opens a track of the internal storage by path', () async {
      final opener = InternalTrackSourceOpener(() async => root.path);

      final source = await opener.open(
        const Track(disk: internalDisk, relativePath: 'Music/a.mp3'),
      );

      expect((source as FileMediaSource).path, '${root.path}/Music/a.mp3');
    });

    test('a missing file cannot be opened', () async {
      final opener = InternalTrackSourceOpener(() async => root.path);

      expect(
        () => opener.open(
          const Track(disk: internalDisk, relativePath: 'Music/gone.mp3'),
        ),
        throwsA(isA<TrackSourceException>()),
      );
    });

    test('a track of another disk cannot be opened', () async {
      final opener = InternalTrackSourceOpener(() async => root.path);

      expect(
        () => opener.open(
          const Track(disk: DiskId('ssd'), relativePath: 'a.mp3'),
        ),
        throwsA(isA<TrackSourceException>()),
      );
    });

    test('only the internal storage is available', () async {
      expect(await InternalVolumeEvents().availableDisks(), {internalDisk});
    });
  });
}
