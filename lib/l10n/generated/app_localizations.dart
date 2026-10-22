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
  /// **'MusicPlayer'**
  String get appTitle;

  /// Shown instead of the library when the audio permission is refused (FR-004).
  ///
  /// In en, this message translates to:
  /// **'Access to the audio files is needed to show and play the music on this phone.'**
  String get permissionExplanation;

  /// Button that asks for the audio permission again.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get permissionRetry;

  /// Button that opens the app settings when Android no longer shows the permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionOpenSettings;

  /// Title of the folder choice screen (FR-003).
  ///
  /// In en, this message translates to:
  /// **'Music folders'**
  String get foldersTitle;

  /// Explains the folder choice.
  ///
  /// In en, this message translates to:
  /// **'Choose the folders that hold your music. Ringtones and audio from messaging apps stay out unless their folder is checked.'**
  String get foldersExplanation;

  /// Name shown for audio files placed directly at the root of the internal storage.
  ///
  /// In en, this message translates to:
  /// **'Storage root'**
  String get foldersRoot;

  /// Number of audio files in a folder.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String folderFileCount(int count);

  /// Confirms the folder choice and starts indexing.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get foldersConfirm;

  /// Folder choice when MediaStore finds no audio.
  ///
  /// In en, this message translates to:
  /// **'No folder of this phone holds audio.'**
  String get foldersNone;

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

  /// Empty library because no folder is checked.
  ///
  /// In en, this message translates to:
  /// **'No folder chosen.'**
  String get libraryNoFolders;

  /// Empty library after indexing the chosen folders.
  ///
  /// In en, this message translates to:
  /// **'No track found in the chosen folders.'**
  String get libraryEmpty;

  /// Button to the folder choice from an empty library.
  ///
  /// In en, this message translates to:
  /// **'Choose folders'**
  String get libraryChooseFolders;

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
  /// **'Cannot play {title}'**
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

  /// Shown when MediaStore cannot be queried.
  ///
  /// In en, this message translates to:
  /// **'The folders of this phone could not be read.'**
  String get libraryLoadFailed;

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
