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

> L'identifiant d'organisation `net.trtl3` est acté (D7). Il est difficile à changer après publication. L'identifiant Android est `net.trtl3.tuneshell` depuis MPL-039 (ADR-007) : TuneShell s'installe à côté de l'ancienne application `net.trtl3.musicplayer` (identifiant partagé par le prototype et les builds d'avant MPL-039), à désinstaller à part (`adb uninstall net.trtl3.musicplayer`).

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

## 13. Tester la bibliothèque d'un disque amovible, les tags et les pochettes (MPL-037)

Build release (D14), installée par-dessus la précédente (`adb install -r`). Un SSD USB-C formaté en exFAT, `adb` en Wi-Fi puisque le port USB-C est pris (`ANDROID_SERIAL` s'il y a plusieurs appareils). Aucun titre de piste, nom de fichier, chemin ni identifiant de volume dans le dépôt ni dans les comptes rendus (D27) : les exports restent hors du dépôt.

**Jeu d'essai synthétique.** Générer le jeu hors du dépôt, avec `ffmpeg`, puis le copier sur le SSD. Les fichiers contiennent des tags et une pochette fabriqués, jamais de musique personnelle :

```bash
mkdir -p ~/tuneshell-fixtures && cd ~/tuneshell-fixtures
ffmpeg -f lavfi -i "color=c=red:s=600x600:d=1" -frames:v 1 cover-a.png
ffmpeg -f lavfi -i "color=c=blue:s=300x300:d=1" -frames:v 1 cover-b.png
for i in $(seq 1 200); do
  cover=cover-a.png; [ $((i % 2)) -eq 0 ] && cover=cover-b.png
  ffmpeg -loglevel error -f lavfi -i "sine=frequency=$((200 + i)):duration=3" -i "$cover" \
    -map 0 -map 1 -c:a libmp3lame -c:v mjpeg -id3v2_version 3 \
    -metadata title="Fixture $i" -metadata artist="Artist $((i % 20))" \
    -metadata album="Album $((i % 10))" -metadata track="$i" "base-$i.mp3"
done
```

Pour le test à 10 000 pistes, copier chacun des 200 fichiers 50 fois, sous des noms différents, dans 100 sous-dossiers du SSD (`TuneShellTest/d00` à `d99`). Pour les cas particuliers, ajouter dans un dossier à part : un fichier `._x.mp3`, un sous-dossier `.cache` avec un MP3, un sous-dossier avec un fichier `.nomedia`, un fichier MP3 vide (illisible), un MP3 sans tags ni pochette.

**Mesures à consigner pendant le test (ADR-008, ADR-009).** Elles n'ont pas été faites avant la livraison de MPL-037 : le code suppose que l'UUID se déduit du dossier choisi et que 2 lectures en parallèle conviennent.

- **Étape 0, UUID du volume :** avec le SSD branché, `adb shell sm list-volumes all` donne le volume public et son UUID (ne pas le consigner dans le dépôt, D27). Après l'étape 1, vérifier que le disque s'affiche avec le nom du volume, qu'il passe « Non connecté » quand on le débranche, et qu'une piste se lit ; si le SSD ne se laisse pas identifier, arrêter et revenir à `/cadrer` (ADR-008).
- **Étape 0b, débit des tags :** noter le temps de lecture des tags de 1 000 pistes avec 1, 2 et 4 lectures en parallèle (`parallelism` de `TagIndexer`, changé le temps de la mesure sur un build de mesure), puis l'effet sur une lecture en cours. La plus petite valeur qui tient le débit visé devient la limite de BR-006.4 ; si ce n'est pas 2, changer la valeur par défaut. Consigner chiffres et choix dans ADR-009.

**Étapes.**

1. **Ajout d'un dossier :** ouvrir l'écran des disques (icône USB), « Ajouter un dossier », choisir `TuneShellTest/d00` dans le sélecteur d'Android, accorder l'accès. Attendu : le disque apparaît avec le nom du volume, « Connecté » ; ses pistes apparaissent tout de suite avec le nom de fichier comme titre, sans attendre les tags (FR-006.7). Choisir un dossier du téléphone : message « Ce dossier est dans le stockage du téléphone… ».
2. **Droit conservé :** arrêt forcé de l'application, puis redémarrage du téléphone, SSD branché. Attendu : les pistes du SSD sont disponibles sans nouveau choix de dossier.
3. **Tags et pochettes :** observer la bande de progression « Lecture des étiquettes : x / y ». Attendu : titres, artistes et pochettes remplacent peu à peu les noms de fichiers ; l'écran reste fluide ; lancer une piste du SSD pendant la lecture des tags ne la coupe pas ; deux pistes du même album n'enregistrent qu'une image (compter les fichiers : `adb shell run-as` est impossible en release, compter sur une build debug ou s'en tenir à la taille du dossier de données dans les réglages d'Android).
4. **Lecture et enchaînement :** lancer une piste du SSD, enchaîner dix pistes, écran verrouillé, application en arrière-plan. Attendu : lecture normale ; notification et écran verrouillé affichent le titre ; aucun message d'erreur.
5. **Descripteurs (build debug) :** sur une build **debug**, `adb shell run-as net.trtl3.tuneshell ls -l /proc/self/fd` n'est pas utilisable (il liste le processus de `ls`) ; utiliser `PID=$(adb shell pidof net.trtl3.tuneshell); adb shell "run-as net.trtl3.tuneshell sh -c 'ls -l /proc/$PID/fd'"` (les guillemets imbriqués sont indispensables : sans eux `sh -c` ne reçoit que `ls`) et compter les lignes qui pointent vers un fichier du volume (le nom du fichier en cours y apparaît). Attendu : le nombre revient à son niveau de départ après dix pistes enchaînées puis un arrêt (BR-006.2). Ce comptage n'est possible qu'en build debug : il ne remplace pas le test en release des autres étapes.
6. **Disque absent :** retirer le SSD, ouvrir l'application. Attendu : ses pistes sont grisées et restent dans la bibliothèque ; l'écran des disques indique « Non connecté » ; une file qui les rencontre les saute avec un message (BR-001). Rebrancher, revenir dans l'application. Attendu : les pistes sont de nouveau disponibles sans nouveau choix de dossier.
7. **Accès à renouveler :** Android ne retire pas un droit de dossier sans action de l'utilisateur, et effacer les données de l'application efface aussi la base : pas de moyen simple de le provoquer. Noter « non testé » pour FR-006.11 (la logique est couverte par les tests automatisés) sauf si un moyen apparaît.
8. **Fichiers ignorés :** choisir le dossier des cas particuliers. Attendu : ni `._x.mp3`, ni le sous-dossier caché, ni le dossier à `.nomedia` ; le MP3 vide est listé (nom de fichier) et lisible par le moteur uniquement s'il l'est, sinon la lecture signale l'échec (BR-003) ; le MP3 sans tags garde son nom de fichier et l'image de remplacement.
9. **Actualiser :** ajouter, supprimer et modifier un fichier sur le SSD, toucher « Actualiser ». Attendu : la piste ajoutée apparaît, la supprimée disparaît, la modifiée est relue ; les autres gardent leur identité.
10. **Parcours coupé :** débrancher le SSD pendant l'actualisation. Attendu : un message signale l'échec et la bibliothèque est gardée. Sans MPL-035, Android peut tuer l'application à ce moment (ADR-008) : le noter ; le parcours reprend au lancement suivant.
11. **Lecture des tags reprise :** avec une lecture de tags en cours (10 000 pistes), fermer l'application puis la rouvrir. Attendu : seules les pistes encore en attente sont lues.
12. **Décocher un dossier :** avec deux dossiers du SSD, retirer l'un. Attendu : ses pistes disparaissent, l'autre reste ; le droit d'accès est libéré (vérifier avec `adb shell dumpsys package net.trtl3.tuneshell`, section des permissions d'URI).
13. **Pochettes du stockage interne :** laisser la lecture se terminer sur le téléphone. Attendu : les pistes du téléphone qui ont une pochette l'affichent dans la liste et la barre de lecture.
14. **10 000 pistes :** ajouter `TuneShellTest` entier. Noter : durée du parcours, durée de la lecture des tags, fluidité du défilement, taille des données de l'application avant et après (pochettes), mémoire (`adb shell dumpsys meminfo net.trtl3.tuneshell`).

