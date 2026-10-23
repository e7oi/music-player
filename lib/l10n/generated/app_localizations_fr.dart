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
    return 'Impossible de lire « $title » : fichier endommagé. Piste suivante lancée.';
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

  @override
  String get libraryDisks => 'Disques amovibles';

  @override
  String get removableTitle => 'Disques amovibles';

  @override
  String get removableNone =>
      'Aucun disque amovible pour l\'instant. Branchez votre disque, puis ajoutez l\'un de ses dossiers.';

  @override
  String get removableAddFolder => 'Ajouter un dossier';

  @override
  String get removableRootFolder => 'Disque entier';

  @override
  String get removableAbsent => 'Non connecté';

  @override
  String get removableAccessLost => 'Accès à renouveler';

  @override
  String get removableAvailable => 'Connecté';

  @override
  String get removableRenew => 'Renouveler l\'accès';

  @override
  String get removableRemoveFolder => 'Retirer ce dossier';

  @override
  String get removableCancel => 'Arrêter';

  @override
  String get removableNoAudio =>
      'Aucun fichier audio n\'a été trouvé dans ce dossier.';

  @override
  String get removableAddFailed =>
      'Le dossier n\'a pas pu être lu. Vérifiez que le disque est branché, puis réessayez.';

  @override
  String get removableNotRemovable =>
      'Ce dossier est dans le stockage du téléphone. Choisissez un dossier du disque amovible.';

  @override
  String get removableRefreshFailed =>
      'Le disque n\'a pas pu être lu. La bibliothèque est restée telle quelle.';

  @override
  String tagsProgress(int done, int total) {
    return 'Lecture des étiquettes : $done / $total';
  }

  @override
  String get navTracks => 'Pistes';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navArtists => 'Artistes';

  @override
  String get navSettings => 'Réglages';

  @override
  String get comingSoon => 'Cette vue arrive bientôt.';

  @override
  String get demoGallery => 'Galerie de composants';

  @override
  String get foldersBack => 'Retour';

  @override
  String get searchSoon => 'Rechercher (bientôt)';

  @override
  String get chipDisks => 'Disques';

  @override
  String disksAbsentBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absents',
      one: '$count absent',
    );
    return '$_temp0';
  }

  @override
  String get libraryScanning => 'Recherche des fichiers audio…';

  @override
  String get libraryCountSearching => 'Recherche en cours…';

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
      other: '$totalString pistes',
      one: '$totalString piste',
    );
    String _temp1 = intl.Intl.pluralLogic(
      unavailable,
      locale: localeName,
      other: ' · $unavailableString indisponibles',
      one: ' · $unavailableString indisponible',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get librarySortTitle => 'Titre A→Z';

  @override
  String bannerAbsentOne(int tracks, String disk) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString pistes ignorées',
      one: '$tracksString piste ignorée',
    );
    return '$_temp0 : $disk absent';
  }

  @override
  String bannerAbsentMany(int tracks, int count) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString pistes ignorées',
      one: '$tracksString piste ignorée',
    );
    return '$_temp0 : $count disques absents';
  }

  @override
  String bannerAccessOne(int tracks, String disk) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString pistes ignorées',
      one: '$tracksString piste ignorée',
    );
    return '$_temp0 : accès à $disk à renouveler';
  }

  @override
  String bannerOther(int tracks, int count) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString pistes ignorées',
      one: '$tracksString piste ignorée',
    );
    return '$_temp0 : $count disques indisponibles';
  }

  @override
  String get bannerSee => 'Voir';

  @override
  String get bannerDismiss => 'Masquer ce message';

  @override
  String get trackUnknownArtist => 'Artiste inconnu';

  @override
  String trackNotConnected(String artist) {
    return '$artist · non connecté';
  }

  @override
  String get trackUnreadable => 'Fichier illisible';

  @override
  String get trackPlaying => 'en lecture';

  @override
  String trackSource(String name) {
    return 'source $name';
  }

  @override
  String get sourceLocal => 'Local';

  @override
  String trackNeedsDisk(String disk) {
    return 'Branche $disk pour lire cette piste';
  }

  @override
  String trackNeedsAccess(String disk) {
    return 'Renouvelle l\'accès à $disk pour lire cette piste';
  }

  @override
  String get emptyLibraryTitle => 'Ta bibliothèque est vide';

  @override
  String get emptyLibraryBody =>
      'Aucun fichier audio dans les dossiers choisis. Ajoute d\'autres dossiers ou actualise.';

  @override
  String get emptyNoFoldersTitle => 'Aucun dossier choisi';

  @override
  String get emptyNoFoldersBody =>
      'Choisis au moins un dossier pour que TuneShell trouve ta musique.';

  @override
  String get chooseFoldersAction => 'Choisir des dossiers';

  @override
  String get jumpCurrent => 'En cours';

  @override
  String get jumpLastPlayed => 'Dernière jouée';

  @override
  String get indexGoToLetter => 'Aller à la lettre';

  @override
  String indexCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString pistes';
  }

  @override
  String indexLetter(String letter, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Lettre $letter, $countString pistes';
  }
}
