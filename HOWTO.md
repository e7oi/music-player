# HOWTO — MusicPlayer

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

```bash
flutter create --org net.trtl3 --platforms=android,windows,macos musicplayer
cd musicplayer
```

> L'identifiant d'organisation `net.trtl3` est acté (D7). Il est difficile à changer après publication.

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
cd musicplayer
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Variante directe : `flutter run --release -d <id_appareil_android>` (`flutter devices` donne l'id).

Vérifier les permissions de l'APK (la build release ne doit pas déclarer `INTERNET` ; `ACCESS_NETWORK_STATE`, ajoutée par une dépendance, est tolérée) :

```bash
$ANDROID_HOME/build-tools/36.0.0/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Note : la build release est actuellement signée avec la clé debug (TODO dans `musicplayer/android/app/build.gradle.kts`). Le keystore de production ne sera **jamais** commité.

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
- **Contrôles requis** *(mise en place progressive : CI documentaire MPL-024, CI code MPL-026)* :
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
