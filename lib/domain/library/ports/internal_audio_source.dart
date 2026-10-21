import 'package:musicplayer/domain/library/model/library_track.dart';

/// The audio files of the internal storage, as MediaStore lists them
/// (ADR-005).
abstract interface class InternalAudioSource {
  /// Every file marked as music, whatever its folder.
  Future<List<TrackInfo>> queryAudio();
}

enum AudioPermissionStatus {
  granted,

  /// Never asked: the first launch asks once (FR-004).
  notRequested,

  /// Not granted yet; asking again shows the Android dialog.
  denied,

  /// Android no longer shows the dialog: only the app settings can grant it.
  permanentlyDenied,
}

/// Access to the audio files (FR-004), requested natively in `MainActivity`.
abstract interface class AudioPermission {
  Future<AudioPermissionStatus> status();

  Future<AudioPermissionStatus> request();

  Future<void> openAppSettings();
}