Consigner le résultat (OK / KO + détails) de chaque étape, sans titre de piste ni nom de fichier (D27).

## 14. Tester les fondations du design (MPL-016)

Build release (D14) installée par-dessus la précédente (`adb install -r`), bibliothèque déjà indexée, SSD branché pour l'étape 5. La page de démonstration n'existe pas en release : elle se teste avec une build **profile** (étape 7).

1. **Thème :** dans les réglages d'Android, passer du thème clair au thème sombre, application ouverte. Attendu : l'application change de thème sans redémarrer ; titres en Manrope, texte en Inter ; barre de navigation et listes lisibles dans les deux thèmes.
2. **Quatre onglets :** toucher Albums, Artistes, Réglages, puis Pistes. Attendu : Albums et Artistes affichent « Cette vue arrive bientôt. » ; Réglages aussi (en release) ; Pistes retrouve la liste à la même position.
3. **Retour système :** depuis Albums, faire le geste Retour. Attendu : Pistes s'affiche ; un second Retour quitte l'application.
4. **Paysage :** lancer une piste, faire pivoter le téléphone. Attendu : la barre du bas devient un rail à gauche ; la lecture, l'onglet courant et la position de la liste ne changent pas.
5. **Écrans existants :** `HOWTO.md` §12 (étapes 1 et 12) et §13 (étapes 1, 4 et 6). Attendu : bibliothèque, disques et lecture comme avant ; la barre de lecture reste au-dessus de la navigation dans chaque onglet ; une indexation en échec montre un bandeau au-dessus de la liste, jamais par-dessus.
6. **Réseau :** `aapt2 dump permissions app-release.apk`. Attendu : pas de `INTERNET`.
7. **Page de démonstration (profile) :** `flutter build apk --profile`, `adb install -r build/app/outputs/flutter-apk/app-profile.apk`, Réglages › Galerie de composants. Comparer chaque section aux captures (`docs/design/screens/png/composants-clair.jpg` et `-sombre.jpg`) en clair et en sombre : lignes de piste, repères de source, cartes de disque, bandeaux, pochettes, bouton « En cours ».
8. **Index sur 5 000 lignes (profile) :** « Open the 5,000-row list ». Attendu : poignée fine au bord droit ; un défilement normal n'ouvre pas l'index ; un glissé depuis la poignée ouvre la colonne « # A–Z », la lettre sous le doigt grossit avec ses voisines, une bulle indique la lettre et le nombre, la liste suit en temps réel, une vibration légère à chaque lettre, les lettres vides (Q, X, Y) sont grisées et sautées, la colonne disparaît 600 ms après le lâcher. Un toucher sans glisser sur la poignée ouvre la grille « Go to letter » (textes en anglais : la galerie n'est pas traduite). Avec l'interrupteur de la barre, l'index passe à gauche.
9. **Index et geste Retour :** en navigation par gestes, glisser horizontalement depuis le bord droit **sur la poignée** : la page reste ; depuis le bord droit **ailleurs** : Retour s'exécute.
10. **Rotation avec l'index :** ouvrir la liste de 5 000 lignes, faire pivoter le téléphone, puis glisser depuis la poignée à sa nouvelle place. Attendu : l'index répond et le Retour reste exclu sur la poignée (le rectangle d'exclusion suit la rotation).
11. **Fluidité :** faire défiler la liste de 5 000 lignes au doigt et à la volée ; noter toute saccade. `adb shell dumpsys gfxinfo` ne compte pas les images de Flutter : le jugement est visuel (60 i/s visés).
12. **TalkBack :** activer TalkBack ; la poignée de la galerie annonce « Go to letter » (« Aller à la lettre » dans l'application, quand l'index y sera branché) ; ses gestes d'ajustement changent de lettre ; chaque bouton-icône annonce un libellé. Texte agrandi à 200 % : pas de texte coupé dans les onglets et la galerie.

Consigner le résultat (OK / KO + détails) de chaque étape, sans titre de piste ni nom de fichier (D27).
