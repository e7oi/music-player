# HOWTO — TuneShell

Procédures pratiques. Ajouter une section à chaque nouvelle procédure validée.

---

## 1. Préparer l'environnement de développement

**Commun**
- Installer le [SDK Flutter](https://docs.flutter.dev/get-started/install) et vérifier avec `flutter doctor`.

**Android**
- Android Studio + SDK Android + un appareil réel (recommandé pour tester l'audio en arrière-plan) ou un émulateur.

**Windows 11**
- Visual Studio 2022 avec la charge de travail « Développement Desktop en C++ ».
- Activer la cible : `flutter config --enable-windows-desktop`

**macOS**
- Un Mac avec Xcode et CocoaPods est requis pour compiler et signer (ou un runner CI macOS).
- Activer la cible : `flutter config --enable-macos-desktop`

---

## 2. Créer le projet

Le projet de production est un seul package Flutter **à la racine du dépôt** (ADR-001, MPL-017) ; il a été créé avec :

```bash
flutter create --org net.trtl3 --platforms=android --project-name musicplayer <dossier temporaire>
```

(nom de travail de l'époque ; paquet renommé `tuneshell` par MPL-039, ADR-007), puis seuls `android/` et `.metadata` ont été repris à la racine. Les commandes se lancent depuis la racine du dépôt :

```bash
flutter --version      # doit afficher la version épinglée dans pubspec.yaml (environment.flutter)
flutter pub get --enforce-lockfile
flutter gen-l10n       # après toute modification des fichiers ARB de lib/l10n/
```

Avant un commit : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test`. `dart analyze` exécute en plus le plugin `riverpod_lint`, que `flutter analyze` ignore.

> L'identifiant d'organisation `net.trtl3` est acté (D7). Il est difficile à changer après publication. L'identifiant Android est `net.trtl3.tuneshell` depuis MPL-039 (ADR-007) : TuneShell s'installe à côté de l'ancienne application `net.trtl3.musicplayer` et du prototype, qu'il faut désinstaller à part (`adb uninstall net.trtl3.musicplayer`).

---

## 3. Lancer l'application

```bash
flutter run -d windows
flutter run -d macos
flutter run -d <id_appareil_android>   # liste : flutter devices
```

---

## 4. Valider le prototype audio (MPL — Épique « Lecture locale »)

Sur chacune des 3 plateformes :
1. Sélectionner un fichier local (MP3 et FLAC au minimum).
2. Lire, mettre en pause, déplacer le curseur (seek).
3. Redémarrer l'app et vérifier que le dossier choisi reste accessible.
4. Sur Android : mettre l'app en arrière-plan et écran verrouillé, **téléphone débranché**, vérifier que la lecture continue.
5. Sur macOS : vérifier les entitlements si l'accès disque échoue sans erreur visible.

Consigner le résultat réel (OK / KO + détails) avant toute fermeture d'item au backlog.

---

## 5. Environnement testé pour MPL-002 (macOS, Android)

Versions réellement utilisées : Flutter 3.47.6 / Dart 3.13.5, JDK 17, Android SDK 36 (build-tools 36.0.0, NDK 28.2).

```bash
brew install --cask flutter
brew install openjdk@17 cocoapods
brew install --cask android-commandlinetools
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"
flutter config --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME"
flutter doctor
```

Pièges rencontrés :
- Le build Android télécharge `libmpv` depuis github.com (réseau requis au build, pas à l'exécution).
- `permission_handler` 13 est incompatible avec l'AGP actuel (exige `compileSdk 37`) : la permission audio est gérée en natif.
- macOS : Xcode complet requis (les Command Line Tools ne suffisent pas).
- Windows : activer le mode développeur (symlinks des plugins).

Fichiers de test audio (7 formats, 20 s, générés localement, non versionnés) : `./tools/gen_test_audio.sh`.
Protocole de test réel par plateforme : voir §8.

---

## 6. Valider en build release

Toujours valider un item en build release (`flutter run --release`) avant de le fermer : le build debug masque des défauts propres à la réduction des ressources.

- Tout test d'arrière-plan se fait **téléphone débranché**.
- Écrire « non testé » plutôt que « OK » quand ce n'est pas vérifié.
- Un item ne se ferme qu'après confirmation explicite de l'utilisateur.

---

## 7. Compiler et installer une build release (Android)

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Variante directe : `flutter run --release -d <id_appareil_android>` (`flutter devices` donne l'id).

Vérifier les permissions de l'APK (la build release ne doit pas déclarer `INTERNET` ; `ACCESS_NETWORK_STATE`, ajoutée par une dépendance, est tolérée) :

```bash
$ANDROID_HOME/build-tools/36.0.0/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Note : la build release est actuellement signée avec la clé debug (TODO dans `android/app/build.gradle.kts`). Le keystore de production ne sera **jamais** commité.

---

## 8. Protocole de test réel et Auto-test

Préparation (une fois) :
```bash
brew install lame flac opus-tools vorbis-tools        # macOS uniquement, pour générer les fichiers
./tools/gen_test_audio.sh                             # crée test-audio/ (7 fichiers de 20 s)
```
Sous Windows, copier simplement `test-audio/` depuis le Mac sur la machine, ou utiliser ses propres fichiers.

**Règles de l'Auto-test**
- Avant de lancer l'Auto-test : **vider la recherche et ne sélectionner aucun format** (aucun filtre actif = tous les formats). L'échantillon est tiré de la liste filtrée, à raison de 1 à 2 pistes par format, 20 au plus.
- Tester **chaque moteur** (sélecteur `just_audio` / `media_kit` en haut de l'écran principal).
- **Ne pas toucher à l'app pendant le test** : le harnais verrouille le lecteur.
- Build release, téléphone débranché.
- Le WMA est attendu en échec avec `just_audio` (D16, accepté).

**Accès à l'Auto-test :** écran principal → icône « Tests et journal » (fiole) → onglet « Résultats » → boutons **Auto-test échantillon**, **Tout (N)** (liste filtrée, avec confirmation et durée estimée), **Rejouer les échecs (k)**, **Arrêter**, **Config moteur**. Résultats exportables par **Copier**, **.txt**, **.csv** ; onglet « Journal » pour le journal d'événements.

### Android — Pixel 10 Pro
1. Copier `test-audio/*` dans `Musique/` du téléphone (câble USB) ; ouvrir une appli musicale ou attendre l'indexation.
2. `cd musicplayer && flutter run --release -d <id>` (`flutter devices` donne l'id).
3. Appuyer sur **Scanner MediaStore**, accepter la permission → 7 pistes attendues.
4. Pour chaque moteur : lancer l'**Auto-test échantillon** (voir les règles ci-dessus) et lire le journal. Écouter chaque piste : la tonalité monte toutes les 5 s ; les boutons Début / Milieu / Fin −2 s doivent la déplacer audiblement.
5. **Redémarrage** : fermer complètement l'app, la rouvrir → « accès restauré sans nouvelle sélection ».
6. **Arrière-plan** : lancer une piste, écran verrouillé 10 min (ou playlist de 7 pistes), **téléphone débranché** → la lecture doit continuer ; `media_kit` en particulier.
7. **Contrôles** : depuis l'écran de verrouillage / la notification : pause, reprise, suivant, précédent, glisser la barre de seek.

### Windows 11 *(en pause)*
1. `flutter config --enable-windows-desktop`, Visual Studio 2022 (C++), mode développeur activé.
2. `cd musicplayer && flutter run -d windows`.
3. **Choisir un dossier** (idéalement sur un **disque USB/externe**) → pistes listées.
4. Auto-test pour chaque moteur ; noter les formats KO (OGG/OPUS en particulier avec `just_audio`).
5. Fermer / rouvrir : le dossier doit être restauré. Débrancher le disque : un message d'erreur clair doit s'afficher, pas un plantage.
6. Vérifier le réseau : `tools/check_libmpv_license.sh musicplayer/build/windows/x64/runner/Release` (Git Bash) pour la licence ; capture réseau/pare-feu pendant la lecture pour confirmer **aucune** requête sortante.

### macOS *(en pause)*
1. Installer Xcode complet (App Store), puis :
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
2. `cd musicplayer && flutter run -d macos`.
3. **Choisir un dossier** (idéalement sur un disque externe) → pistes listées ; l'app est sandboxée (entitlements : `docs/sprints/sprint-1/RESULTS.md` §8).
4. Auto-test pour chaque moteur ; noter si `just_audio` échoue sur OGG/OPUS (hypothèse : `docs/sprints/sprint-1/RESULTS.md` §2.3).
5. **Quitter complètement (⌘Q) et relancer** : « accès restauré » attendu. Si le message « ÉCHEC accès … » s'affiche, c'est le problème de bookmark/entitlement (jamais silencieux par conception).
6. Touches média du clavier / Centre de contrôle : `audio_service` doit afficher la piste et réagir.
7. Licence : `tools/check_libmpv_license.sh musicplayer/build/macos/Build/Products/Release/musicplayer.app` (build `flutter build macos --release`).

Consigner les résultats (OK / KO / non testé, voir §6) et signaler les échecs.

---

## 9. Flux Git et contrôles avant merge

- **Branches de travail :** push libre ; un correctif = un commit annulable.
- **`main` :** protégée, uniquement par pull request avec contrôles au vert (D17). Jamais de push direct.
- **Contrôles requis** *(mise en place progressive : CI documentaire MPL-024 **en place** — workflow `docs-ci`, jobs `markdown-lint`, `links`, `secrets`, `repo-checks`, voir `.github/workflows/docs-ci.yml` ; ruleset `protect-main` actif depuis le 08/10/2026 : PR obligatoire, contrôles `markdown-lint`, `links`, `secrets`, `repo-checks`, push forcé et suppression bloqués ; CI code minimale en place depuis MPL-017 — workflow `code-ci`, job `code-checks` (format, traductions à jour, analyse, tests), contrôle requis de `protect-main` ; MPL-026 la complète)* :
  1. `dart format --set-exit-if-changed .`
  2. `flutter analyze` sans avertissement
  3. `flutter test`
  4. Détection de secrets (`gitleaks`)
  5. Vulnérabilités et licences des dépendances
  6. Liste blanche des permissions du manifest de la build release
  7. Documentation à jour
- **Tests fonctionnels :** sur appareil réel, en build release (§6), avant la fermeture d'un item.
- **Snapshots de sprint :** dans `docs/sprints/`.
- **Méthodologies :** dans le dépôt privé `ai-tools`, hors de ce dépôt.

---

## 10. Tester le contrat du moteur audio sur appareil (MPL-017)

La suite `test/contract/audio_engine_contract.dart` tourne en CI contre le fake ; sur appareil, elle tourne contre l'adaptateur `media_kit`. Le test génère lui-même un fichier WAV d'une seconde et un fichier illisible : aucun fichier personnel n'est nécessaire (D27).

1. Brancher le Pixel (ou `adb connect` en Wi-Fi) ; `ANDROID_SERIAL=<id>` s'il y a plusieurs appareils (`flutter devices`).
2. Depuis la racine du dépôt, en mode profile, compilé en natif (AOT) comme la release. `flutter drive` refuse la release (« Flutter Driver (non-web) does not support running in release mode ») et `flutter test integration_test` ne compile qu'en debug. Le lancement de l'application elle-même se valide à part, en build release (D14, §7).

   ```bash
   flutter drive --profile --driver=test_driver/integration_test.dart \
     --target=integration_test/media_kit_audio_engine_test.dart
   ```

   Avec plusieurs appareils, ajouter `-d <id>` (`flutter devices`).

   L'application de test remplace l'application installée.
3. Résultat attendu : `All tests passed.` (8 tests dont 2 ignorés : descripteurs, couverts par MPL-035).
4. Consigner le résultat (OK / KO + sortie) ; ne rien coller de plus que la sortie du test.

---

## 11. Tester la bibliothèque du stockage interne (MPL-018)

Build release (D14), Pixel branché ou en Wi-Fi, quelques fichiers audio dans `Music/` et au moins un autre dossier qui contient de la musique (par exemple un MP3 copié dans `Download/`). Les sonneries ne comptent pas : MediaStore ne les marque pas comme musique.

1. Désinstaller l'application pour repartir d'un premier lancement : `adb uninstall net.trtl3.tuneshell`. Cela efface aussi la bibliothèque enregistrée.
2. `flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk`, puis ouvrir l'application.
3. **Autorisation refusée :** refuser l'accès. Attendu : message d'explication et bouton « Autoriser l'accès ». Le toucher, refuser encore. Attendu : le bouton devient « Ouvrir les réglages » ; le toucher montre d'abord la demande d'Android si elle s'affiche encore, sinon la fiche de l'application. Fermer puis rouvrir l'application : elle ne redemande pas l'accès d'elle-même.
4. **Autorisation accordée :** l'accorder dans les réglages et revenir. Attendu : la liste des dossiers, avec `Music` coché et le nombre de fichiers de chacun.
5. **Indexation :** valider. Attendu : seules les pistes des dossiers cochés apparaissent, sans blocage de l'écran.
6. **Lecture :** toucher une piste. Attendu : la lecture démarre ; la barre du bas montre la piste ; pause, suivante et précédente fonctionnent.
7. **Ajout :** copier un fichier dans `Music/`, attendre quelques secondes (indexation de MediaStore), toucher « Actualiser ». Attendu : la piste apparaît. Sans recherche dans la liste, utiliser un fichier dont le nom se classe en tête (par exemple `000-test.wav`). Un fichier copié par `adb push` n'est marqué comme musique qu'après une analyse : `adb shell content call --uri content://media --method scan_file --arg /storage/emulated/0/Music/000-test.wav`.
8. **Suppression :** supprimer ce fichier, toucher « Actualiser ». Attendu : la piste disparaît.
9. **Dossiers :** toucher « Dossiers », cocher un autre dossier, valider. Attendu : ses pistes apparaissent ; le décocher : elles disparaissent.
10. **Retrait de l'autorisation :** la retirer dans les réglages, revenir dans l'application. Android redémarre alors l'application. Attendu : le message d'explication, sans nouvelle demande automatique ; une fois l'accès rendu, la bibliothèque est intacte.
11. **Retour arrière pendant la lecture :** lancer une piste, faire le geste de retour (ou la touche), attendre quelques secondes, rouvrir l'application. Attendu : pas de plantage, la lecture a continué, la barre montre la piste et une seule piste joue ; recommencer deux fois, puis changer de piste. Sans service au premier plan (MPL-036), Android peut arrêter l'application en arrière-plan : la lecture s'arrête alors, sans plantage. Compter les sorties audio : `adb shell dumpsys audio | grep 'u/pid:<uid>/' | grep -c state:started`.

Consigner le résultat (OK / KO + détails) de chaque étape, sans titre de piste ni nom de fichier (D27).


## 12. Tester la lecture en arrière-plan et les contrôles du système (MPL-036)

Build release (D14), installée par-dessus la précédente (`adb install -r`), bibliothèque déjà indexée. Téléphone **débranché** pour les étapes 2 et 9 (`adb` en Wi-Fi si besoin). Un casque Bluetooth et un second téléphone pour l'appel.

1. **Notification :** lancer une piste. Attendu : notification « Lecture » avec titre, artiste ou album, précédent, pause, suivant, arrêt et barre de progression ; même lecteur dans les réglages rapides.
2. **Écran verrouillé :** verrouiller le téléphone 15 minutes. Attendu : la lecture continue et enchaîne les pistes ; l'écran verrouillé montre la piste et ses commandes, qui fonctionnent.
3. **Commandes du système :** depuis la notification, toucher suivant, précédent (avant puis après 3 s de lecture), pause, lecture, et déplacer la barre de progression. Attendu : l'écran de l'application suit (FR-001).
4. **Touches média :** avec le casque Bluetooth, lecture/pause, piste suivante, piste précédente. Attendu : comme à l'étape 3.
5. **Appel :** application en arrière-plan et écran verrouillé, se faire appeler pendant la lecture, décrocher, parler plus d'une minute, raccrocher sans rien toucher. Attendu : pause pendant l'appel, reprise à la fin, notification toujours là ; aucune `ForegroundServiceStartNotAllowedException` dans `adb logcat`. Recommencer en touchant « lecture » deux fois dans la notification pendant l'appel (l'application est déjà en pause : la notification n'offre pas « pause ») : la musique ne joue pas par-dessus l'appel et ne reprend pas au raccrochage (BR-005, règles 1 et 3). Puis, application en arrière-plan, toucher « lecture » dans la notification : la lecture repart et `dumpsys activity services <paquet>` montre `isForeground=true`.
6. **Autre application :** lancer une vidéo ou une autre application de musique. Attendu : pause, sans reprise à la fermeture de l'autre application.
7. **Atténuation :** lancer un guidage GPS (Google Maps) pendant la lecture. Attendu : le volume baisse pendant l'annonce, la lecture continue (BR-005, règle 4). Si le volume ne baisse pas, le noter : la règle 4 devient une ligne « À valider ».
8. **Casque :** débrancher ou déconnecter le casque pendant la lecture. Attendu : pause, sans reprise au rebranchement.
9. **Fermeture :** pendant la lecture, geste de retour, puis retirer l'application des applications récentes. Attendu : la lecture continue, la notification reste ; la toucher rouvre l'application sur la piste en cours. Mettre en pause, retirer encore l'application des récentes : la notification disparaît.
10. **Arrêt :** relancer une piste, toucher arrêt dans la notification. Attendu : la lecture s'arrête et la notification disparaît. Laisser la file arriver à sa fin : même résultat. Puis : lancer une piste, geste de retour, toucher arrêt dans la notification, attendre 10 s, rouvrir l'application. Attendu : l'application redémarre normalement ; aucun `Fatal signal` dans `adb logcat`.
11. **Changement de piste :** pendant la lecture, toucher une autre piste dans la liste. Attendu : la notification et l'écran verrouillé changent de piste sans disparaître ni clignoter.
12. **Touche média à froid :** mettre en pause, retirer l'application des récentes, attendre que le processus ait disparu (`adb shell pidof net.trtl3.tuneshell` vide), puis appuyer sur lecture du casque Bluetooth. Attendu : rien ne joue (la file n'est pas conservée) et aucun message « l'application s'est arrêtée » ; noter toute `ForegroundServiceDidNotStartInTimeException` dans `adb logcat`. Si le processus reste en cache après le retrait des récentes, le terminer avec `adb shell am kill net.trtl3.tuneshell` ; fermer d'abord toute autre application dont la session média est active (`dumpsys media_session`, « Sessions Stack » vide), sinon elle reçoit la touche. Puis ouvrir l'application depuis son icône sans la tuer. Attendu : la bibliothèque s'affiche (pas d'écran de chargement bloqué) et une piste se lance ; aucune `MissingPluginException` dans `adb logcat`.

Consigner le résultat (OK / KO + détails) de chaque étape, sans titre de piste ni nom de fichier (D27). Vérifications par adb : `dumpsys activity services <paquet>` (`isForeground=true`, type `0x2`), `dumpsys media_session` (état de la session), `dumpsys audio` (« Audio Focus stack »).
