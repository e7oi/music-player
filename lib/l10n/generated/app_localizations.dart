import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Application name shown in the app bar and the task switcher.
  ///
  /// In en, this message translates to:
  /// **'TuneShell'**
  String get appTitle;

  /// Title of the folder choice screen (FR-003).
  ///
  /// In en, this message translates to:
  /// **'Music folders'**
  String get foldersTitle;

  /// Name shown for audio files placed directly at the root of the internal storage.
  ///
  /// In en, this message translates to:
  /// **'Storage root'**
  String get foldersRoot;

  /// Confirms the folder choice and starts indexing.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get foldersConfirm;

  /// Action that reindexes the library.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get libraryRefresh;

  /// Action that reopens the folder choice.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get libraryFolders;

  /// Shown when indexing failed; the stored library stays visible.
  ///
  /// In en, this message translates to:
  /// **'The library could not be refreshed.'**
  String get libraryIndexFailed;

  /// Tooltip of the play button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Tooltip of the pause button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Tooltip of the next button.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get playerNext;

  /// Tooltip of the previous button.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get playerPrevious;

  /// BR-001: tracks of an unavailable disk were skipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track skipped: disk missing} other{{count} tracks skipped: disk missing}}'**
  String noticeTracksSkipped(int count);

  /// BR-003: a track could not be played.
  ///
  /// In en, this message translates to:
  /// **'Cannot play “{title}”: damaged file. Next track started.'**
  String noticeTrackFailed(String title);

  /// BR-003: too many consecutive failures.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped after {count} failures in a row'**
  String noticeStoppedAfterFailures(int count);

  /// BR-002: the disk of the current track was ejected.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped: disk removed'**
  String get noticeStoppedByEjection;

  /// Retries reading the folders.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get libraryRetry;

  /// Name of the Android notification channel of the playback notification (FR-005).
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get notificationChannelName;

  /// Description of the playback notification channel, shown in the Android settings.
  ///
  /// In en, this message translates to:
  /// **'Playback controls: previous, pause, next.'**
  String get notificationChannelDescription;

  /// Tooltip of the button that opens the removable disks (FR-006)
  ///
  /// In en, this message translates to:
  /// **'Removable disks'**
  String get libraryDisks;

  /// Title of the removable disks screen
  ///
  /// In en, this message translates to:
  /// **'Removable disks'**
  String get removableTitle;

  /// Shown when no removable disk is in the library
  ///
  /// In en, this message translates to:
  /// **'No removable disk yet. Plug in your drive, then add one of its folders.'**
  String get removableNone;

  /// Button that opens the Android folder picker
  ///
  /// In en, this message translates to:
  /// **'Add a folder'**
  String get removableAddFolder;

  /// Name of the folder that is the root of the disk
  ///
  /// In en, this message translates to:
  /// **'Whole disk'**
  String get removableRootFolder;

  /// State of a removable disk that is not mounted
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get removableAbsent;

  /// State of a mounted disk whose access was lost
  ///
  /// In en, this message translates to:
  /// **'Access to renew'**
  String get removableAccessLost;

  /// State of a readable removable disk
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get removableAvailable;

  /// Button that reopens the folder picker for a disk whose access was lost
  ///
  /// In en, this message translates to:
  /// **'Renew access'**
  String get removableRenew;

  /// Tooltip of the button that removes a folder from the library
  ///
  /// In en, this message translates to:
  /// **'Remove this folder'**
  String get removableRemoveFolder;

  /// Button that stops the scan and the reading of tags
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get removableCancel;

  /// Message after choosing a folder without audio
  ///
  /// In en, this message translates to:
  /// **'No audio file was found in this folder.'**
  String get removableNoAudio;

  /// Message when the scan of a new folder fails
  ///
  /// In en, this message translates to:
  /// **'The folder could not be read. Check that the disk is connected, then try again.'**
  String get removableAddFailed;

  /// Message when the picked folder is on the internal storage
  ///
  /// In en, this message translates to:
  /// **'This folder is on the phone\'s own storage. Choose a folder of the removable disk.'**
  String get removableNotRemovable;

  /// Message when refreshing a disk fails
  ///
  /// In en, this message translates to:
  /// **'The disk could not be read. The library was kept as it was.'**
  String get removableRefreshFailed;

  /// Progress of the reading of tags and artwork
  ///
  /// In en, this message translates to:
  /// **'Reading tags: {done} / {total}'**
  String tagsProgress(int done, int total);

  /// Label of the Tracks tab (FR-009).
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get navTracks;

  /// Label of the Albums tab (FR-009).
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get navAlbums;

  /// Label of the Artists tab (FR-009).
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get navArtists;

  /// Label of the Settings tab (FR-009).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Shown by the tabs whose content is not built yet (FR-009).
  ///
  /// In en, this message translates to:
  /// **'This view is coming soon.'**
  String get comingSoon;

  /// Entry of the settings tab that opens the component demo page (debug and profile builds only, FR-010).
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get demoGallery;

  /// Tooltip of the back arrow of the folder choice when it was opened from the library (FR-003).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get foldersBack;

  /// Tooltip of the disabled search button of the Tracks header (FR-011.1).
  ///
  /// In en, this message translates to:
  /// **'Search (soon)'**
  String get searchSoon;

  /// Label of the Disks action chip of the Tracks view (FR-011.2).
  ///
  /// In en, this message translates to:
  /// **'Disks'**
  String get chipDisks;

  /// Badge on the Disks chip when disks are absent or need access (FR-011.2).
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String disksAbsentBadge(int count);

  /// Progress banner of the first scan (FR-011.4).
  ///
  /// In en, this message translates to:
  /// **'Looking for audio files…'**
  String get libraryScanning;

  /// Count line while the first scan runs (FR-011.4).
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get libraryCountSearching;

  /// Count line of the track list (FR-011.5).
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{{total} track} other{{total} tracks}}{unavailable, plural, =0{} other{ · {unavailable} unavailable}}'**
  String libraryCount(int total, int unavailable);

  /// Label of the only sort of the track list (FR-011.5).
  ///
  /// In en, this message translates to:
  /// **'Title A→Z'**
  String get librarySortTitle;

  /// Banner when one disk is absent (BR-008.2).
  ///
  /// In en, this message translates to:
  /// **'{tracks, plural, one{{tracks} track skipped} other{{tracks} tracks skipped}}: {disk} missing'**
  String bannerAbsentOne(int tracks, String disk);

  /// Banner when several disks are absent (BR-008.2).
  ///
  /// In en, this message translates to:
  /// **'{tracks, plural, one{{tracks} track skipped} other{{tracks} tracks skipped}}: {count} disks missing'**
  String bannerAbsentMany(int tracks, int count);

  /// Banner when the access to one disk is lost (BR-008.2).
  ///
  /// In en, this message translates to:
  /// **'{tracks, plural, one{{tracks} track skipped} other{{tracks} tracks skipped}}: access to {disk} must be renewed'**
  String bannerAccessOne(int tracks, String disk);

  /// Banner for several disks, absent or needing access (BR-008.2).
  ///
  /// In en, this message translates to:
  /// **'{tracks, plural, one{{tracks} track skipped} other{{tracks} tracks skipped}}: {count} disks unavailable'**
  String bannerOther(int tracks, int count);

  /// Action of the sources banner: opens the disks screen (BR-008.2).
  ///
  /// In en, this message translates to:
  /// **'See'**
  String get bannerSee;

  /// Tooltip of the close button of the sources banner (BR-008.3).
  ///
  /// In en, this message translates to:
  /// **'Hide this message'**
  String get bannerDismiss;

  /// Shown for a track without an artist tag (FR-011.6).
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get trackUnknownArtist;

  /// Second line of a track whose disk is absent (FR-011.6).
  ///
  /// In en, this message translates to:
  /// **'{artist} · not connected'**
  String trackNotConnected(String artist);

  /// Second line of a track the engine failed on (FR-011.6).
  ///
  /// In en, this message translates to:
  /// **'Unreadable file'**
  String get trackUnreadable;

  /// Said by TalkBack for the track being played (FR-011.12).
  ///
  /// In en, this message translates to:
  /// **'playing'**
  String get trackPlaying;

  /// Said by TalkBack after a track: its source (FR-011.12).
  ///
  /// In en, this message translates to:
  /// **'source {name}'**
  String trackSource(String name);

  /// Name of the internal storage as a source (FR-012.6).
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// Message when an unavailable track is touched (BR-008.5).
  ///
  /// In en, this message translates to:
  /// **'Plug in {disk} to play this track'**
  String trackNeedsDisk(String disk);

  /// Message when a track whose disk access is lost is touched (BR-008.5).
  ///
  /// In en, this message translates to:
  /// **'Renew the access to {disk} to play this track'**
  String trackNeedsAccess(String disk);

  /// Title of the empty library state (FR-011.9).
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get emptyLibraryTitle;

  /// Body of the empty library state (FR-011.9).
  ///
  /// In en, this message translates to:
  /// **'No audio file in the chosen folders. Add other folders or refresh.'**
  String get emptyLibraryBody;

  /// Title of the no-folder state (FR-011.9).
  ///
  /// In en, this message translates to:
  /// **'No folder chosen'**
  String get emptyNoFoldersTitle;

  /// Body of the no-folder state (FR-011.9).
  ///
  /// In en, this message translates to:
  /// **'Choose at least one folder so TuneShell can find your music.'**
  String get emptyNoFoldersBody;

  /// Button of the empty states (FR-011.9).
  ///
  /// In en, this message translates to:
  /// **'Choose folders'**
  String get chooseFoldersAction;

  /// Label of the button that leads to the track being played (FR-013.3).
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get jumpCurrent;

  /// Label of the button when nothing plays (FR-013.4).
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get jumpLastPlayed;

  /// Title of the letter grid and label of the index handle (FR-013.1).
  ///
  /// In en, this message translates to:
  /// **'Go to letter'**
  String get indexGoToLetter;

  /// Count in the bubble of the alphabet index (FR-013.1).
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String indexCount(int count);

  /// Said by TalkBack for a letter of the index (FR-013.1).
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}, {count} tracks'**
  String indexLetter(String letter, int count);

  /// Small line above the name on the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeGreeting;

  /// Tagline of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'Your music, at home.'**
  String get welcomeTagline;

  /// First promise of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'Reads the files already on your phone and your disks.'**
  String get welcomePromiseRead;

  /// Second promise of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'No account, no ads.'**
  String get welcomePromiseNoAccount;

  /// Third promise of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'No data sent: everything stays on the device.'**
  String get welcomePromiseNoData;

  /// Button of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeStart;

  /// Footer line of the welcome screen (FR-014.1).
  ///
  /// In en, this message translates to:
  /// **'Free and open source'**
  String get welcomeFooter;

  /// Step indicator of the first launch (FR-014.1, FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// Title of the explanation screen (FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'Allow access to your music'**
  String get accessTitle;

  /// Body of the explanation screen (FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'TuneShell needs to read the audio files of this phone to build your library.'**
  String get accessBody;

  /// First guarantee of the explanation screen (FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'Read only: nothing is changed or deleted'**
  String get accessGuaranteeReadOnly;

  /// Second guarantee of the explanation screen (FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your phone'**
  String get accessGuaranteeLocal;

  /// Button that asks Android for access (FR-014.2).
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get accessAllow;

  /// Button after a simple refusal (FR-014.3).
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get accessRetry;

  /// Button that postpones the access (FR-014.6).
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get accessNotNow;

  /// Banner after a simple refusal (FR-014.3).
  ///
  /// In en, this message translates to:
  /// **'Access denied. Without it, TuneShell cannot find your music.'**
  String get accessRefused;

  /// Title of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Access is blocked'**
  String get blockedTitle;

  /// Body of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Android no longer lets the app ask for permission. You can turn it on in the app settings:'**
  String get blockedBody;

  /// First step of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Open the TuneShell settings'**
  String get blockedStepSettings;

  /// Second step of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get blockedStepPermissions;

  /// Third step of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Music and audio'**
  String get blockedStepMusic;

  /// Fourth step of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get blockedStepAllow;

  /// Button that opens the app settings (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get blockedOpenSettings;

  /// Button that opens the Android folder picker (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Choose a folder instead'**
  String get blockedChooseFolder;

  /// Note under the buttons of the blocked screen (FR-014.5).
  ///
  /// In en, this message translates to:
  /// **'Choosing a folder on a removable disk works without this permission.'**
  String get blockedNote;

  /// Title of the library when the user chose Not now (FR-014.6).
  ///
  /// In en, this message translates to:
  /// **'Access to your music not granted'**
  String get declinedTitle;

  /// Body of the library when the user chose Not now (FR-014.6).
  ///
  /// In en, this message translates to:
  /// **'TuneShell cannot read your audio files without your permission.'**
  String get declinedBody;

  /// Introduction of the folder choice (FR-015.1).
  ///
  /// In en, this message translates to:
  /// **'TuneShell looks for your music in the checked folders. You can change this choice later.'**
  String get foldersIntro;

  /// Section title of the folder list (FR-015.1).
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get foldersSection;

  /// File count under a folder (FR-015.1).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} audio file} other{{count} audio files}}'**
  String folderAudioCount(int count);

  /// Button that opens the folder picker for a removable disk (FR-015.7).
  ///
  /// In en, this message translates to:
  /// **'Add a folder'**
  String get foldersAdd;

  /// Summary under the folder list (FR-015.1).
  ///
  /// In en, this message translates to:
  /// **'{folders, plural, one{{folders} folder} other{{folders} folders}} · {files, plural, one{{files} file} other{{files} files}}'**
  String foldersSummary(int folders, int files);

  /// Summary while the counts are read (FR-015.3).
  ///
  /// In en, this message translates to:
  /// **'{folders, plural, one{{folders} folder} other{{folders} folders}} · counting…'**
  String foldersCounting(int folders);

  /// Button of the first folder choice (FR-015.1).
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get foldersContinue;

  /// Message when no folder is checked (FR-015.4).
  ///
  /// In en, this message translates to:
  /// **'Check at least one folder to continue.'**
  String get foldersNoneChecked;

  /// Title when no folder holds audio (FR-015.5).
  ///
  /// In en, this message translates to:
  /// **'No audio file found'**
  String get foldersEmptyTitle;

  /// Body when no folder holds audio (FR-015.5).
  ///
  /// In en, this message translates to:
  /// **'No folder on this phone holds music. Add a folder or plug in a disk.'**
  String get foldersEmptyBody;

  /// Summary when no folder holds audio (FR-015.5).
  ///
  /// In en, this message translates to:
  /// **'No folder to add.'**
  String get foldersNothingToAdd;

  /// Error banner of the folder choice (FR-015.6).
  ///
  /// In en, this message translates to:
  /// **'The folders could not be read.'**
  String get foldersReadFailed;

  /// Label of the mini player zone that opens the full-screen player (FR-016.4).
  ///
  /// In en, this message translates to:
  /// **'Open the player'**
  String get playerOpen;

  /// Second line of the mini player when the disk of the track left (FR-016.7).
  ///
  /// In en, this message translates to:
  /// **'Stopped: {disk} unplugged'**
  String playerStoppedLost(String disk);

  /// Button that closes the full-screen player (FR-017.1).
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get playerCollapse;

  /// Caption above the origin of the queue (FR-017.2).
  ///
  /// In en, this message translates to:
  /// **'Playing from'**
  String get playerPlayingFrom;

  /// Tooltip of the disabled heart (FR-017.5).
  ///
  /// In en, this message translates to:
  /// **'Favorites (coming soon)'**
  String get playerFavoriteSoon;

  /// Label of the shuffle button (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// Label of the repeat button (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get playerRepeat;

  /// Said by TalkBack after Shuffle when it is on (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get playerModeOn;

  /// Said by TalkBack after Shuffle or Repeat when it is off (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get playerModeOff;

  /// Said by TalkBack after Repeat (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'all tracks'**
  String get playerRepeatAll;

  /// Said by TalkBack after Repeat (FR-017.7).
  ///
  /// In en, this message translates to:
  /// **'one track'**
  String get playerRepeatOne;

  /// Label of the position slider (FR-017.6).
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get playerSeek;

  /// Said by TalkBack for the position slider (FR-017.6).
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String playerPositionValue(String position, String total);

  /// Button that opens the queue (FR-017.8).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Up next · no track} one{Up next · {count} track} other{Up next · {count} tracks}}'**
  String playerUpNext(int count);

  /// Part of the details line of the player (FR-017.4).
  ///
  /// In en, this message translates to:
  /// **'Disc {number}'**
  String playerDiscNumber(int number);

  /// Part of the details line of the player (FR-017.4).
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String playerTrackNumber(int number);

  /// Banner of the player after an ejection (FR-017.10).
  ///
  /// In en, this message translates to:
  /// **'Playback stopped: {disk} unplugged'**
  String playerStoppedBanner(String disk);

  /// Title of the queue sheet (FR-018.2).
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// Summary under the queue title (FR-018.2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} track} other{{count} tracks}} · {duration}'**
  String queueSummary(int count, String duration);

  /// Summary under the queue title when the shuffle is on (FR-018.2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} track} other{{count} tracks}} · {duration} · shuffled'**
  String queueSummaryShuffled(int count, String duration);

  /// Button that removes the tracks after the current one (FR-018.9).
  ///
  /// In en, this message translates to:
  /// **'Clear upcoming'**
  String get queueClear;

  /// Section of the current track in the queue (FR-018.3).
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get queueNow;

  /// Section of the next tracks in the queue (FR-018.4).
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get queueNext;

  /// Label of the drag handle of a queue row (FR-018.5).
  ///
  /// In en, this message translates to:
  /// **'Move {title}'**
  String queueMove(String title);

  /// Second line of a queue row whose disk is absent (FR-018.7).
  ///
  /// In en, this message translates to:
  /// **'{artist} · not connected, will be skipped'**
  String queueWillSkip(String artist);

  /// Action of a queue row for TalkBack (FR-018.8).
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemove;

  /// Message after a track is removed from the queue (FR-018.8).
  ///
  /// In en, this message translates to:
  /// **'{title} removed from the queue'**
  String queueRemoved(String title);

  /// Action of the menu of a track (FR-019.1).
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get menuPlayNext;

  /// Action of the menu of a track (FR-019.1).
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get menuAddToQueue;

  /// Message after Play next (FR-019.3).
  ///
  /// In en, this message translates to:
  /// **'Playing next: {title}'**
  String menuPlayNextDone(String title);

  /// Message after Add to queue (FR-019.3).
  ///
  /// In en, this message translates to:
  /// **'Added to the queue: {title}'**
  String menuAddedDone(String title);

  /// Count line of the Albums view (FR-020.1).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} album} other{{count} albums}}'**
  String albumsCount(int count);

  /// Label of the only sort of the Albums view (FR-020.1).
  ///
  /// In en, this message translates to:
  /// **'Album artist'**
  String get albumsSort;

  /// Title of the tracks without an album tag (BR-010, rule 2).
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get albumUnknown;

  /// Number of tracks of an album or an artist (FR-020, FR-021).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} track} other{{count} tracks}}'**
  String groupTracks(int count);

  /// Number of discs of an album, shown above one (FR-020.9).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} disc} other{{count} discs}}'**
  String albumDiscs(int count);

  /// Said by TalkBack for an album or artist whose disks are absent (FR-020.5).
  ///
  /// In en, this message translates to:
  /// **'{label}, unavailable: {disk} not connected'**
  String albumNotConnected(String label, String disk);

  /// Duration under an hour (FR-020.9).
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// Duration of an hour or more; minutes are padded to two digits (FR-021.8).
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes}'**
  String durationHours(int hours, String minutes);

  /// Button that plays an album in order (FR-022.2).
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get albumPlay;

  /// Button that plays all the tracks of an artist (FR-022.2).
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get artistPlayAll;

  /// Count line of the Artists view (FR-021.1).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} artist} other{{count} artists}} · grouped by album artist'**
  String artistsCount(int count);

  /// Second line of an artist (FR-021.2).
  ///
  /// In en, this message translates to:
  /// **'{albums, plural, one{{albums} album} other{{albums} albums}} · {tracks, plural, one{{tracks} track} other{{tracks} tracks}}'**
  String artistSummary(int albums, int tracks);

  /// Second line of the unknown artist (FR-021.2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} track without tags} other{{count} tracks without tags}}'**
  String artistUnknownSummary(int count);

  /// Second line of an artist whose disks are absent (FR-021.5).
  ///
  /// In en, this message translates to:
  /// **'{summary} · {disk} not connected'**
  String artistNotConnected(String summary, String disk);

  /// Empty state of the Albums view (FR-020.7).
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get groupsEmptyAlbums;

  /// Empty state of the Artists view (FR-021.6).
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get groupsEmptyArtists;

  /// Hint of the empty Albums and Artists views (FR-020.7).
  ///
  /// In en, this message translates to:
  /// **'Choose folders in the Tracks tab.'**
  String get groupsEmptyHint;

  /// Origin of a queue started from an album (FR-022.6).
  ///
  /// In en, this message translates to:
  /// **'Album · {title}'**
  String queueOriginAlbum(String title);

  /// Origin of a queue started from an artist (FR-022.6).
  ///
  /// In en, this message translates to:
  /// **'Artist · {name}'**
  String queueOriginArtist(String name);

  /// Shown when the album of an open detail disappears (FR-020.8).
  ///
  /// In en, this message translates to:
  /// **'This album is no longer in the library.'**
  String get groupNotFound;

  /// Shown when the artist of an open detail disappears (FR-021.7).
  ///
  /// In en, this message translates to:
  /// **'This artist is no longer in the library.'**
  String get artistNotFound;

  /// Said by TalkBack for a letter of the index of albums and artists (FR-020.6).
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}, {items}'**
  String indexLetterItems(String letter, String items);

  /// Count in the bubble of the index of artists (FR-021.4).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} artist} other{{count} artists}}'**
  String artistsCountShort(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
