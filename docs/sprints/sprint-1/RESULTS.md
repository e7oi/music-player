**Snapshot du Sprint 1, figé au 05/10/2026.** Ne pas mettre à jour. Procédure en vigueur : `HOWTO.md` à la racine.

# RESULTS — MPL-002 · prototype audio multiplateforme

**Date :** 03/10/2026 · **Branche :** `mpl-002-audio-prototype` · **Code :** `musicplayer/`

> **Statut global : validation partielle.** Seul Android a été exécuté, et **sur émulateur**, pas sur le Pixel 10 Pro.
> Windows et macOS n'ont **jamais été compilés ni lancés** (génération faite depuis un Mac sans Xcode ni Windows).
> Aucun critère d'acceptation n'est donc validé « pour de bon » : c'est à toi de les confirmer par test réel (protocole §6).
> Rien dans ce document ne doit alimenter `CHANGELOG.md` avant ton test.

> **Mise à jour 03/10 (suite du premier essai Pixel)** : le harnais de test, les diagnostics (arrêt écran verrouillé, volume, WMA, FLAC) et la correction `media_kit`/service de premier plan sont dans [`DIAGNOSTICS.md`](DIAGNOSTICS.md). Les résultats ci-dessous (émulateur) n'ont pas été mis à jour avec vos résultats Pixel, que je n'ai pas en main.

Légende : **OK** = exécuté et observé · **KO** = exécuté, échec · **non testé** = pas exécuté (explication + protocole).

---

## 1. Ce qui a été réellement exécuté

| Élément | Détail |
|---|---|
| Outils | Flutter 3.47.6 (Dart 3.13.5), JDK 17, Android SDK 36, Gradle/AGP 9.1 |
| Cible Android testée | **Émulateur** profil Pixel 9, Android 16 (API 36, arm64, Google APIs), headless |
| Limite de l'émulateur | Lancé avec `-no-audio` : **le son n'a jamais été écouté**. On observe que le moteur avance sa position, accepte les seeks et atteint la fin de piste, pas que le haut-parleur émet. |
| Fichiers de test | 7 fichiers synthétiques de 20 s (`tools/gen_test_audio.sh`) : tonalité qui change toutes les 5 s pour rendre un seek audible. **Ce ne sont pas de vrais fichiers tagués** (ID3, pochettes, VBR, gros FLAC : non couverts). |
| Build | `flutter build apk --debug` et `--release` : OK. `flutter analyze` : aucun problème. `flutter test` : OK. |
| Automatisation | Bouton **Auto-test** de l'écran de test (lecture, pause, reprise, seek début/milieu/fin, fin de piste), lu dans `adb logcat`. Les contrôles système ont été pilotés par `adb shell cmd media_session dispatch …` et vérifiés avec `dumpsys media_session`. |

---

## 2. Résultats plateforme × moteur × format

Colonnes : **Chargé** = durée connue · **Lecture** = position qui avance · **Pause** = position figée · **Reprise** · **Seek** début / milieu / fin (−2 s) · **Fin** = état « completed » atteint après le seek de fin.

### 2.1 Android (émulateur API 36, son désactivé)

| Moteur | Fichier (format) | Chargé | Lecture | Pause | Reprise | Seek début | Seek milieu | Seek fin | Fin |
|---|---|---|---|---|---|---|---|---|---|
| just_audio 0.10.6 | `test_aac.m4a` (AAC) | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_alac.m4a` (**ALAC**) | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_flac.flac` | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_mp3.mp3` | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_opus.opus` | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_vorbis.ogg` | OK | OK | OK | OK | OK | OK | OK | OK |
| just_audio | `test_wav.wav` | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit 1.2.6 | `test_aac.m4a` (AAC) | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_alac.m4a` (**ALAC**) | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_flac.flac` | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_mp3.mp3` | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_opus.opus` | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_vorbis.ogg` | OK | OK | OK | OK | OK | OK | OK | OK |
| media_kit | `test_wav.wav` | OK | OK | OK | OK | OK | OK | OK | OK |

