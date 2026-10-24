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
  String get foldersTitle => 'Music folders';

  @override
  String get foldersRoot => 'Storage root';

  @override
  String get foldersConfirm => 'Confirm';

  @override
  String get libraryRefresh => 'Refresh';

  @override
  String get libraryFolders => 'Folders';

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

  @override
  String get welcomeGreeting => 'Welcome to';

  @override
  String get welcomeTagline => 'Your music, at home.';

  @override
  String get welcomePromiseRead =>
      'Reads the files already on your phone and your disks.';

  @override
  String get welcomePromiseNoAccount => 'No account, no ads.';

  @override
  String get welcomePromiseNoData =>
      'No data sent: everything stays on the device.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeFooter => 'Free and open source';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get accessTitle => 'Allow access to your music';

  @override
  String get accessBody =>
      'TuneShell needs to read the audio files of this phone to build your library.';

  @override
  String get accessGuaranteeReadOnly =>
      'Read only: nothing is changed or deleted';

  @override
  String get accessGuaranteeLocal => 'Nothing leaves your phone';

  @override
  String get accessAllow => 'Allow access';

  @override
  String get accessRetry => 'Try again';

  @override
  String get accessNotNow => 'Not now';

  @override
  String get accessRefused =>
      'Access denied. Without it, TuneShell cannot find your music.';

  @override
  String get blockedTitle => 'Access is blocked';

  @override
  String get blockedBody =>
      'Android no longer lets the app ask for permission. You can turn it on in the app settings:';

  @override
  String get blockedStepSettings => 'Open the TuneShell settings';

  @override
  String get blockedStepPermissions => 'Permissions';

  @override
  String get blockedStepMusic => 'Music and audio';

  @override
  String get blockedStepAllow => 'Allow';

  @override
  String get blockedOpenSettings => 'Open settings';

  @override
  String get blockedChooseFolder => 'Choose a folder instead';

  @override
  String get blockedNote =>
      'Choosing a folder on a removable disk works without this permission.';

  @override
  String get declinedTitle => 'Access to your music not granted';

  @override
  String get declinedBody =>
      'TuneShell cannot read your audio files without your permission.';

  @override
  String get foldersIntro =>
      'TuneShell looks for your music in the checked folders. You can change this choice later.';

  @override
  String get foldersSection => 'Internal storage';

  @override
  String folderAudioCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString audio files',
      one: '$countString audio file',
    );
    return '$_temp0';
  }

  @override
  String get foldersAdd => 'Add a folder';

  @override
  String foldersSummary(int folders, int files) {
    final intl.NumberFormat filesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String filesString = filesNumberFormat.format(files);

    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '$folders folder',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$filesString files',
      one: '$filesString file',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String foldersCounting(int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '$folders folder',
    );
    return '$_temp0 · counting…';
  }

  @override
  String get foldersContinue => 'Continue';

  @override
  String get foldersNoneChecked => 'Check at least one folder to continue.';

  @override
  String get foldersEmptyTitle => 'No audio file found';

  @override
  String get foldersEmptyBody =>
      'No folder on this phone holds music. Add a folder or plug in a disk.';

  @override
  String get foldersNothingToAdd => 'No folder to add.';

  @override
  String get foldersReadFailed => 'The folders could not be read.';

  @override
  String get playerOpen => 'Open the player';

  @override
  String playerStoppedLost(String disk) {
    return 'Stopped: $disk unplugged';
  }

  @override
  String get playerCollapse => 'Collapse';

  @override
  String get playerPlayingFrom => 'Playing from';

  @override
  String get playerFavoriteSoon => 'Favorites (coming soon)';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerModeOn => 'on';

  @override
  String get playerModeOff => 'off';

  @override
  String get playerRepeatAll => 'all tracks';

  @override
  String get playerRepeatOne => 'one track';

  @override
  String get playerSeek => 'Position';

  @override
  String playerPositionValue(String position, String total) {
    return '$position of $total';
  }

  @override
  String playerUpNext(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up next · $countString tracks',
      one: 'Up next · $countString track',
      zero: 'Up next · no track',
    );
    return '$_temp0';
  }

  @override
  String playerDiscNumber(int number) {
    return 'Disc $number';
  }

  @override
  String playerTrackNumber(int number) {
    return 'Track $number';
  }

  @override
  String playerStoppedBanner(String disk) {
    return 'Playback stopped: $disk unplugged';
  }

  @override
  String get queueTitle => 'Queue';

  @override
  String queueSummary(int count, String duration) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks',
      one: '$countString track',
    );
    return '$_temp0 · $duration';
  }

  @override
  String queueSummaryShuffled(int count, String duration) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks',
      one: '$countString track',
    );
    return '$_temp0 · $duration · shuffled';
  }

  @override
  String get queueClear => 'Clear upcoming';

  @override
  String get queueNow => 'Now playing';

  @override
  String get queueNext => 'Up next';

  @override
  String queueMove(String title) {
    return 'Move $title';
  }

  @override
  String queueWillSkip(String artist) {
    return '$artist · not connected, will be skipped';
  }

  @override
  String get queueRemove => 'Remove from queue';

  @override
  String queueRemoved(String title) {
    return '$title removed from the queue';
  }

  @override
  String get menuPlayNext => 'Play next';

  @override
  String get menuAddToQueue => 'Add to queue';

  @override
  String menuPlayNextDone(String title) {
    return 'Playing next: $title';
  }

  @override
  String menuAddedDone(String title) {
    return 'Added to the queue: $title';
  }

  @override
  String albumsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString albums',
      one: '$countString album',
    );
    return '$_temp0';
  }

  @override
  String get albumsSort => 'Album artist';

  @override
  String get albumUnknown => 'Unknown album';

  @override
  String groupTracks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks',
      one: '$countString track',
    );
    return '$_temp0';
  }

  @override
  String albumDiscs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString discs',
      one: '$countString disc',
    );
    return '$_temp0';
  }

  @override
  String albumNotConnected(String label, String disk) {
    return '$label, unavailable: $disk not connected';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours, String minutes) {
    return '$hours h $minutes';
  }

  @override
  String get albumPlay => 'Play';

  @override
  String get artistPlayAll => 'Play all';

  @override
  String artistsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString artists',
      one: '$countString artist',
    );
    return '$_temp0 · grouped by album artist';
  }

  @override
  String artistSummary(int albums, int tracks) {
    String _temp0 = intl.Intl.pluralLogic(
      albums,
      locale: localeName,
      other: '$albums albums',
      one: '$albums album',
    );
    String _temp1 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracks tracks',
      one: '$tracks track',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String artistUnknownSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks without tags',
      one: '$countString track without tags',
    );
    return '$_temp0';
  }

  @override
  String artistNotConnected(String summary, String disk) {
    return '$summary · $disk not connected';
  }

  @override
  String get groupsEmptyAlbums => 'No albums';

  @override
  String get groupsEmptyArtists => 'No artists';

  @override
  String get groupsEmptyHint => 'Choose folders in the Tracks tab.';

  @override
  String queueOriginAlbum(String title) {
    return 'Album · $title';
  }

  @override
  String queueOriginArtist(String name) {
    return 'Artist · $name';
  }

  @override
  String get groupNotFound => 'This album is no longer in the library.';

  @override
  String get artistNotFound => 'This artist is no longer in the library.';
}
