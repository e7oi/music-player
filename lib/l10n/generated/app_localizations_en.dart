// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TuneShell';

  @override
  String get permissionExplanation =>
      'Access to the audio files is needed to show and play the music on this phone.';

  @override
  String get permissionRetry => 'Allow access';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String get foldersTitle => 'Music folders';

  @override
  String get foldersExplanation =>
      'Choose the folders that hold your music. Ringtones and audio from messaging apps stay out unless their folder is checked.';

  @override
  String get foldersRoot => 'Storage root';

  @override
  String folderFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get foldersConfirm => 'Confirm';

  @override
  String get foldersNone => 'No folder of this phone holds audio.';

  @override
  String get libraryRefresh => 'Refresh';

  @override
  String get libraryFolders => 'Folders';

  @override
  String get libraryNoFolders => 'No folder chosen.';

  @override
  String get libraryEmpty => 'No track found in the chosen folders.';

  @override
  String get libraryChooseFolders => 'Choose folders';

  @override
  String get libraryIndexFailed => 'The library could not be refreshed.';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next track';

  @override
  String get playerPrevious => 'Previous track';

  @override
  String noticeTracksSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks skipped: disk missing',
      one: '1 track skipped: disk missing',
    );
    return '$_temp0';
  }

  @override
  String noticeTrackFailed(String title) {
    return 'Cannot play $title';
  }

  @override
  String noticeStoppedAfterFailures(int count) {
    return 'Playback stopped after $count failures in a row';
  }

  @override
  String get noticeStoppedByEjection => 'Playback stopped: disk removed';

  @override
  String get libraryLoadFailed =>
      'The folders of this phone could not be read.';

  @override
  String get libraryRetry => 'Retry';

  @override
  String get notificationChannelName => 'Playback';

  @override
  String get notificationChannelDescription =>
      'Playback controls: previous, pause, next.';

  @override
  String get libraryDisks => 'Removable disks';

  @override
  String get removableTitle => 'Removable disks';

  @override
  String get removableNone =>
      'No removable disk yet. Plug in your drive, then add one of its folders.';

  @override
  String get removableAddFolder => 'Add a folder';

  @override
  String get removableRootFolder => 'Whole disk';

  @override
  String get removableAbsent => 'Not connected';

  @override
  String get removableAccessLost => 'Access to renew';

  @override
  String get removableAvailable => 'Connected';

  @override
  String get removableRenew => 'Renew access';

  @override
  String get removableRemoveFolder => 'Remove this folder';

  @override
  String get removableCancel => 'Stop';

  @override
  String get removableNoAudio => 'No audio file was found in this folder.';

  @override
  String get removableAddFailed =>
      'The folder could not be read. Check that the disk is connected, then try again.';

  @override
  String get removableNotRemovable =>
      'This folder is on the phone\'s own storage. Choose a folder of the removable disk.';

  @override
  String get removableRefreshFailed =>
      'The disk could not be read. The library was kept as it was.';

  @override
  String tagsProgress(int done, int total) {
    return 'Reading tags: $done / $total';
  }

  @override
  String get navTracks => 'Tracks';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navArtists => 'Artists';

  @override
  String get navSettings => 'Settings';

  @override
  String get comingSoon => 'This view is coming soon.';

  @override
  String get demoGallery => 'Component gallery';

  @override
  String get foldersBack => 'Back';
}