Notes :
- Les lignes `test_aac.m4a` et `test_alac.m4a` des deux premières exécutions de l'auto-test apparaissent toutes deux comme `m4a` dans le log ; l'ordre (aac puis alac) est celui de la liste MediaStore, et les deux lignes sont OK pour les deux moteurs.
- **ALAC** : lu sur Android par les deux moteurs (ExoPlayer/MediaCodec côté just_audio, décodeur `alac` de FFmpeg côté media_kit). Sur macOS (AVPlayer, supporte ALAC nativement) et Windows (WinRT MediaPlayer) : **non testé**.
- « OK » ici ne dit rien sur la qualité sonore, ni sur la précision du seek à l'oreille, ni sur des fichiers réels.

### 2.2 Windows 11 — **non testé**, pour les deux moteurs, tous les formats
Pas de machine Windows, impossible de compiler depuis macOS. Code écrit et analysé statiquement uniquement.
- `just_audio` s'appuie sur `just_audio_windows` 0.2.3 (WinRT `MediaPlayer`, MIT, ~20 k téléchargements) : plugin tiers, pas maintenu par l'auteur de `just_audio`. Aucune garantie pour OGG/OPUS (dépend probablement des codecs Windows installés : non vérifié) : **à tester en priorité**.
- `media_kit` : libmpv 2023-09-24 téléchargé au build (voir §5).

### 2.3 macOS — **non testé**, pour les deux moteurs, tous les formats
Xcode complet absent de ce Mac (seulement les Command Line Tools) : `flutter build macos` impossible. Entitlements et accès fichiers écrits mais jamais exécutés.
- **Hypothèse à vérifier (non mesurée)** : `just_audio` utilise AVPlayer sur macOS ; AVFoundation ne lit pas Ogg Vorbis, donc `test_vorbis.ogg` risque d'être **KO** avec `just_audio`, tandis que `media_kit` (libmpv/FFmpeg) devrait tout lire.

---

## 3. Critères d'acceptation

| Critère | Android (émulateur) | Android (Pixel 10 Pro) | Windows | macOS |
|---|---|---|---|---|
| Lecture d'un fichier local de chaque format | **OK** (2 moteurs, §2.1), écoute non faite | non testé | non testé | non testé |
| Pause, reprise, seek début/milieu/fin sans erreur | **OK** (2 moteurs) | non testé | non testé | non testé |
| Dossier/bibliothèque accessible après redémarrage, sans nouvelle sélection | **OK** : après réinstallation + relance, « 7 pistes (accès restauré sans nouvelle sélection) » (permission `READ_MEDIA_AUDIO` persistante, aucune sélection) | non testé | non testé | non testé |
| Android : lecture écran verrouillé / app en arrière-plan | **OK sur 25 s** (2 moteurs, voir ci-dessous) | **non testé** | — | — |
| Android : contrôles notification / écran verrouillé | **OK** pause, lecture, suivant, précédent (2 moteurs) ; barre de seek visible | **non testé** | — | — |
| macOS : accès dossier en mode sandboxé, sans échec silencieux | — | — | — | **non testé** |
| Windows : lecture depuis disque externe/USB | — | — | **non testé** | — |

### Détail Android (émulateur)
- **Arrière-plan / verrouillé** : lecture lancée, `HOME`, puis `KEYCODE_SLEEP` (`mWakefulness=Asleep`). Après 25 s, la session média est toujours `PLAYING` et la piste a avancé (`active item id` 0 → 1) pour **les deux** moteurs. Le service `audio_service` est bien au premier plan (`isForeground=true`, type `mediaPlayback`).
  - **Limites** : 25 s seulement, écran éteint sans verrouillage PIN, pas de mode Doze, pas de batterie réelle. Risque spécifique `media_kit` : je n'ai pas vérifié si un WakeLock CPU est pris pendant la lecture (ni pour just_audio) ; **à surveiller sur le Pixel** sur plusieurs minutes écran éteint.
- **Contrôles** : `cmd media_session dispatch pause|play|next|previous` → états `PAUSED`/`PLAYING` et changement de piste corrects pour les deux moteurs. Le lecteur média du panneau de notifications affiche titre, précédent, pause, suivant, stop et la barre de progression. **Non testés** : seek par glissement depuis la notification, touches média matérielles/Bluetooth, écran de verrouillage réel.
- **Permission** : la boîte système « Autoriser musicplayer à accéder à la musique et à l'audio » s'affiche au premier appui sur « Scanner MediaStore ».

