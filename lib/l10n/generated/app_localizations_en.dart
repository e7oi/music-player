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
    return 'Cannot play “$title”: damaged file. Next track started.';
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

  @override
  String get searchSoon => 'Search (soon)';

  @override
  String get chipDisks => 'Disks';

  @override
  String disksAbsentBadge(int count) {
    return '$count missing';
  }

  @override
  String get libraryScanning => 'Looking for audio files…';

  @override
  String get libraryCountSearching => 'Searching…';

  @override
  String libraryCount(int total, int unavailable) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat unavailableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String unavailableString = unavailableNumberFormat.format(
      unavailable,
    );

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalString tracks',
      one: '$totalString track',
    );
    String _temp1 = intl.Intl.pluralLogic(
      unavailable,
      locale: localeName,
      other: ' · $unavailableString unavailable',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get librarySortTitle => 'Title A→Z';

  @override
  String bannerAbsentOne(int tracks, String disk) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString tracks skipped',
      one: '$tracksString track skipped',
    );
    return '$_temp0: $disk missing';
  }

  @override
  String bannerAbsentMany(int tracks, int count) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString tracks skipped',
      one: '$tracksString track skipped',
    );
    return '$_temp0: $count disks missing';
  }

  @override
  String bannerAccessOne(int tracks, String disk) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString tracks skipped',
      one: '$tracksString track skipped',
    );
    return '$_temp0: access to $disk must be renewed';
  }

  @override
  String bannerOther(int tracks, int count) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString tracks skipped',
      one: '$tracksString track skipped',
    );
    return '$_temp0: $count disks unavailable';
  }

  @override
  String get bannerSee => 'See';

  @override
  String get bannerDismiss => 'Hide this message';

  @override
  String get trackUnknownArtist => 'Unknown artist';

  @override
  String trackNotConnected(String artist) {
    return '$artist · not connected';
  }

  @override
  String get trackUnreadable => 'Unreadable file';

  @override
  String get trackPlaying => 'playing';

  @override
  String trackSource(String name) {
    return 'source $name';
  }

  @override
  String get sourceLocal => 'Local';

  @override
  String trackNeedsDisk(String disk) {
    return 'Plug in $disk to play this track';
  }

  @override
  String trackNeedsAccess(String disk) {
    return 'Renew the access to $disk to play this track';
  }

  @override
  String get emptyLibraryTitle => 'Your library is empty';

  @override
  String get emptyLibraryBody =>
      'No audio file in the chosen folders. Add other folders or refresh.';

  @override
  String get emptyNoFoldersTitle => 'No folder chosen';

  @override
  String get emptyNoFoldersBody =>
      'Choose at least one folder so TuneShell can find your music.';

  @override
  String get chooseFoldersAction => 'Choose folders';

  @override
  String get jumpCurrent => 'Now playing';

  @override
  String get jumpLastPlayed => 'Last played';

  @override
  String get indexGoToLetter => 'Go to letter';

  @override
  String indexCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString tracks';
  }

  @override
  String indexLetter(String letter, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Letter $letter, $countString tracks';
  }
}
