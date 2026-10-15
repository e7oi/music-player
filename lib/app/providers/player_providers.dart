import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/app/providers/library_providers.dart';
import 'package:musicplayer/data/audio/media_kit_audio_engine.dart';
import 'package:musicplayer/domain/playback/model/playback_notice.dart';
import 'package:musicplayer/domain/playback/model/player_state.dart';
import 'package:musicplayer/domain/playback/ports/audio_engine.dart';
import 'package:musicplayer/domain/playback/services/player_controller.dart';
import 'package:musicplayer/domain/storage/ports/track_source_opener.dart';
import 'package:musicplayer/domain/storage/ports/volume_events.dart';
import 'package:musicplayer/platform/internal_storage.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = MediaKitAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final trackSourceOpenerProvider = Provider<TrackSourceOpener>((ref) {
  final mediaStore = ref.watch(mediaStoreProvider);
  return InternalTrackSourceOpener(mediaStore.internalStorageRoot);
});

final volumeEventsProvider = Provider<VolumeEvents>(
  (ref) => InternalVolumeEvents(),
);

/// The controller owns no engine (ADR-002): this provider disposes the
/// controller, [audioEngineProvider] the engine.
final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController(
    engine: ref.watch(audioEngineProvider),
    opener: ref.watch(trackSourceOpenerProvider),
    volumes: ref.watch(volumeEventsProvider),
  );
  ref.onDispose(controller.dispose);
  // The controller queues every command behind its start.
  unawaited(controller.start());
  return controller;
});

final playerStateProvider = StreamProvider<PlayerState>((ref) async* {
  final controller = ref.watch(playerControllerProvider);
  yield controller.state;
  yield* controller.states;
});

final playbackNoticesProvider = StreamProvider<PlaybackNotice>(
  (ref) => ref.watch(playerControllerProvider).notices,
);
