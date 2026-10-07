**Snapshot du Sprint 1, figé au 05/10/2026.** Ne pas mettre à jour. Procédure en vigueur : `HOWTO.md` à la racine.

# DIAGNOSTICS — MPL-006 / 007 / 008 / 009 / 010 / 011

**Date :** 03/10/2026 · **Branche :** `mpl-002-audio-prototype` · rien n'est poussé.

> **À lire d'abord**
> - Tout ce qui est marqué « exécuté » l'a été **sur l'émulateur Android 16 (API 36)** ou sur des fichiers copiés sur le Mac. **Rien n'a été relancé sur le Pixel** : je n'y ai installé ni lancé l'app. Les conclusions « sur Pixel » sont donc soit des lectures système passives (listées §0), soit « à confirmer ».
> - Chaque diagnostic donne des causes **classées par niveau de preuve** : **Prouvé** (reproduit et mesuré), **Fort indice** (données réelles concordantes, non reproduit), **Hypothèse** (plausible, non testé), **Non déterminé**.
> - Aucun journal du Pixel n'a été relu (je n'ai que votre description) : les KO du premier essai ne sont pas ré-analysables ligne à ligne.

## 0. Ce que j'ai lu sur le Pixel (lecture seule, aucun réglage modifié)

Appareil branché en USB : Pixel 10 Pro, Android 17 (SDK 37). Commandes exécutées : `getprop`, `pm list packages`, requêtes MediaStore sur les 3 fichiers cités, `adb pull` de 3 fichiers (2 FLAC et 1 WMA, copiés dans le scratchpad du Mac, hors dépôt), `dumpsys audio`, `dumpsys package net.trtl3.musicplayer`, `dumpsys battery`, `dumpsys deviceidle`, `appops get`, `am get-standby-bucket`. Rien d'installé, rien de lancé, aucun `set`.

---

## 1. Lot A — Harnais et console de test (MPL-006 révisé + MPL-007)

