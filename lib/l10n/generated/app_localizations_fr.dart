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
  String get foldersTitle => 'Dossiers de musique';

  @override
  String get foldersRoot => 'Racine du stockage';

  @override
  String get foldersConfirm => 'Valider';

  @override
  String get libraryRefresh => 'Actualiser';

  @override
  String get libraryFolders => 'Dossiers';

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

  @override
  String get welcomeGreeting => 'Bienvenue dans';

  @override
  String get welcomeTagline => 'Ta musique, chez toi.';

  @override
  String get welcomePromiseRead =>
      'Lit les fichiers déjà présents sur ton téléphone et tes disques.';

  @override
  String get welcomePromiseNoAccount => 'Aucun compte, aucune publicité.';

  @override
  String get welcomePromiseNoData =>
      'Aucune donnée envoyée : tout reste sur l\'appareil.';

  @override
  String get welcomeStart => 'Commencer';

  @override
  String get welcomeFooter => 'Libre et gratuit · Code source ouvert';

  @override
  String stepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get accessTitle => 'Autoriser l\'accès à ta musique';

  @override
  String get accessBody =>
      'TuneShell a besoin de lire les fichiers audio de ce téléphone pour construire ta bibliothèque.';

  @override
  String get accessGuaranteeReadOnly =>
      'Lecture seule : rien n\'est modifié ni supprimé';

  @override
  String get accessGuaranteeLocal => 'Rien ne quitte ton téléphone';

  @override
  String get accessAllow => 'Autoriser l\'accès';

  @override
  String get accessRetry => 'Réessayer';

  @override
  String get accessNotNow => 'Pas maintenant';

  @override
  String get accessRefused =>
      'Accès refusé. Sans lui, TuneShell ne peut pas trouver ta musique.';

  @override
  String get blockedTitle => 'L\'accès est bloqué';

  @override
  String get blockedBody =>
      'Android ne permet plus de redemander l\'autorisation. Tu peux l\'activer dans les réglages de l\'app :';

  @override
  String get blockedStepSettings => 'Ouvrir les réglages de TuneShell';

  @override
  String get blockedStepPermissions => 'Autorisations';

  @override
  String get blockedStepMusic => 'Musique et audio';

  @override
  String get blockedStepAllow => 'Autoriser';

  @override
  String get blockedOpenSettings => 'Ouvrir les réglages';

  @override
  String get blockedChooseFolder => 'Choisir un dossier à la place';

  @override
  String get blockedNote =>
      'Le choix d\'un dossier d\'un disque amovible fonctionne sans cette autorisation.';

  @override
  String get declinedTitle => 'Accès à ta musique non accordé';

  @override
  String get declinedBody =>
      'TuneShell ne peut pas lire tes fichiers audio sans ton autorisation.';

  @override
  String get foldersIntro =>
      'TuneShell cherche ta musique dans les dossiers cochés. Tu pourras changer ce choix plus tard.';

  @override
  String get foldersSection => 'Stockage interne';

  @override
  String folderAudioCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fichiers audio',
      one: '$countString fichier audio',
    );
    return '$_temp0';
  }

  @override
  String get foldersAdd => 'Ajouter un dossier';

  @override
  String foldersSummary(int folders, int files) {
    final intl.NumberFormat filesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String filesString = filesNumberFormat.format(files);

    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders dossiers',
      one: '$folders dossier',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$filesString fichiers',
      one: '$filesString fichier',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String foldersCounting(int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders dossiers',
      one: '$folders dossier',
    );
    return '$_temp0 · comptage…';
  }

  @override
  String get foldersContinue => 'Continuer';

  @override
  String get foldersNoneChecked => 'Coche au moins un dossier pour continuer.';

  @override
  String get foldersEmptyTitle => 'Aucun fichier audio trouvé';

  @override
  String get foldersEmptyBody =>
      'Aucun dossier de ce téléphone ne contient de musique. Ajoute un dossier ou branche un disque.';

  @override
  String get foldersNothingToAdd => 'Aucun dossier à ajouter.';

  @override
  String get foldersReadFailed => 'Les dossiers n\'ont pas pu être lus.';

  @override
  String get playerOpen => 'Ouvrir le lecteur';

  @override
  String playerStoppedLost(String disk) {
    return 'Arrêt : $disk débranché';
  }

  @override
  String get playerCollapse => 'Réduire';

  @override
  String get playerPlayingFrom => 'Lecture depuis';

  @override
  String get playerFavoriteSoon => 'Favoris (bientôt)';

  @override
  String get playerShuffle => 'Aléatoire';

  @override
  String get playerRepeat => 'Répéter';

  @override
  String get playerModeOn => 'activé';

  @override
  String get playerModeOff => 'désactivé';

  @override
  String get playerRepeatAll => 'toutes les pistes';

  @override
  String get playerRepeatOne => 'une piste';

  @override
  String get playerSeek => 'Position';

  @override
  String playerPositionValue(String position, String total) {
    return '$position sur $total';
  }

  @override
  String playerUpNext(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'À suivre · $countString pistes',
      one: 'À suivre · $countString piste',
      zero: 'À suivre · aucune piste',
    );
    return '$_temp0';
  }

  @override
  String playerDiscNumber(int number) {
    return 'Disque $number';
  }

  @override
  String playerTrackNumber(int number) {
    return 'Piste $number';
  }

  @override
  String playerStoppedBanner(String disk) {
    return 'Lecture arrêtée : $disk débranché';
  }

  @override
  String get queueTitle => 'File d\'attente';

  @override
  String queueSummary(int count, String duration) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pistes',
      one: '$countString piste',
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
      other: '$countString pistes',
      one: '$countString piste',
    );
    return '$_temp0 · $duration · aléatoire';
  }

  @override
  String get queueClear => 'Vider la suite';

  @override
  String get queueNow => 'En cours';

  @override
  String get queueNext => 'À suivre';

  @override
  String queueMove(String title) {
    return 'Déplacer $title';
  }

  @override
  String queueWillSkip(String artist) {
    return '$artist · non connecté, sera ignorée';
  }

  @override
  String get queueRemove => 'Retirer de la file';

  @override
  String queueRemoved(String title) {
    return '$title retirée de la file';
  }

  @override
  String get menuPlayNext => 'Lire ensuite';

  @override
  String get menuAddToQueue => 'Ajouter à la file';

  @override
  String menuPlayNextDone(String title) {
    return 'Lecture ensuite : $title';
  }

  @override
  String menuAddedDone(String title) {
    return 'Ajouté à la file : $title';
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
  String get albumsSort => 'Artiste de l\'album';

  @override
  String get albumUnknown => 'Album inconnu';

  @override
  String groupTracks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pistes',
      one: '$countString piste',
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
      other: '$countString disques',
      one: '$countString disque',
    );
    return '$_temp0';
  }

  @override
  String albumNotConnected(String label, String disk) {
    return '$label, indisponible : $disk non connecté';
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
  String get albumPlay => 'Lire';

  @override
  String get artistPlayAll => 'Tout lire';

  @override
  String artistsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString artistes',
      one: '$countString artiste',
    );
    return '$_temp0 · regroupés par artiste de l\'album';
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
      other: '$tracks pistes',
      one: '$tracks piste',
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
      other: '$countString pistes sans étiquette',
      one: '$countString piste sans étiquette',
    );
    return '$_temp0';
  }

  @override
  String artistNotConnected(String summary, String disk) {
    return '$summary · $disk non connecté';
  }

  @override
  String get groupsEmptyAlbums => 'Aucun album';

  @override
  String get groupsEmptyArtists => 'Aucun artiste';

  @override
  String get groupsEmptyHint => 'Choisis des dossiers dans l\'onglet Pistes.';

  @override
  String queueOriginAlbum(String title) {
    return 'Album · $title';
  }

  @override
  String queueOriginArtist(String name) {
    return 'Artiste · $name';
  }

  @override
  String get groupNotFound => 'Cet album n\'est plus dans la bibliothèque.';

  @override
  String get artistNotFound => 'Cet artiste n\'est plus dans la bibliothèque.';

  @override
  String indexLetterItems(String letter, String items) {
    return 'Lettre $letter, $items';
  }

  @override
  String artistsCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString artistes',
      one: '$countString artiste',
    );
    return '$_temp0';
  }
}
