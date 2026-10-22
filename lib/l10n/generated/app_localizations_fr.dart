// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TuneShell';

  @override
  String get permissionExplanation =>
      'L\'accès aux fichiers audio est nécessaire pour afficher et lire la musique du téléphone.';

  @override
  String get permissionRetry => 'Autoriser l\'accès';

  @override
  String get permissionOpenSettings => 'Ouvrir les réglages';

  @override
  String get foldersTitle => 'Dossiers de musique';

  @override
  String get foldersExplanation =>
      'Choisir les dossiers qui contiennent la musique. Les sonneries et les sons des messageries restent hors de la bibliothèque si leur dossier n\'est pas coché.';

  @override
  String get foldersRoot => 'Racine du stockage';

  @override
  String folderFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String get foldersConfirm => 'Valider';

  @override
  String get foldersNone => 'Aucun dossier du téléphone ne contient d\'audio.';

  @override
  String get libraryRefresh => 'Actualiser';

  @override
  String get libraryFolders => 'Dossiers';

  @override
  String get libraryNoFolders => 'Aucun dossier choisi.';

  @override
  String get libraryEmpty => 'Aucune piste trouvée dans les dossiers choisis.';

  @override
  String get libraryChooseFolders => 'Choisir les dossiers';

  @override
  String get libraryIndexFailed =>
      'L\'actualisation de la bibliothèque a échoué.';

  @override
  String get playerPlay => 'Lecture';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Piste suivante';

  @override
  String get playerPrevious => 'Piste précédente';

  @override
  String noticeTracksSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistes ignorées : disque absent',
      one: '1 piste ignorée : disque absent',
    );
    return '$_temp0';
  }

  @override
  String noticeTrackFailed(String title) {
    return 'Lecture impossible : $title';
  }

  @override
  String noticeStoppedAfterFailures(int count) {
    return 'Lecture arrêtée après $count échecs de suite';
  }

  @override
  String get noticeStoppedByEjection => 'Lecture arrêtée : disque retiré';

  @override
  String get libraryLoadFailed =>
      'Les dossiers du téléphone n\'ont pas pu être lus.';

  @override
  String get libraryRetry => 'Réessayer';

  @override
  String get notificationChannelName => 'Lecture';

  @override
  String get notificationChannelDescription =>
      'Commandes de lecture : précédent, pause, suivant.';
}