### Fait
| Demande | Réalisé |
|---|---|
| Isolation | Pendant un test, le `PlayerController` est **verrouillé** : lecture, ouverture, seek, suivant/précédent, changement de moteur et commandes système (notification) sont **ignorés**. Seule la `TestSession` pilote le moteur, figé au démarrage ; son nom est écrit dans le rapport. Bannière « Test en cours, ne pas toucher », sélecteur de moteur et scan désactivés. |
| Échantillon par défaut | 1 à 2 pistes par extension (la plus courte puis la plus longue), 20 maximum. |
| Mode « Tout » | Confirmation avec durée estimée (6 s par piste, **mesuré 4,9–5,6 s** sur l'émulateur ; ≈ 4 h pour 2 624 pistes). |
| Contrôle | Compteur n/total, titre en cours, bouton Arrêter, timeout de 60 s par piste et 15 s par appel moteur (verdict `TIMEOUT` avec l'étape bloquée). |
| Journal lisible | Légende des colonnes en tête, durée de chaque étape, chemin, message d'erreur exact (y compris les lignes `mpv`), résumé par format, export **texte**, **CSV** et « Copier ». |
| Verdicts | `OK`, **`WARN`** (étapes OK mais le moteur a signalé une erreur pendant la piste), `KO`, `TIMEOUT`. C'est ce qui aurait signalé « Army of Me » (OK à tort dans le 1er essai). |
| Console (MPL-007) | Recherche sans casse ni accents (tous les mots), filtre de formats multi-sélection avec **inventaire** de la bibliothèque, tri nom/format/durée/taille/date d'ajout, `ListView.builder` à hauteur fixe, Auto-test appliqué à la **liste filtrée**, « Rejouer les échecs » (KO, TIMEOUT et WARN). |

### Vérifié
- 10 tests unitaires : repliement des accents, filtre/tri/inventaire, échantillonnage, rapport CSV/texte, **isolation** (faux moteur : aucune action utilisateur n'atteint le moteur pendant un test), mesure de coût du filtre. `flutter analyze` propre.
- Émulateur, bibliothèque synthétique de **2 634 pistes** (générée par `tools/gen_big_library.sh`, + vos 3 fichiers réels) : liste, inventaire par format (mp3 1229, flac 656, m4a 372, opus 128…), recherche « bjork » qui trouve le dossier « Björk » (107 résultats avec le filtre mp3), Auto-test sur la liste filtrée (2 pistes mp3 seulement), bannière et progression.
- Échantillon complet sur toute la bibliothèque, 13 pistes, **deux moteurs, sans régression** après la correction MPL-008 (voir §2).
- Coût du filtre en Dart (VM de bureau, indicatif) : 3,8 ms par frappe, 3 ms pour un nouveau tri, sur 5 000 pistes.

### Non vérifié
- **Fluidité réelle du défilement** de 2 624 pistes sur le Pixel : `dumpsys gfxinfo` ne voit pas les images Flutter ; aucune mesure fiable. À regarder à l'œil, idéalement en `flutter run --profile`.
- **Exports** (.txt, .csv) via la boîte système et « Copier » : **non testés** (code écrit, jamais cliqué). `Tout` sur 2 624 pistes : non lancé.
- Le journal contient les lignes du test ; sa taille est plafonnée à 5 000 lignes (un test « Tout » en produit ~20 000 : les premières seraient perdues). Le rapport lui-même (texte/CSV) n'est pas plafonné.

---

## 2. MPL-008 — La lecture s'arrête après ~1 min écran verrouillé

### 2.1 Audit de configuration
| Élément | Valeur | Verdict |
|---|---|---|
| Permissions | `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `READ_MEDIA_AUDIO` : déclarées **et accordées** sur le Pixel | OK |
| Service | `com.ryanheise.audioservice.AudioService`, `foregroundServiceType="mediaPlayback"` (`types=0x2` vérifié par `dumpsys`) | OK |
| `androidStopForegroundOnPause` | **`true`** (défaut de `AudioServiceConfig`, non surchargé) | À risque : voir 2.3 |
| `androidNotificationOngoing` | `false` (défaut) | neutre |
| `POST_NOTIFICATIONS` | **absente** du manifeste ; sur le Pixel `appops POST_NOTIFICATION = ignore` | **Écart** : la notification n'est probablement pas affichée (Android 13+). Effet sur l'arrêt : non démontré |
| `targetSdk` | 36 (défaut Flutter 3.47) | information |
| Bucket d'attente (Pixel) | 40 (« rare »), pas dans la liste blanche batterie | à noter, effet non démontré |

### 2.2 Wake lock CPU, par moteur
- **Code source** : `audio_service` prend un `PARTIAL_WAKE_LOCK` (`AudioService.java`, `enterPlayingState()` → `acquireWakeLock()`) et le **libère dans `exitForegroundState()`**, c.-à-d. dès que le service quitte le premier plan. `just_audio` : aucun code de wake lock dans le plugin. `media_kit` / libs Android : aucun. **Aucun moteur ne tient de wake lock lui-même.**
- **`dumpsys power`, émulateur, 120 s écran verrouillé, les deux moteurs** : `PARTIAL_WAKE_LOCK 'com.ryanheise.audioservice.AudioService'` (uid de l'app) **+** `'AudioMix'` (système, au nom de l'app). Donc dans le cas sain, la protection CPU vient d'`audio_service`, pour les deux moteurs.
- **Conséquence** : si le service perd le premier plan, **le wake lock disparaît aussi** (preuve en 2.3, cas `media_kit` : plus de lock `audioservice` en fin de capture).

### 2.3 Causes, classées
**① Prouvé (émulateur Android 16), corrigé — `media_kit` perd le service de premier plan à chaque changement de piste.**
- Scénario : enchaînement de pistes courtes, écran verrouillé, échantillonnage toutes les 3 s pendant 90 s (`tools/diag_lockscreen.sh`).
- Mécanisme : mpv signale `playing=false` en fin de fichier ; l'adaptateur relayait cet état ; `audio_service` fait `stopForeground` (+ libère le wake lock), puis, 40 ms plus tard, `playing=true` déclenche `startForegroundService` **sans action de l'utilisateur et app en arrière-plan** : Android refuse.
- Preuves : `ActivityManager: Background started FGS: Disallowed [callingPackage: net.trtl3.musicplayer … code:DENIED]` et `startForegroundService() not allowed` ; `isForeground=true` dans **4 échantillons sur 31** (3, 6, 9 s) puis jamais ; des événements `playbackState playing=false/true` toutes les 2,5 à 8 s ; pas de wake lock `audioservice` en fin de capture ; événements `AudioHardening … level: partial` à ces instants.
- Même scénario avec **`just_audio`** : service au premier plan **31/31**, aucune bascule de `playing` (le drapeau reste vrai d'une piste à l'autre).
- **Correction** (commit séparé `d6f041c`, facile à annuler) : l'état `playing` de `media_kit` devient l'**intention** (`play()` appelé, pas de `pause()`/`stop()`), comme chez `just_audio` ; le contrôleur met en pause explicitement à la fin de la file. **Après correction, même scénario : 31/31, 0 ligne « Disallowed », 0 bascule, wake lock présent.**
- **Limite** : prouvé sur Android 16 ; **non confirmé sur le Pixel (Android 17)**.

**② Fort indice (journal système réel du Pixel) — Android 17 « audio hardening ».**
`dumpsys audio` du Pixel contient, pour `net.trtl3.musicplayer` :
```
21:00:05  AudioHardening background playback would be muted … level: partial, usage: USAGE_MEDIA
21:00:11  … partial     21:00:17  … partial     21:00:22  … partial
21:00:26  … level: full
21:06:47  … partial     21:11:16  … partial
```
Selon la documentation Android 17 : `partial` = l'app joue en arrière-plan **sans aucun service de premier plan** ; `full` = service présent **sans capacité « while-in-use »** (démarré hors action visible/utilisateur) ; dans les deux cas **l'audio est coupé (silence), sans exception**. Ces événements sont exactement ce que produit ① (service sorti du premier plan, redémarrage refusé), et aussi **n'importe quelle pause→lecture effectuée en arrière-plan**, y compris les étapes « pause/reprise » de l'ancien Auto-test si l'écran était verrouillé pendant qu'il tournait (ce qui correspond à votre 1er essai).
- **Ce que ça ne prouve pas** : quel moteur jouait, si le son a réellement été coupé (le libellé du journal est « would be muted ») ni que c'est la cause de l'arrêt à ~1 min. Les événements du Pixel concordent avec ①, ils ne la démontrent pas.

**③ Non déterminé — `just_audio` sur le Pixel.** Sur émulateur, `just_audio` ne montre aucun défaut (31/31 avec enchaînement de pistes, wake lock tenu). Si l'arrêt à ~1 min est aussi observé avec `just_audio` sur le Pixel après correction ①, la cause est ailleurs (voir ④).

**④ Hypothèses non testées** : `POST_NOTIFICATIONS` refusé (notification masquée, effet sur le service non démontré) ; bucket « rare » / gestion batterie constructeur ; Doze (non pertinent tant qu'un service de premier plan existe). **Le script de capture enregistre le bucket, la permission de notification et la liste blanche batterie.**

> **Rien d'autre n'a été corrigé.** En particulier : pas de demande de `POST_NOTIFICATIONS`, pas de changement de `androidStopForegroundOnPause`, pas de wake lock supplémentaire : aucune preuve que ce soit la cause.

### 2.4 Journalisation ajoutée (écran « Journal » et `adb logcat -s flutter`, `-s MPL`)
- État du lecteur à chaque changement (moteur, `processing`, `playing`) ; **battement de cœur toutes les 5 s** : moteur, état, position, durée, cycle de vie de l'app, piste.
- Cycle de vie de l'activité côté natif (tag `MPL` : `onCreate/onStart/onResume/onPause/onStop/onDestroy/onTrimMemory`) et côté Flutter (`lifecycle`).
- Focus audio : interruptions (begin/type), `becomingNoisy`, périphériques ajoutés/retirés.
- Service : commandes système (play/pause/stop/suivant/précédent), boutons média, `onTaskRemoved`, `onNotificationDeleted`, changements de `playbackState`.
- `mpv` : avertissements et erreurs avec leur composant (`ffmpeg/audio`, `ad`, `demuxer`…).
- Arrêt du service : pas de crochet dans le plugin ; il se déduit de `ActivityManager`/`isForeground` dans la capture ci-dessous.

### 2.5 Procédure : capture sans câble USB (débogage sans fil)
1. **Pixel** : Réglages → Options pour les développeurs → *Débogage sans fil* activé (même Wi-Fi que le Mac). Touchez *Débogage sans fil* → *Associer l'appareil avec un code*.
2. **Mac** : `adb pair <IP>:<port_association>` puis saisir le code ; ensuite `adb connect <IP>:<port>` (le port est celui affiché sur l'écran principal *Débogage sans fil*). `adb devices` doit lister `<IP>:<port>`.
3. Installer l'APK de test (ex. `flutter build apk --release` puis `adb -s <IP>:<port> install -r build/app/outputs/flutter-apk/app-release.apk`). Le build release est plus réaliste ; le build debug ajoute des logs Dart.
4. **Lancer la capture sur le Mac, puis démarrer la lecture et verrouiller** :
   ```bash
   tools/diag_lockscreen.sh -s <IP>:<port> -d 600 -i 10
   ```
   (10 min, un échantillon toutes les 10 s). Dans l'app : filtrer une liste de **pistes courtes** (ou tout), toucher une piste, **bouton Verrouiller**.
5. **Débrancher le câble USB** pendant la capture ; le Wi-Fi doit rester actif écran éteint (si des échantillons sont vides, c'est le Wi-Fi qui s'est endormi, pas l'app : l'heure d'appareil est dans chaque fichier).
6. Résultat dans `diag-AAAAMMJJ-HHMMSS/` : `00-context.txt` (appareil, `targetSdk`, permission de notification, bucket, batterie), un `sample-NNNNs.txt` par intervalle (écran/wake locks, **service au premier plan**, session média, **événements AudioHardening + focus**, pistes `audio_flinger` avec `PortMuted`/`G dB`, processus, alimentation), `logcat.txt` horodaté (ActivityManager, `MPL`, `flutter`, focus…) et `final-*.txt` (dumps complets). Lecture rapide :
   ```bash
   grep -hE 'state=PlaybackState|isForeground|AudioHardening' diag-*/sample-*.txt | sort | uniq -c | sort -rn | head
   grep -E 'Disallowed|FGS|AudioHardening|playbackState' diag-*/logcat.txt | head -40
   ```
7. À regarder, dans l'ordre : le service est-il `isForeground=true` à chaque échantillon ? À partir de quelle seconde cesse-t-il de l'être ? Un `Background started FGS: Disallowed` correspond-il ? `PortMuted=true` / `G dB` qui chute à ce moment ? `mWakefulness=Asleep` et lock `audioservice` encore présent ?

Commandes manuelles équivalentes pendant la coupure :
```bash
adb -s <IP>:<port> shell dumpsys activity services net.trtl3.musicplayer | grep -E 'isForeground|types'
adb -s <IP>:<port> shell dumpsys audio | grep -A12 'Hardening enforcement'
adb -s <IP>:<port> shell "dumpsys power | grep -A4 'Wake Locks'"
adb -s <IP>:<port> shell dumpsys media_session | grep -A8 'package=net.trtl3.musicplayer'
adb -s <IP>:<port> logcat -v threadtime -s MPL flutter ActivityManager
```
Test de causalité (**modifie un réglage système : à vous de décider**) : la documentation Android 17 cite `adb shell cmd audio set-enable-hardening disable|enable|throw`. Je ne l'ai **pas** exécutée, et `cmd audio help` ne renvoie rien sur ce Pixel : la commande est **à vérifier**. Si elle existe et que l'arrêt disparaît avec `disable`, l'audio hardening est confirmé comme cause.

---

## 3. MPL-011 — Volume plus faible avec `media_kit`

### 3.1 Configuration effective relevée (bouton « Config moteur » ; émulateur, `army.flac`)
| | just_audio (ExoPlayer, media3 1.4.1) | media_kit (libmpv) |
|---|---|---|
| Volume moteur | `1.0` | `100` (`volume-max 130`), `mute=no` |
| ReplayGain / normalisation | aucune (non implémentée) | `replaygain=no`, preamp 0, `audio-normalize-downmix=no`, `af` vide |
| Backend audio | `AudioTrack` (session 297) | **`ao=opensles`** |
| Format / canaux | PCM 16 bits, stéréo | `s16`, 44 100 Hz, `audio-channels=auto-safe` |
| AudioAttributes | `usage=MEDIA (1)`, `contentType=MUSIC (2)` | `usage=MEDIA (1)`, `contentType=**UNKNOWN (0)**` |

### 3.2 Mesure objective système (émulateur, `dumpsys media.audio_flinger`, même piste, même position)
| Colonne `audio_flinger` | just_audio | media_kit |
|---|---|---|
| Gain de piste `L dB / R dB / VS dB` | 0 / 0 / 0 | 0 / 0 / 0 |
| `G dB` / `PortVol dB` (volume de flux) | −33 / −33 | −33 / −33 |
| Format / débit | PCM16 / 44 100 | PCM16 / 44 100 |
| `Usg` / `CT` | 1 / **2** | 1 / **0** |
| Taille de tampon (`FrmCnt`) | 16 048 | 4 012 |
| `PortMuted` | false | false |

**Conclusion mesurée (émulateur)** : au niveau du framework Android, **le gain appliqué est identique** ; la config de mpv est neutre (pas de ReplayGain ni de filtre). Les différences sont le **type de contenu** (MUSIC vs UNKNOWN), l'**API de sortie** (OpenSL ES vs AudioTrack) et la taille de tampon.

### 3.3 Causes possibles, classées
- **Non déterminé (pas de mesure sur le Pixel)**. L'émulateur n'a pas d'effets audio constructeur.
- **Hypothèses** : (a) le Pixel traite différemment `CONTENT_TYPE_UNKNOWN` et `CONTENT_TYPE_MUSIC` (effets/loudness) ; (b) chemin OpenSL ES vs AudioTrack ; (c) selon le format, décodeur différent (MediaCodec vs FFmpeg) : sans effet pour FLAC (sans perte), à vérifier pour MP3/AAC ; (d) biais de perception (A/B non à volume système égal). **Aucune n'est prouvée.**
- **Éliminé sur émulateur** : volume moteur, ReplayGain, normalisation, filtres, volume de flux, gain de piste.

### 3.4 Méthode de comparaison objective (à faire sur le Pixel)
1. **Même fichier, même position, même volume système, BT et écouteurs identiques.** Fichier conseillé : `test_wav.wav` (sinusoïde à −8,73 dBFS crête, générée par `tools/gen_test_audio.sh`), lu de 1 s à 19 s ; volume système noté (`adb shell dumpsys audio | grep -i "streamVolume"`).
2. **Côté système (sans micro)** : pendant que chaque moteur joue la même piste, relever `adb shell dumpsys media.audio_flinger` (colonnes `G dB`, `L/R/VS dB`, `PortVol dB`, `Format`, `CT`, `Usg`, flags) : toute différence de gain ou de chaîne d'effets y apparaît.
3. **Côté niveau physique** : enregistrer la sortie avec la **même chaîne** pour les deux moteurs (adaptateur USB-C → entrée ligne du Mac, de préférence ; sinon micro fixe), puis :
   ```bash
   tools/measure_loudness.py just_audio.wav media_kit.wav --from 3 --to 14
   ```
   Écart RMS < 0,5 dB = bruit de mesure ; ~3 dB = nettement audible.
4. Répéter avec un MP3, un M4A et un FLAC réels (décodeurs différents selon le format).
5. Si l'écart est confirmé : refaire en forçant `contentType=MUSIC` sur la sortie de `media_kit` (à tester, **non fait**).

---

## 4. MPL-009 — WMA

| Constat | Preuve |
|---|---|
| Le fichier est du **Windows Media Audio 9 standard** : WMA v2 (`wFormatTag 0x0161`), 192 kbit/s, 44,1 kHz, stéréo | analyse de l'en-tête ASF de `02 Hope and Memory.wma` |
| **`just_audio` ne lit pas le WMA** : `PlayerException(0): Source error`, durée inconnue | reproduit sur émulateur ; **exécuté** |
| **`media_kit` lit le WMA** : chargé, lecture, pause, reprise, seeks, fin de piste, aucune erreur | reproduit sur émulateur ; cohérent avec votre journal Pixel |
| Pourquoi | ExoPlayer (media3 1.4.1) **n'a aucun extracteur ASF/WMA** (liste des classes de `media3-extractor` inspectée : MP3, FLAC, MP4, OGG, WAV, AMR, TS, MKV, AVI…). libmpv est compilé avec `--enable-decoder='wma*'` et `--enable-demuxer=asf` (vérifié dans le binaire) |
| Android ne comprend pas non plus le WMA côté bibliothèque | MediaStore du Pixel : `duration=NULL` pour les 5 WMA vus → les durées s'affichent « — » dans la liste |

**Conclusion : `media_kit` lit les `.wma`, `just_audio` non (plateforme Android).** Windows : WMA nativement lisible par Windows Media (hypothèse, **non testé**) ; macOS : AVPlayer ne lit pas le WMA (hypothèse, **non testé**).

---

## 5. MPL-010 — FLAC suspects avec `media_kit`

**Fichiers analysés** (copiés du Pixel sur le Mac) : `01 - Beggar in the Morning.flac` (33,9 Mo) et `01 - Army of Me.flac` (28,0 Mo).

| Constat (les deux fichiers) | Détail |
|---|---|
| **Tag ID3v2.3 en tête** du fichier, avant `fLaC` | 27 557 o (Beggar), 27 097 o (Army) ; `flac` : « non-standard and strongly discouraged » |
| **Tag ID3v1 (« TAG ») de 128 octets en queue** | présent dans les deux |
| `flac -t` → `LOST_SYNC` | position de l'erreur = **exactement le nombre total d'échantillons** (Army : 10 338 216 ; Beggar : 15 657 852, valeurs identiques à `STREAMINFO`) |

**Interprétation (prouvée)** : tout le flux audio est décodable ; l'erreur ne survient qu'**après le dernier échantillon**, quand le décodeur lit le tag ID3v1 final comme s'il s'agissait d'une trame FLAC.

**Reproduction avec les deux moteurs** (émulateur, fichiers réels, test isolé) :
| | `just_audio` (ExoPlayer) | `media_kit` (mpv) |
|---|---|---|
| Army of Me | **OK**, aucun message | **WARN** : `error ad: Error decoding audio` à la fin |
| Beggar in the Morning | **OK** | **WARN**, même erreur à la fin |

Message exact relevé côté mpv, au moment où la lecture atteint la fin : `ffmpeg/audio: flac: invalid sync code` → `invalid frame header` → `decode_frame() failed` → `ad: Error decoding audio.` (+ au chargement `flac: Discarding ID3 tags because more suitable tags were found.`). Toutes les étapes (chargement, lecture, pause, reprise, seeks, fin de piste) passent.

**« Beggar : toutes les étapes KO, sans seek » : non reproduit.** En test isolé, les deux moteurs passent toutes les étapes sur ce fichier. Cause la plus probable : contamination de l'ancien test (changement de moteur et re-scan pendant le test) : **fort indice, non prouvé**, faute d'accès à l'ancien journal. À rejouer sur le Pixel avec le nouveau harnais (bouton « Rejouer les échecs »).

**Impact** : sans conséquence audible (tous les échantillons sont décodés), mais `media_kit` expose l'erreur comme un échec de lecture. À traiter plus tard : tolérer une erreur de décodage dans la dernière seconde, et/ou nettoyer les tags (`tools/analyze_audio_file.sh <fichier>` pour auditer une bibliothèque). Je n'ai rien corrigé dans l'application.

---

## 6. Outils ajoutés
| Fichier | Rôle |
|---|---|
| `tools/diag_lockscreen.sh` | capture MPL-008 (lecture seule), compatible USB et sans fil |
| `tools/gen_big_library.sh` | bibliothèque synthétique (2 624+ fichiers, accents) pour la liste/recherche |
| `tools/analyze_audio_file.sh` | analyse structurelle d'un fichier suspect (ID3, `flac -t`, `ffprobe` si installé) |
| `tools/measure_loudness.py` | écart de niveau RMS entre deux enregistrements (MPL-011) |

## 7. Problèmes ouverts
1. **Correction ① à confirmer sur le Pixel** (Android 17) avec `tools/diag_lockscreen.sh` en sans-fil, les deux moteurs, ≥ 5 min écran verrouillé, enchaînement de pistes courtes **et** pistes longues.
2. **Ne pas verrouiller le téléphone pendant un Auto-test** : ses étapes pause/reprise relancent le service en arrière-plan (refusé par Android) ; le journal Pixel actuel s'explique ainsi.
3. `POST_NOTIFICATIONS` absente/ignorée sur le Pixel : notification probablement invisible, contrôles de verrouillage à vérifier (impact aussi pour Android Auto plus tard). Non corrigé : effet sur l'arrêt non démontré.
4. Volume `media_kit` : **cause non déterminée** ; mesure sur le Pixel nécessaire (§3.4).
5. Exports et « Tout » sur 2 624 pistes non testés ; fluidité du défilement non mesurée ; plafond du journal (5 000 lignes).
6. Le message `Error decoding audio` en fin de FLAC avec tag ID3v1 est un faux KO potentiel pour `media_kit` en lecture normale.
7. `just_audio` + WMA : non lisible (limite Android) ; stratégie de repli à décider (D2).

---

## 8. MPL-013 — Notification et canal « Lecture » absents en build release

**Date :** 04/10/2026. Appareil : Pixel 10 Pro, **Android 17 (SDK 37)**, build `CP3A.260905.009`, `user/release-keys`. Émulateur de comparaison : Android 16 (SDK 36).

### 8.1 Cause (prouvée)
**La réduction des ressources (`shrinkResources`, activée d'office par Flutter en release) supprime les 7 icônes `drawable/audio_service_*`.** `audio_service` les retrouve **par leur nom** (`Resources.getIdentifier("audio_service_play_arrow", "drawable", …)`), ce que le réducteur ne voit pas. Sans icône, `PlaybackStateCompat.CustomAction.Builder` lève `IllegalArgumentException: You must specify an icon resource id to build a CustomAction` **à chaque mise à jour d'état**, avant d'atteindre `enterPlayingState()` : le service n'entre jamais au premier plan, ne crée ni canal ni notification, et la session média reste `NONE`/inactive.

| Preuve | Résultat |
|---|---|
| Table de ressources des APK (`aapt2 dump resources`) | debug : **7** icônes ; release : **0** ; release sans réduction : 7 |
| Rapport du réducteur (`mapping/release/resources.txt`) | `drawable:audio_service_*` **« is not reachable »** (7 lignes) |
| Journal d'exécution, release avec réduction, **Pixel et émulateur** | même exception, **même pile** `AudioService.l` (même `r8-map-id`), dès le **premier** état au démarrage de l'app, avant toute lecture |
| `dumpsys activity services` (Pixel, release avec réduction) | `startForegroundCount=0`, pas `isForeground` |
| `dumpsys notification` (Pixel, release avec réduction) | **0** notification de l'app |
| `dumpsys media_session` (Pixel, release avec réduction) | `active=false`, `state=NONE` |
| Test discriminant, **Pixel**, release sans réduction (80,8 Mo) | `isForeground=true` (type `mediaPlayback`), notification postée (Précédent/Pause…), session `PLAYING`, wake lock `audioservice`, **0 exception** |
| Test discriminant, **émulateur**, 3 builds | release avec réduction : 0 notification, 11 exceptions ; sans réduction et debug : notification présente, 0 exception |
| Build debug, **Pixel** | identique au « sans réduction » (service, notification, session, wake lock, 0 exception) |

### 8.2 Hypothèses examinées
| Hypothèse | Verdict | Preuve |
|---|---|---|
| **Manifeste fusionné différent** | **Écartée** | diff debug/release : seules différences `INTERNET` (debug seulement) et `android:debuggable` ; `AudioService`, `MediaButtonReceiver`, `foregroundServiceType="mediaPlayback"` et toutes les permissions sont identiques |
| **R8 (réduction du code) retire/renomme une classe d'`audio_service`** | **Non établie comme cause** | R8 est actif (`mapping.txt` 19 Mo) et renomme des classes ; `AudioServiceActivity` est fusionnée dans `MainActivity`, sans effet observé ; les classes déclarées dans le manifeste (`AudioService`, `MediaButtonReceiver`) sont conservées. Après correction des ressources, **R8 reste actif et tout fonctionne** : aucune règle `-keep` n'a été nécessaire |
| **Initialisation propre à la release** | Écartée | exception reproduite à l'identique en debug/release seulement pour la présence des icônes |
| **Permission de notification** | Ce n'était pas la cause de ce défaut | le flux de permission (MPL-012) fonctionne ; même avec la permission accordée, la notification manquait en release |

### 8.3 Correctif (commit séparé `38cbf32`, réversible)
Fichier `musicplayer/android/app/src/main/res/raw/keep.xml` : `tools:keep="@drawable/audio_service_*"` (**uniquement** ces 7 icônes, pas un keep global), avec un commentaire expliquant pourquoi. Annulation : supprimer ce fichier.
- **Vérifié** : APK release normal (réduction **active**, 75,6 Mo) : 7 icônes présentes (`resources.txt` : « reachable from keep xml file »), R8 inchangé.
- **Émulateur (Android 16)** : `just_audio` et `media_kit` → service au premier plan, canal « Lecture », notification, lecteur affiché dans le panneau, **0 exception**. Écran de verrouillage réel (PIN) : lecteur affiché et boutons réactifs (voir MPL-012).
- **Pixel (Android 17), build corrigé installé, lecture lancée par vous, relevés système** : `just_audio` **et** `media_kit` : `isForeground=true` (type `mediaPlayback`), notification avec Précédent/Pause/Suivant, session `active=true`/`PLAYING`, wake lock `audioservice` tenu, **0 exception, 0 « Background started FGS: Disallowed »**.
- **Validé par l'utilisateur sur le Pixel** (release, téléphone débranché, `just_audio` et `media_kit`) : lecteur dans le panneau et sur l'écran verrouillé, boutons fonctionnels, canal « Lecture » visible (voir §8.5).

### 8.4 Conséquence importante pour MPL-008 (à lire)
Votre validation MPL-008 (lecture écran verrouillé > 5 min, enchaînement de pistes, `just_audio` et `media_kit`, release, téléphone débranché) a été obtenue avec un build où **le service n'est jamais passé au premier plan** (cause ci-dessus). Elle **ne valide donc pas** l'explication « service de premier plan perdu entre deux pistes » (§2.3 ①), et elle montre au contraire que, sur ce Pixel, la lecture a continué plus de 5 min **sans** service de premier plan (les événements `AudioHardening … would be muted` sont donc, au moins ici, restés sans effet audible). La cause de l'arrêt à ~1 min du premier essai reste **non déterminée** ; le défaut `media_kit`/service (§2.3 ①) reste réel et corrigé, mais son effet sur le Pixel **n'est pas prouvé**.
**Refait avec le build corrigé (service au premier plan) — confirmé par l'utilisateur** : plus de 15 min écran verrouillé avec enchaînement de pistes, notification visible, `just_audio` et `media_kit`, release, téléphone débranché. Aucune régression. La cause de l'arrêt à ~1 min du premier essai reste toutefois **non déterminée** : elle n'a pas été reproduite, et la capture `tools/diag_lockscreen.sh` n'a pas été faite sur le build corrigé.

### 8.5 Critères d'acceptation MPL-013
| Critère | Statut |
|---|---|
| Canal « Lecture » visible dans les réglages de notifications de l'app | **OK** (utilisateur, Pixel, release) |
| Lecteur affiché dans le panneau de notifications pendant la lecture | **OK** (utilisateur, Pixel, release) ; relevé système concordant |
| Précédent / pause / suivant fonctionnels, panneau **et** écran verrouillé | **OK** (utilisateur, Pixel, release) |
| Vérifié avec `just_audio` **et** `media_kit` | **OK** (utilisateur) |
| Aucune régression de la lecture écran verrouillé (MPL-008) | **OK** (utilisateur) : plus de 15 min, enchaînement de pistes, notification visible |

**MPL-012 (observation utilisateur)** : le flux de permission fonctionne sur le Pixel, et le lecteur **reste affiché même avec la permission de notification et le canal désactivés**. L'absence de contrôles n'était donc pas due à la permission : la cause était MPL-013. La demande de permission reste utile (notification visible dans le panneau) mais n'est pas nécessaire à l'affichage du lecteur sur cet appareil.

### 8.6 Pièges notés
- `flutter build apk --no-shrink` **n'existe pas** dans Flutter 3.47.6. Pour désactiver la réduction (diagnostic) : `flutter build apk --release --android-project-arg=shrink=false`.
- Le README d'`audio_service` 0.18.19 affirme que les icônes du plugin ne sont pas retirées par défaut : **faux** avec Flutter 3.47.6 / AGP 9.1 (preuve ci-dessus). Un `keep.xml` est nécessaire.
- Le canal de notification persiste d'une installation à l'autre (mise à jour sans désinstallation) : sa présence dans `dumpsys` n'est pas une preuve que le build en cours le crée. Le critère fiable est `startForegroundCount` / `isForeground` et la notification postée.
- Un build debug masque ce défaut : tout item doit être validé en **release** avant fermeture.

---

## 9. MPL-011 (reprise) — `media_kit` perçu plus faible que `just_audio` sur le Pixel

**Date :** 05/10/2026. **Statut : cause non déterminée.** Le Pixel n'était pas branché pendant ce travail : **aucune mesure n'a été faite sur le Pixel**. Ce qui suit est (a) ce qui a été établi sur émulateur et dans le binaire libmpv, (b) les outils et les trois builds prêts, (c) la matrice qui dit quoi conclure de chaque résultat. **Aucun gain n'a été ajouté ni modifié** (volume moteur, ReplayGain, normalisation : inchangés).

### 9.1 Ce qui est établi (émulateur Android 16, release, sinus 1 kHz −12 dBFS)
Signal de référence : `tools/gen_sine_1khz.py` → `sine_1k_-12dBFS_30s.wav` (stéréo 16 bits 44,1 kHz, **crête −12,00 dBFS, RMS −15,01 dBFS** vérifiés).

| Relevé `dumpsys` pendant la lecture | B1 `just_audio` | B1 `media_kit` | B2 `media_kit` (`ao=audiotrack`) | B3 `just_audio` (contentType UNKNOWN) |
|---|---|---|---|---|
| Lecteur | `AudioTrack` | **OpenSL ES AudioPlayer** | `AudioTrack` | `AudioTrack` |
| usage | MEDIA | MEDIA | MEDIA | MEDIA |
| **contentType** | **MUSIC** | **UNKNOWN** | **MOVIE** | **UNKNOWN** |
| **flags** | `0xA00` (DEEP_BUFFER + MUTE_HAPTIC) | **`0x0`** | `0xA00` | `0xA00` |
| Thread de sortie / flags | `AudioOut_D` / PRIMARY | idem | idem | idem |
| Gain de piste (`L/R/VS dB`) | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| `G dB` = `PortVol dB` (volume de flux) | −33 / −33 | −33 / −33 | −33 / −33 | −33 / −33 |
| Effets actifs sur le thread | 0 chaîne | 0 | 0 | 0 |
| Format / débit de la piste | PCM16 / 44 100 | PCM16 / 44 100 | PCM16 / **48 000** (rééchantillonné par mpv) | PCM16 / 44 100 |
| Tampon (`FrmCnt`) | 16 048 | 4 012 | 3 936 | 16 048 |
| Volume `STREAM_MUSIC` | index 5 | 5 | 5 | 5 |

**Lecture** : sur l'émulateur, **aucun gain ne diffère** entre les moteurs (gain de piste 0 dB, même volume de flux, aucun effet, même thread et périphérique). Les seules différences sont : le type de lecteur, le **contentType**, les **flags** (`media_kit` par défaut n'a pas `DEEP_BUFFER`), le débit et le tampon. L'émulateur n'a pas la chaîne audio du Pixel (effets constructeur, routage) : **il ne peut pas expliquer une différence de volume perçue**.

### 9.2 Ce que libmpv permet (binaire Android inspecté)
- Deux sorties audio compilées : **`opensles`** (celle que `media_kit` impose par défaut) et **`audiotrack`**.
- La sortie `audiotrack` fixe **en dur** `USAGE_MEDIA` + **`CONTENT_TYPE_MOVIE`** ; `opensles` donne `CONTENT_TYPE_UNKNOWN` et aucun drapeau. **Aucune option mpv ne permet `CONTENT_TYPE_MUSIC`.**
- Conséquence : l'expérience demandée « contentType MUSIC pour `media_kit` » **n'est pas réalisable avec le plugin** (il faudrait patcher libmpv ou changer de moteur). Je la remplace par l'expérience **inverse sur le moteur de référence** (B3 : `just_audio` en UNKNOWN) ; elle répond à la même question (le contentType change-t-il le niveau ?).

### 9.3 Builds numérotés (release, réduction active, une seule variable chacun)
| Build | Commande | Variable | APK (MD5) |
|---|---|---|---|
| **B1** | `flutter build apk --release` | aucune (référence) | `0fcf419a…` |
| **B2** | `flutter build apk --release --dart-define=MPV_AO=audiotrack` | `media_kit` sort par `AudioTrack` au lieu d'OpenSL ES (donc flags `DEEP_BUFFER`, contentType MOVIE) | `ddbcd878…` |
| **B3** | `flutter build apk --release --dart-define=JA_CONTENT_TYPE=unknown` | `just_audio` déclare contentType UNKNOWN au lieu de MUSIC | `bbd2bbc1…` |

Vérifié sur émulateur : chaque variable agit comme annoncé (tableau 9.1). Le journal de l'app écrit `[experiment] B1 baseline` / `MPV_AO=audiotrack` / `JA_CONTENT_TYPE=unknown` au démarrage.

### 9.4 Matrice d'interprétation (à appliquer aux résultats Pixel)
| Observation sur le Pixel | Conclusion |
|---|---|
| B1 : relevés **identiques** pour les deux moteurs (mêmes gains, thread, effets) **et** enregistrements au même niveau (< 0,5 dB) | **Pas de différence de pipeline ni de niveau** : l'écart perçu n'est pas mesurable (écoute, décodeurs sur musique réelle) |
| B1 : relevés **différents** (thread/flags de sortie, chaîne d'effets) et `media_kit` plus faible à l'enregistrement | La **chaîne de sortie** diffère ; voir B2 / B3 pour isoler |
| **B2** : `media_kit` rejoint `just_audio` (écart < 0,5 dB) | **Cause = chemin OpenSL ES / absence de `DEEP_BUFFER`** ; correctif possible : `ao=audiotrack` (en gardant à l'esprit contentType MOVIE et le rééchantillonnage à 48 kHz) |
| **B3** : `just_audio` devient plus faible et rejoint `media_kit` | **Cause = contentType** (UNKNOWN traité autrement par le Pixel) ; non corrigeable via les options mpv |
| B2 et B3 sans effet, relevés identiques | Cause **non déterminée** par ces variables ; envisager le décodage (comparer WAV/FLAC/MP3 réels) et le rééchantillonnage |

### 9.5 Protocole Pixel (à dérouler ; Pixel branché en USB, déverrouillé)
1. Fichier de test (le seul changement sur le téléphone ; suppression : `adb shell rm -r /sdcard/Music/mpl-test`) :
   ```bash
   python3 tools/gen_sine_1khz.py
   adb shell mkdir -p /sdcard/Music/mpl-test
   adb push test-audio/sine_1k_-12dBFS_30s.wav /sdcard/Music/mpl-test/
   adb shell content call --uri content://media/ --method scan_volume --arg external_primary
   ```
2. Pour chaque build (B1, puis B2, puis B3) : `adb install -r <apk>`, ouvrir l'app, chercher « sine_1k », **même volume système** (noter l'index), haut-parleur, pas de Bluetooth.
3. Pour chaque moteur : lancer le sinus, **attendre 5 s**, puis **pendant la lecture** :
   ```bash
   tools/diag_loudness.sh -l B1-just_audio      # puis B1-media_kit, B2-media_kit, B3-just_audio…
   ```
4. Comparer : `tools/summarize_loudness.py 'loud-B1-*'` (lignes « differs » = candidats). Les dossiers `loud-*` contiennent les dumps complets (`audio.txt`, `flinger.txt`, `policy.txt`).
5. **Mesure objective du niveau** (le seul moyen de savoir si l'écart existe) : enregistrer le haut-parleur avec la **même chaîne** pour chaque moteur et chaque build (micro fixe, même distance, même pièce ; ou entrée ligne si sortie casque), 15 s en régime établi, puis :
   ```bash
   tools/measure_loudness.py B1-just_audio.wav B1-media_kit.wav --from 3 --to 14
   ```
   Écart < 0,5 dB = bruit ; ~3 dB = nettement audible. Le sinus pur évite l'effet du contenu musical et du décodeur.
6. Rendre compte : les `summary.txt`, le tableau du comparateur et les écarts en dB ; je classe ensuite la cause selon la matrice 9.4.

### 9.6 Ce que je ne peux pas dire aujourd'hui
Que `media_kit` est réellement plus faible (constat à l'oreille, **non mesuré**), ni pourquoi. Rien dans les relevés d'émulateur ne justifie un correctif ; aucun gain compensatoire n'est proposé.

### 9.7 Relevés Pixel 10 Pro (Android 17) — sinus 1 kHz −12 dBFS, haut-parleur, 05/10/2026
Volume `STREAM_MUSIC` : **index 1** (haut-parleur) identique pour tous les relevés ; build release, réduction active. Relevés par `tools/diag_loudness.sh` + `tools/summarize_loudness.py` (mesures de l'outil ; écoute et enregistrement non faits par l'outil).

| | B1 `just_audio` | B1 `media_kit` | B2 `media_kit` (`ao=audiotrack`) |
|---|---|---|---|
| Lecteur | AudioTrack | **OpenSL ES AudioPlayer** | AudioTrack |
| contentType / flags | MUSIC / `DEEP_BUFFER` | **UNKNOWN / aucun** | MOVIE / `DEEP_BUFFER` |
| **Thread de sortie** | `AudioOut_15` | **`AudioOut_2D`** | `AudioOut_15` |
| **Flags de la sortie** | `DEEP_BUFFER` | **`FAST` + `RAW`** | `DEEP_BUFFER` |
| Format HAL | PCM_FLOAT 48 kHz | **PCM_32_BIT** 48 kHz | PCM_FLOAT 48 kHz |
| Latence de la sortie | 70 ms | **1 ms** | (même sortie que `just_audio`) |
| Gain de piste `G/L/R/VS`, `PortVol` | −60 / 0 / 0 / 0, −60 dB | identique | identique |
| Chaînes d'effets sur le thread | 0 | 0 | 0 |
| Débit de la piste / tampon | 44 100 / 11 025 | 44 100 / 1 772 | 48 000 (rééchantillonné) / 5 772 |

**Ce que les relevés établissent (Pixel)** : (1) **aucun gain** (piste, mixeur, volume de flux) ne diffère entre les moteurs ; (2) **aucun effet logiciel** actif ni d'un côté ni de l'autre ; (3) `media_kit` par défaut est routé vers la sortie **`FAST|RAW`**, `just_audio` vers la sortie **`DEEP_BUFFER`** : ce sont deux flux de sortie distincts jusqu'au HAL ; (4) avec B2, `media_kit` rejoint exactement la sortie de `just_audio`.
**Ce qu'ils n'établissent pas** : que la sortie `FAST|RAW` soit plus faible à l'enceinte (le traitement du HAL/du DSP du Pixel en aval n'est pas visible par `dumpsys`). Cause **non déterminée** tant que B2 n'est pas comparé à l'oreille/à l'enregistrement (écoute et enregistrement à faire par l'utilisateur ; contentType non encore isolé : B3).

### 9.8 Retours d'écoute utilisateur et relevés B3 (Pixel, 05/10/2026)
**Écoute B2 (rapportée par l'utilisateur, non mesurée)** : avec `media_kit` en `ao=audiotrack`, le volume du sinus est perçu **similaire** à `just_audio`, au **haut-parleur** et avec les **Pixel Buds A-Series**. **Effet secondaire signalé** : au haut-parleur, un son « comme doublé » dans la **première seconde** de la piste (non analysé ; build/moteur exacts à confirmer ; hypothèses non testées : transitoire de démarrage de la sortie `DEEP_BUFFER`, rééchantillonnage 44,1 → 48 kHz de mpv, ou ancien moteur encore audible lors du changement).

**Relevés B3** (volume haut-parleur **index 5**, G = PortVol = −45 dB pour les deux moteurs ; changé par l'utilisateur depuis B1/B2, donc **non comparable en niveau aux essais précédents**) :
| | B3 `just_audio` (contentType forcé UNKNOWN) | B3 `media_kit` (défaut) |
|---|---|---|
| contentType | **UNKNOWN** | UNKNOWN |
| Sortie / flags | `AudioOut_15` / `DEEP_BUFFER` | `AudioOut_2D` / `FAST|RAW` |
| Format HAL | PCM_FLOAT | PCM_32_BIT |
| Gains, effets | identiques, 0 effet | identiques, 0 effet |

Avec B3, les deux moteurs ont le **même contentType** mais **pas la même sortie** : la comparaison à l'oreille isole donc le contentType. Résultat d'écoute B3 : voir §9.9.

### 9.9 Résultat d'écoute B3 et état de la conclusion (05/10/2026)
**Build confirmé** : l'APK installé sur le Pixel au moment de l'écoute est **B3** (MD5 `bbd2bbc1…`, installé à 01:59:33 ; le journal de l'app écrit `JA_CONTENT_TYPE=unknown` à chaque démarrage). L'utilisateur n'a pas changé de build depuis.

**Retour d'écoute (utilisateur, non mesuré)** : en B3, `media_kit` est perçu **légèrement plus faible** que `just_audio` ; le son « doublé » de B2 **n'est plus entendu**. L'utilisateur ne savait pas quel build était installé ; l'identification ci-dessus lève ce doute.

**Lecture**
- En B3 les deux moteurs ont le **même contentType (UNKNOWN)** et un gain identique (−45 dB, aucun effet), mais restent sur des **sorties différentes** (`just_audio` : `DEEP_BUFFER` ; `media_kit` : `FAST|RAW`). `media_kit` reste pourtant plus faible : **le contentType n'est pas la cause** (si c'était lui, `just_audio` en UNKNOWN serait descendu au niveau de `media_kit`).
- Avec B2 (`media_kit` sur la même sortie `DEEP_BUFFER` que `just_audio`) le volume était perçu similaire (§9.8).
- Conclusion **probable, non prouvée** : la différence perçue vient du **chemin de sortie** (`FAST|RAW` d'OpenSL ES contre `DEEP_BUFFER`), donc du traitement en aval (HAL/DSP du Pixel), non visible par `dumpsys`. Il n'y a **aucune mesure** en dB : l'écart est qualifié de « léger » à l'oreille, et B2 et B3 n'ont pas été comparés à volume égal (le volume a changé entre les deux).
- Le « doublé » est propre à B2 (`ao=audiotrack`) si l'utilisateur l'a entendu avec cette variante ; cause non analysée (hypothèses listées en §9.8).

**Options, aucune appliquée** : (a) garder `media_kit` par défaut (OpenSL ES), écart léger ; (b) adopter `ao=audiotrack` (volume similaire, mais « doublé » au démarrage et contentType MOVIE) ; (c) variante B4 de B2 pour supprimer le « doublé » (non construite). Mesure objective possible : enregistrement du haut-parleur + `tools/measure_loudness.py`, à volume identique.
