import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/app.dart';
import 'package:tuneshell/app/system_playback.dart';
import 'package:tuneshell/data/audio/media_kit_audio_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKitAudioEngine.ensureInitialized();
  // One container shared by the screens and the media session.
  final container = ProviderContainer();
  await startSystemPlayback(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TuneShellApp(),
    ),
  );
}