---

## 4. Décisions techniques prises (et pourquoi)

| Sujet | Choix | Raison |
|---|---|---|
| Accès Android | **MediaStore** via un petit `MethodChannel` Kotlin (`MainActivity.kt`), pas de sélecteur de dossier | Demandé par le ticket. Liste les pistes sans réimport ; la permission persiste. |
| Plugin MediaStore | **Aucun** (`on_audio_query` 2.9.0 : dernière version stable datée de ~3 ans, 3.0 en bêta) | Code natif de ~60 lignes, contrôlé, sans dépendance abandonnée ; utile pour Android Auto plus tard. |
| Permission Android | Implémentée en natif (Kotlin) | `permission_handler` 13.0.2 exige `compileSdk 37`, incompatible avec l'AGP 9.1 / Flutter 3.47 actuel (build KO). Plugin retiré. |
| Lecture par `media_kit` sur Android | On lui donne le **chemin fichier** (colonne `DATA` de MediaStore), pas l'URI `content://` | libmpv/FFmpeg ne sait pas ouvrir `content://`. `just_audio` (ExoPlayer) utilise l'URI. Voir §7. |
| `audio_service` | Pont mince (`PlayerAudioHandler`) au-dessus d'un `PlayerController` indépendant du moteur | Compatible avec tout moteur par construction ; Windows n'a pas `audio_service`, le contrôleur fonctionne sans. |
| macOS | App Sandbox + `files.user-selected.read-write` + `files.bookmarks.app-scope` ; bookmark créé juste après le choix du dossier (`macos_secure_bookmarks` 0.3.0), résolu au lancement | Setup documenté par le paquet. **Jamais exécuté.** |
| Windows | Chemin du dossier simplement mémorisé | Pas de sandbox. |
| Réseau | Aucune permission `INTERNET` en **release** (vérifié avec `aapt2`) ; `ytdl=no` pour mpv ; pas d'entitlement `network.client` sur macOS | Voir §5 : la bibliothèque contient du code réseau, on la prive d'accès. |

---

## 5. Licences et impact si le code reste fermé

> Analyse technique, **pas un avis juridique**. À faire valider avant toute distribution fermée.

### Dépendances directes (licences lues dans les `LICENSE` des paquets du cache pub)

| Paquet | Version | Licence |
|---|---|---|
| just_audio | 0.10.6 | MIT (inclut ExoPlayer/Media3 1.4.1 : **Apache-2.0**) |
| just_audio_windows | 0.2.3 | MIT |
| media_kit, media_kit_libs_audio (+ libs_android/macos/windows_audio) | 1.2.6 / 1.0.7 | **MIT** pour le code Dart/glue — mais voir ci-dessous pour le binaire natif |
| audio_service | 0.18.19 | MIT |
| file_picker | 13.1.0 | MIT |
| macos_secure_bookmarks | 0.3.0 | Apache-2.0 |
| shared_preferences, path | 2.5.5 / 1.9.1 | BSD-3-Clause |

### Le point critique : le binaire natif de `media_kit`
La licence **MIT du paquet pub ne couvre pas** `libmpv`/FFmpeg qu'il télécharge. Mesuré sur le `libmpv.so` arm64 réellement embarqué dans l'APK (`tools/check_libmpv_license.sh`) :

- FFmpeg : `--disable-gpl --disable-nonfree --enable-version3`, chaîne de licence « **LGPL version 3 or later** » ;
- mpv : `--enable-lgpl` ;
- aussi liés statiquement : mbedtls (Apache-2.0), libxml2 (MIT).
- **Android = LGPL v3, vérifié** (APK construit ici).
- **Windows = LGPL v3, vérifié** sur le binaire épinglé par le paquet (`mpv-dev-x86_64-20230924-git-652a1dd.7z`, MD5 conforme) : FFmpeg `--disable-gpl --enable-version3` (« LGPL version 3 or later »), mpv `-Dgpl=false`. Ce build lie aussi libarchive, lcms2, openal, libjxl, mbedtls (licences de ces composants **non analysées**).
- **macOS = LGPL v3, vérifié** sur `libmpv-xcframeworks_v0.6.0_macos-universal-audio-default.tar.gz` (SHA-256 conforme à celui du Makefile) : Avutil/Avcodec « LGPL version 3 or later », mpv `-Dgpl=false`. Frameworks dynamiques séparés (Mpv, Av*, Swresample, Swscale, Mbed*).
- Vérification faite sur les **archives téléchargées**, pas sur un build Windows/macOS de l'app : le script `tools/check_libmpv_license.sh` permet de la refaire sur un build réel. Une mise à jour de `media_kit_libs_*` peut changer ces builds : à revérifier à chaque montée de version.

