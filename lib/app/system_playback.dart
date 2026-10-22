import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/playback/services/interruption_policy.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/platform/audio_session_interruptions.dart';
import 'package:tuneshell/platform/media_session/player_audio_handler.dart';

/// Hands the player controller of [container] to Android: audio focus
/// (BR-005) and the media session with its notification (FR-005). Runs once
/// per process: the Flutter engine outlives the activity, and the process
/// ends with it (MainActivity, ADR-006).
Future<void> startSystemPlayback(ProviderContainer container) async {
  final controller = container.read(playerControllerProvider);
  InterruptionPolicy(
    controller: controller,
    interruptions: await AudioSessionInterruptions.create(),
  ).start();

  final l10n = lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  await AudioService.init(
    builder: () => PlayerAudioHandler(
      controller,
      describe: (track) => container.read(libraryTrackIndexProvider)[track],
    ),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'net.trtl3.tuneshell.playback',
      androidNotificationChannelName: l10n.notificationChannelName,
      androidNotificationChannelDescription:
          l10n.notificationChannelDescription,
    ),
  );
}
