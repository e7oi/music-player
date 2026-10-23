import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_storage.dart';

void main() {
  /// A disk list that arrives at once used to be lost: the provider read the
  /// current state, then subscribed, and anything emitted in between never
  /// reached the interface (the tracks stayed greyed). The race depends on
  /// microtask timing, so this test is a guard; the page tests of
  /// `library_page_test.dart` (greyed tracks, playing a track) are the ones
  /// that failed without the fix.
  test('keeps a state emitted right after the controller starts', () async {
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
        volumeEventsProvider.overrideWithValue(
          FakeVolumeEvents({internalDisk, const DiskId('ssd')}),
        ),
      ],
    );
    addTearDown(container.dispose);
    final seen = <Set<DiskId>>[];
    container.listen(playerStateProvider, (_, next) {
      if (next.hasValue) seen.add(next.requireValue.availableDisks);
    }, fireImmediately: true);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(seen.last, {internalDisk, const DiskId('ssd')});
  });

  test('later changes still arrive', () async {
    final volumes = FakeVolumeEvents({internalDisk});
    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
        volumeEventsProvider.overrideWithValue(volumes),
      ],
    );
    addTearDown(container.dispose);
    container.listen(playerStateProvider, (_, _) {}, fireImmediately: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await container.read(playerControllerProvider).setQueue([
      const Track(disk: internalDisk, relativePath: 'a.mp3'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      container.read(playerStateProvider).requireValue.queue,
      hasLength(1),
    );
  });
}