### Si le code doit rester fermé (D1)
- **`just_audio`** : MIT/Apache-2.0 partout, aucune contrainte de copyleft. Mention des licences dans l'app.
- **`media_kit` avec build LGPL (cas Android)** : possible en fermé **sous conditions** : bibliothèque liée dynamiquement et remplaçable par l'utilisateur (ici `libmpv.so` séparé dans l'APK), texte LGPL + attributions fournis, offre du code source de la bibliothèque et de ses scripts de build, pas d'interdiction de rétro-ingénierie pour le débogage. LGPL v3 ajoute l'obligation de permettre l'installation d'une version modifiée sur les « produits utilisateur » : problématique sur iOS (hors périmètre), délicate avec la signature/notarisation macOS.
- **`media_kit` avec un build GPL** : incompatible avec un code fermé. **Non observé** sur les 3 builds actuels, mais à surveiller aux mises à jour.
- **Open source (D1 = ouvert)** : les deux moteurs sont utilisables ; la contrainte LGPL/GPL disparaît en pratique.

### Réseau
Les builds libmpv contiennent des protocoles http/https/ftp/rtmp/tls. L'app ne les appelle pas (fichiers locaux uniquement), mais « aucune requête sortante » repose donc sur : absence de `INTERNET` (Android release, vérifié), absence de `network.client` (macOS, non vérifié), et **rien d'équivalent sous Windows** (pas de sandbox) → à contrôler avec le pare-feu / une capture réseau.
Les **builds** téléchargent des binaires depuis github.com (libmpv Android/Windows/macOS) : pas de réseau à l'exécution, mais une dépendance de chaîne d'approvisionnement (sommes MD5 sur Android/Windows, SHA-256 sur macOS).

---

## 6. Recommandation du moteur audio (provisoire)

**Les données ne suffisent pas pour trancher pour Windows/macOS.** Voici la recommandation et la règle de décision.

| Critère | just_audio | media_kit |
|---|---|---|
| Android (mesuré) | OK 7/7 formats ; ExoPlayer, `content://` natif | OK 7/7 formats ; nécessite un chemin fichier |
| macOS / Windows | AVPlayer / WinRT MediaPlayer (plugin Windows non officiel) : couverture de formats = celle de l'OS (OGG/OPUS incertains) | même libmpv partout : même couverture de formats, comportement homogène |
| Licence | MIT / Apache-2.0, aucune contrainte | MIT + **LGPL v3 sur Android, Windows et macOS** (vérifié, builds actuels) |
| Maintenance (pub.dev, 03/10/2026) | 0.10.6, publié il y a ~3 mois | 1.2.6 publié il y a ~9 mois ; libs 12 mois ; dépôt du build libmpv Windows archivé le 09/10/2024 (build du 24/09/2023 utilisé) |
| PRD phase 2 (gapless, crossfade, égaliseur) | égaliseur seulement Android ; gapless OK | filtre `equalizer` compilé dans libmpv ; gapless natif mpv |
| Intégration `audio_service` | éprouvée | OK via notre pont (testé) |

**Recommandation :**
1. **Garder l'interface `AudioEngine`** (déjà en place) : le moteur reste interchangeable.
2. **Android : `just_audio`** par défaut (intégration native, permissive, aucune contrainte de licence).
3. **Règle pour le desktop :** exécuter ce prototype sur macOS et Windows. Si `just_audio` échoue sur FLAC ou OGG/OPUS (formats exigés par le PRD) ou si le plugin Windows est instable → **`media_kit` partout**, sachant que les builds Windows/macOS sont **LGPL v3** (vérifié, §5) : OK si D1 est « ouvert » ou si la conformité LGPL est acceptée. Sinon → `just_audio` + limitation des formats documentée.

---

## 7. Problèmes ouverts

