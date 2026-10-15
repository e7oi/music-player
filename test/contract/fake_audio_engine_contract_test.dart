import 'package:musicplayer/domain/storage/model/media_source.dart';

import '../fakes/fake_audio_engine.dart';
import 'audio_engine_contract.dart';

void main() {
  runAudioEngineContract(
    description: 'FakeAudioEngine',
    createEngine: () =>
        FakeAudioEngine(trackLength: const Duration(milliseconds: 50)),
    playableSource: () async => const FileMediaSource('fake://track'),
    unreadableSource: () async =>
        const FileMediaSource(FakeAudioEngine.unreadablePath),
    descriptorSourceFor: (onRelease) async =>
        DescriptorMediaSource(fd: 3, release: () async => onRelease()),
    quietPeriod: const Duration(milliseconds: 150),
  );
}
