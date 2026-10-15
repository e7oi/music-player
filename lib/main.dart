import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/app/app.dart';
import 'package:musicplayer/data/audio/media_kit_audio_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKitAudioEngine.ensureInitialized();
  runApp(const ProviderScope(child: MusicPlayerApp()));
}