1. **Windows et macOS jamais compilés ni exécutés** (Xcode absent ; pas de Windows). `flutter doctor` : Xcode incomplet. CocoaPods installé.
2. **Test sur le Pixel 10 Pro non fait** : arrière-plan prolongé, écran de verrouillage réel, touches média, batterie/Doze (surtout `media_kit` sans WakeLock).
3. **Aucune écoute** : l'émulateur tournait sans audio ; qualité sonore, précision du seek et gapless non évalués. Fichiers réels (ID3, VBR MP3, grosses pochettes) non testés.
4. **Licences libmpv** : LGPL v3 confirmée sur les 3 plateformes (archives épinglées). Reste à refaire la vérification sur un vrai build, et à analyser les licences des bibliothèques annexes du build Windows (libarchive, lcms2, openal, libjxl).
5. **`media_kit` sur Android dépend du chemin fichier** (colonne `DATA` dépréciée). Si Android restreint encore cet accès, ou si on veut du SAF (`content://`/disque USB OTG), il faudra passer un descripteur (`fd://`) ou rester sur `just_audio`. Non testé : pistes sur carte SD / USB OTG.
6. **Plugin Windows de `just_audio`** : non officiel, 0.2.3, peu utilisé ; support OGG/OPUS inconnu.
7. **`audio_service` n'a pas de support Windows** : aucun contrôle système (SMTC) dans ce prototype. `smtc_windows` 1.1.0 existe (MIT) mais exige la toolchain Rust ; à évaluer plus tard.
8. **Fragilité du contrat moteur** : `just_audio.play()` ne se termine qu'à la pause/fin ; l'adaptateur le neutralise (`unawaited`). À garder en tête pour tout nouvel adaptateur.
9. **Dépendances vérifiées incompatibles** : `permission_handler` 13.0.2 (compileSdk 37). Les builds Gradle ont aussi installé automatiquement `platforms;android-35` et CMake 3.22.1.
10. **Builds dépendant de github.com** (téléchargement de libmpv) : pas de build hors ligne reproductible sans vendoring.
11. **Détail MediaStore** : artiste inconnu renvoyé sous la forme littérale `<unknown>` (à normaliser en phase UI).
12. **Mac de développement** : ~13 Go libres sur le disque ; Xcode complet ne tiendra probablement pas sans libérer de l'espace.

---

## 8. Permissions et entitlements

### Android (`AndroidManifest.xml`, vérifiés sur l'APK release)
| Permission | Pourquoi |
|---|---|
| `READ_MEDIA_AUDIO` | Lister l'audio via MediaStore (API 33+) |
| `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | Idem pour API ≤ 32 |
| `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Lecture en arrière-plan (`audio_service`) |
| `ACCESS_NETWORK_STATE` | Ajoutée par une dépendance, pas par nous (sans effet réseau) |

Pas de `INTERNET` en release (présente seulement en debug/profil, ajoutée par le template Flutter pour le hot reload). Composants déclarés : service `com.ryanheise.audioservice.AudioService` (type `mediaPlayback`), `MediaButtonReceiver`, activité héritant de `AudioServiceActivity`.

### macOS (`DebugProfile.entitlements` et `Release.entitlements`)
| Entitlement | Pourquoi |
|---|---|
| `com.apple.security.app-sandbox` | Obligatoire (App Store / notarisation) |
| `com.apple.security.files.user-selected.read-write` | Panneau « Ouvrir » (doc du paquet de bookmarks ; `read-only` suffirait peut-être, à resserrer après test) |
| `com.apple.security.files.bookmarks.app-scope` | Retrouver le dossier après redémarrage (sans lui la résolution échoue) |
| `com.apple.security.network.server`, `cs.allow-jit` (debug seulement) | Fournis par le template pour le débogage |

Pas d'entitlement `network.client`.

### Windows
Aucune permission particulière. Activer le **mode développeur** (symlinks des plugins) pour compiler.

---

## 9. Protocole de test à exécuter par toi

Préparation (une fois) :
```bash
brew install lame flac opus-tools vorbis-tools        # macOS uniquement, pour générer les fichiers
./tools/gen_test_audio.sh                             # crée test-audio/ (7 fichiers de 20 s)
```
Sous Windows, copie simplement `test-audio/` depuis le Mac sur la machine, ou utilise tes propres fichiers.

