import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:musicplayer/data/audio/media_kit_audio_engine.dart';
import 'package:musicplayer/domain/storage/model/media_source.dart';

import '../test/contract/audio_engine_contract.dart';

/// Runs the AudioEngine contract against media_kit on a device, in release
/// mode through `flutter drive` (procedure in HOWTO.md §10).
///
/// The audio is generated here, so no personal file is needed (D27).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKitAudioEngine.ensureInitialized();

  late File tone;
  late File garbage;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('engine_contract');
    tone = await File('${dir.path}/tone.wav').writeAsBytes(_sineWav());
    garbage = await File('${dir.path}/garbage.flac')
        .writeAsBytes(List<int>.generate(64 * 1024, (i) => (i * 7919) & 0xff));
  });

  runAudioEngineContract(
    description: 'media_kit',
    createEngine: MediaKitAudioEngine.new,
    playableSource: () async => FileMediaSource(tone.path),
    unreadableSource: () async => FileMediaSource(garbage.path),
  );
}

/// One second of a 440 Hz sine, 16-bit mono PCM at 44.1 kHz.
Uint8List _sineWav() {
  const sampleRate = 44100;
  const samples = sampleRate;
  const dataSize = samples * 2;
  final bytes = ByteData(44 + dataSize);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples; i++) {
    final value = (sin(2 * pi * 440 * i / sampleRate) * 8000).round();
    bytes.setInt16(44 + i * 2, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
