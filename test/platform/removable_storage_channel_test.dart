import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';
import 'package:tuneshell/domain/storage/model/volume_event.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/platform/file_tags_channel.dart';
import 'package:tuneshell/platform/removable_storage_channel.dart';

import '../fakes/fake_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const name = RemovableStorageChannel.channelName;
  const channel = MethodChannel(name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) reply = (_) => null;

  setUp(() {
    calls.clear();
    reply = (_) => null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const ssd = DiskId('1234-ABCD');

  group('FR-006 source', () {
    test('a picked folder carries the disk, its label and the path', () async {
      reply = (_) => {'uuid': '1234-abcd', 'path': 'Music', 'label': 'SSD'};

      final folder = await RemovableStorageChannel().pickFolder();

      expect(folder?.disk, ssd);
      expect(folder?.diskLabel, 'SSD');
      expect(folder?.path, 'Music');
    });

    test('a cancelled picker is null', () async {
      expect(await RemovableStorageChannel().pickFolder(), isNull);
    });

    test('scan turns the rows into track information without tags', () async {
      reply = (_) => [
        {'relativePath': 'Music/a.mp3', 'size': 12, 'modifiedMs': 5000},
      ];

      final found = await RemovableStorageChannel().scan(ssd, 'Music');

      expect(found.single.relativePath, 'Music/a.mp3');
      expect(found.single.size, 12);
      expect(found.single.modifiedAt.millisecondsSinceEpoch, 5000);
      expect(found.single.title, isNull);
      expect(calls.single.arguments, {'uuid': '1234-ABCD', 'path': 'Music'});
    });

    test('a lost access and a cancel are typed', () async {
      reply = (_) => throw PlatformException(code: 'access_lost');
      await expectLater(
        RemovableStorageChannel().scan(ssd, 'Music'),
        throwsA(isA<RemovableAccessException>()),
      );

      reply = (_) => throw PlatformException(code: 'cancelled');
      await expectLater(
        RemovableStorageChannel().scan(ssd, 'Music'),
        throwsA(isA<ScanCancelledException>()),
      );
    });

    test('any other scan failure stays an error', () async {
      reply = (_) => throw PlatformException(code: 'scan_failed');

      await expectLater(
        RemovableStorageChannel().scan(ssd, 'Music'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('mounted volumes use upper case identifiers', () async {
      reply = (_) => [
        {'uuid': '1234-abcd', 'label': 'SSD'},
      ];

      final volumes = await RemovableStorageChannel().mountedVolumes();

      expect(volumes.single.id, ssd);
    });
  });

  /// @verifies BR-006.1
  group('opening a track of a removable disk', () {
    test('gives the engine a descriptor it releases itself', () async {
      reply = (call) => call.method == 'openFd' ? 42 : null;
      final opener = RemovableTrackSourceOpener(RemovableStorageChannel());

      final source = await opener.open(
        const Track(disk: ssd, relativePath: 'Music/a.mp3'),
      );

      expect(source, isA<DescriptorMediaSource>());
      final descriptor = source as DescriptorMediaSource;
      expect(descriptor.fd, 42);
      expect(calls.where((c) => c.method == 'closeFd'), isEmpty);

      await descriptor.release();

      expect(calls.last.method, 'closeFd');
      expect(calls.last.arguments, {'fd': 42});
    });

    test('a refused file is a source exception', () async {
      reply = (_) => throw PlatformException(code: 'access_lost');
      final opener = RemovableTrackSourceOpener(RemovableStorageChannel());

      await expectLater(
        opener.open(const Track(disk: ssd, relativePath: 'a.mp3')),
        throwsA(isA<TrackSourceException>()),
      );
    });

    test('the router sends each disk to its own opener', () async {
      final internal = FakeTrackSourceOpener();
      final removable = FakeTrackSourceOpener();
      final router = RoutingTrackSourceOpener(
        internal: internal,
        removable: removable,
        internalDisk: internalDisk,
      );

      await router.open(const Track(disk: internalDisk, relativePath: 'a'));
      await router.open(const Track(disk: ssd, relativePath: 'b'));

      expect(internal.opened.single.relativePath, 'a');
      expect(removable.opened.single.relativePath, 'b');
    });
  });

  /// @verifies FR-006.10
  group('availability of the removable disks', () {
    test('the internal storage is always available', () async {
      reply = (_) => <Object?>[];
      final events = RemovableVolumeEvents(
        RemovableStorageChannel(),
        internalDisk,
      );

      expect(await events.availableDisks(), {internalDisk});
    });

    test('a refresh announces a disk that came and one that went', () async {
      var mounted = <Map<String, String>>[
        {'uuid': '1234-ABCD', 'label': 'SSD'},
      ];
      reply = (_) => mounted;
      final events = RemovableVolumeEvents(
        RemovableStorageChannel(),
        internalDisk,
      );
      expect(await events.availableDisks(), {internalDisk, ssd});
      final seen = <VolumeEvent>[];
      events.events.listen(seen.add);

      mounted = [];
      await events.refresh();
      mounted = [
        {'uuid': '1234-ABCD', 'label': 'SSD'},
      ];
      await events.refresh();
      await events.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(seen.map((e) => e.runtimeType), [VolumeRemoved, VolumeMounted]);
      expect(seen.every((e) => e.disk == ssd), isTrue);
    });
  });

  group('FR-007 tags', () {
    const tagsChannel = MethodChannel(FileTagsChannel.channelName);

    test('a row becomes tags, the internal storage is read by path', () async {
      messenger.setMockMethodCallHandler(tagsChannel, (call) async {
        calls.add(call);
        return {
          'title': 'T',
          'track': 3,
          'durationMs': 61000,
          'artwork': 'abc',
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(tagsChannel, null));

      final tags = await FileTagsChannel(internalDisk)
          .read(const Track(disk: internalDisk, relativePath: 'Music/a.mp3'));

      expect(tags?.title, 'T');
      expect(tags?.trackNumber, 3);
      expect(tags?.duration, const Duration(seconds: 61));
      expect(tags?.artwork, 'abc');
      expect(calls.single.arguments, {'uuid': null, 'path': 'Music/a.mp3'});
    });

    test('a removable track is read through its volume', () async {
      messenger.setMockMethodCallHandler(tagsChannel, (call) async {
        calls.add(call);
        return <String, Object?>{};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(tagsChannel, null));

      await FileTagsChannel(internalDisk)
          .read(const Track(disk: ssd, relativePath: 'a.mp3'));

      expect(calls.single.arguments, {'uuid': '1234-ABCD', 'path': 'a.mp3'});
    });
  });
}