### Android — Pixel 10 Pro
1. Copier `test-audio/*` dans `Musique/` du téléphone (câble USB) ; ouvrir une appli musicale ou attendre l'indexation.
2. `cd musicplayer && flutter run -d <id>` (`flutter devices` donne l'id). Utiliser de préférence `flutter run --release` pour la lecture longue.
3. Appuyer sur **Scanner MediaStore**, accepter la permission → 7 pistes attendues.
4. Pour chaque moteur (boutons en haut) : appuyer sur **Auto-test** et lire le journal (tout doit être « OK »). Écouter chaque piste : la tonalité monte toutes les 5 s ; les boutons Début / Milieu / Fin −2 s doivent la déplacer audiblement.
5. **Redémarrage** : fermer complètement l'app, la rouvrir → « accès restauré sans nouvelle sélection ».
6. **Arrière-plan** : lancer une piste, écran verrouillé 10 min (ou playlist de 7 pistes) → la lecture doit continuer ; `media_kit` en particulier.
7. **Contrôles** : depuis l'écran de verrouillage / la notification : pause, reprise, suivant, précédent, glisser la barre de seek.

### Windows 11
1. `flutter config --enable-windows-desktop`, Visual Studio 2022 (C++), mode développeur activé.
2. `cd musicplayer && flutter run -d windows`.
3. **Choisir un dossier** (idéalement sur un **disque USB/externe**) → pistes listées.
4. Auto-test pour chaque moteur ; noter les formats KO (OGG/OPUS en particulier avec `just_audio`).
5. Fermer / rouvrir : le dossier doit être restauré. Débrancher le disque : un message d'erreur clair doit s'afficher, pas un plantage.
6. Vérifier le réseau : `tools/check_libmpv_license.sh musicplayer/build/windows/x64/runner/Release` (Git Bash) pour la licence ; capture réseau/pare-feu pendant la lecture pour confirmer **aucune** requête sortante.

### macOS
1. Installer Xcode complet (App Store), puis :
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
2. `cd musicplayer && flutter run -d macos`.
3. **Choisir un dossier** (idéalement sur un disque externe) → pistes listées ; l'app est sandboxée (entitlements ci-dessus).
4. Auto-test pour chaque moteur ; noter si `just_audio` échoue sur OGG/OPUS (hypothèse §2.3).
5. **Quitter complètement (⌘Q) et relancer** : « accès restauré » attendu. Si le message « ÉCHEC accès … » s'affiche, c'est le problème de bookmark/entitlement (jamais silencieux par conception).
6. Touches média du clavier / Centre de contrôle : `audio_service` doit afficher la piste et réagir.
7. Licence : `tools/check_libmpv_license.sh musicplayer/build/macos/Build/Products/Release/musicplayer.app` (build `flutter build macos --release`).

Reporte les OK / KO dans les tableaux §2 et §3 et signale-moi les échecs.


---

## 10. Résultats Pixel 10 Pro (Android 17) — 05/10/2026

Source : **confirmés par l'utilisateur** (essais réels : release, téléphone débranché, `just_audio` **et** `media_kit`). Les relevés `dumpsys` cités dans `DIAGNOSTICS.md` sont de l'outil de génération. Détails et preuves : [`DIAGNOSTICS.md`](DIAGNOSTICS.md) §2 et §8.

| Élément | Résultat | Remarques |
|---|---|---|
| MPL-013 : lecteur dans le panneau et sur l'écran verrouillé, boutons, canal « Lecture » | **OK** | cause : réduction des ressources qui supprimait les icônes `audio_service_*` ; correctif commit `38cbf32` |
| MPL-008 : lecture écran verrouillé avec enchaînement de pistes, notification visible | **OK** : plus de 15 min | avec le build corrigé (service au premier plan). La cause de l'arrêt à ~1 min du premier essai reste non déterminée |
| MPL-012 : flux de permission de notification | **OK** | le lecteur reste affiché même avec la permission et le canal désactivés : la permission n'était pas la cause de l'absence de contrôles |

Les cases du §3 pour le Pixel qui ne figurent pas ci-dessus (formats, seeks, redémarrage, etc.) restent « non testé » tant que le protocole §9 n'a pas été déroulé par l'utilisateur.
