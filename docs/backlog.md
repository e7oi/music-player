# Backlog — MusicPlayer
Préfixe : MPL · Prochaine clé : MPL-039 · Dernière MAJ : 2026-10-21

> Importé le 2026-10-14 depuis `docs/sprints/sprint-2/SPRINT-2-START.md` v5 (§3 snapshot du backlog, §4 registre des décisions), copie fidèle du tableau, des détails de MPL-029 et du registre : aucun libellé reformulé, seuls les icônes de type et de priorité sont remplacées par du texte. Le snapshot de sprint reste figé ; ce fichier est désormais la référence vivante, écrite par Claude Code, relue et validée par le propriétaire. Format : `backlog-methodology.md` §13 (dépôt AI-tools). MPL-032 est absent du snapshot : sa clé reste réservée.
> Statuts : À faire → En cours → À tester → Terminé (+ Bloqué). Un ticket n'est « Terminé » que sur l'ordre « validé » du propriétaire, après un test réel en build release sur le Pixel (D14), et après le merge de sa PR.

## Actifs
| Clé | Type | Prio | Titre | Statut | Parent | Bloqué par |
|---|---|---|---|---|---|---|
| MPL-001 | Épique | P0 | Épique « Lecture locale » | En cours | — | — |
| MPL-004 | Épique | P1 | Épique « Expérience de type streaming » | À faire | — | — |
| MPL-005 | Épique | P2 | Épique « Voiture / Android Auto » 🔗 dépend de 001 ⚠️ D6 | À faire | — | — |
| MPL-010 | Bug | P2 | Avertissements de décodage `media_kit` sans effet audible constaté : FLAC avec étiquettes ID3 ; MP3 avec données non-MPEG après la dernière trame (MP3 A, MP3 B ; voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.5) — (origine des octets et fréquence dans la bibliothèque non établies ; pas de changement de code) | À faire | — | — |
| MPL-014 | Tâche technique | P2 | Prototype audio Windows et macOS (en pause) | À faire | — | — |
| MPL-015 | Tâche technique | P2 | Revoir dialogue et bandeau de permission ⚠️ un seul appareil testé | À faire | — | — |
| MPL-016 | Tâche technique | P0 | Maquettes UI/UX dans Claude Design (note : prévoir l'état « sources indisponibles » sans écraser la liste de pistes, défaut observé dans le prototype MPL-003) | À faire | — | — |
| MPL-037 | Récit | P0 | Bibliothèque du SSD par SAF : choix du dossier, droit d'accès persistant, parcours, lecture des tags et des pochettes dans les fichiers en arrière-plan, pochettes du stockage interne aussi (décision du 2026-10-15) (≈ 39 ms par fichier mesurés sur SAF, ≈ 100 s pour 2 600 fichiers), ouverture `fd://`, test à 10 000 pistes. Repris de MPL-018 le 2026-10-15 | À faire | MPL-001 | MPL-018 |
| MPL-038 | Récit | P1 | Réassociation d'un nouveau disque dont les chemins relatifs correspondent à ceux d'un disque absent (D23) et retrait d'un disque externe de la bibliothèque (demande du propriétaire du 2026-10-15 ; sort des playlists, favoris et statistiques du disque à trancher au cadrage). Repris de MPL-018 le 2026-10-15 | À faire | MPL-001 | MPL-037 |
| MPL-019 | Récit | P2 | Normalisation du volume (ReplayGain, préampli) | À faire | MPL-004 | — |
| MPL-020 | Épique | P0 | Épique « Qualité, CI et documentation » | En cours | — | — |
| MPL-026 | Tâche technique | P1 | CI code Flutter : format, analyse, tests, vulnérabilités, licences, **liste blanche des permissions** du manifest, vérification de l'empreinte de libmpv 🔗 | À faire | MPL-020 | — |
| MPL-027 | Tâche technique | P1 | Tests fonctionnels `integration_test` + procédure appareil réel 🔗 | À faire | MPL-020 | — |
| MPL-028 | Tâche technique | P1 | Fraîcheur des docs (en-têtes, modèle de PR, étape `/endSprint`) | À faire | MPL-020 | — |
| MPL-029 | Récit | P2 | Enrichissement en ligne opt-in (pochettes, paroles, métadonnées manquantes) 🔗 ⚠️ | Bloqué | MPL-004 | D20, MPL-018 |
| MPL-030 | Récit | P2 | Support Linux (desktop) — nice to have, non engagé 🔗 | Bloqué | — | D2 |
| MPL-031 | Tâche technique | P2 | Test négatif de la CI dans un dépôt privé jetable | À faire | MPL-020 | — |
| MPL-033 | Récit | P2 | Lecture de web-radio (France Info, Radio-Canada, France Inter, Radio Nova, CBC...), Phase 2 🔗 | Bloqué | MPL-004 | D26 |
| MPL-034 | Tâche technique | P2 | Auto-test : davantage de MP3 dans l'échantillon (92 % de la bibliothèque), un MP3 illisible gardé comme témoin, pistes en erreur signalées (« flaggées ») dans l'interface — (possible depuis MPL-003) | À faire | MPL-001 | — |
| MPL-035 | Tâche technique | P2 | Retrait du stockage amovible pendant la lecture : écouteur natif d'éjection puis `stop()` et fermeture du descripteur dans `PlayerController` (indépendant du moteur) ; vérifier la marge sous charge et avec d'autres descripteurs ouverts ; retirer le récepteur `ACTION_MEDIA_*` ; pas de reprise au rebranchement (décidé le 2026-10-15) ; descripteur proxy gardé comme alternative non testée. Voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3 🔗 MPL-017, D25. Depuis le 2026-10-15 : MPL-017 livre le port `VolumeEvents` et la réaction du contrôleur (BR-002) ; ce ticket livre l'adaptateur natif et le test sur le Pixel. À couvrir aussi (2026-10-15) : mesurer sur le Pixel le temps entre l'annonce d'éjection et la fermeture du fichier par mpv ; décider si l'éjection doit passer avant la commande en cours (elle attend aujourd'hui dans la file de `PlayerController`) ; garder le descripteur proxy comme plan B si la marge d'environ 1 s ne suffit pas | À faire | MPL-001 | — |
| MPL-036 | Tâche technique | P0 | Lecture en arrière-plan et contrôles du système (`audio_service` : service au premier plan, notification, écran verrouillé, touches média) et interruptions (`audio_session` : focus audio, débranchement du casque), branchés sur le `PlayerController` ; `AudioServiceActivity` remplace le moteur partagé de MPL-018 ; retour de `keep.xml` (cadré le 2026-10-21) | En cours | MPL-001 | — |

## Détails
### MPL-036
**Description.** Rendre la lecture utilisable hors de l'application : elle continue écran verrouillé et en arrière-plan, se commande depuis la notification, l'écran verrouillé et les touches média, et réagit aux appels, aux autres applications audio et au débranchement du casque. Cadrage du 2026-10-21, juste après MPL-018 (choix du propriétaire).

**Inclus.**
- `audio_service` : service au premier plan, session média, notification de lecture, écran verrouillé, touches média ; adaptateur sous `platform/media_session/` branché sur le `PlayerController` (FR-005, ADR-006).
- `MainActivity` hérite d'`AudioServiceActivity`, qui remplace l'objet `Shared` de MPL-018 ; canal MediaStore enregistré une fois par moteur (ADR-006).
- `audio_session` : port `AudioInterruptions` et règles de BR-005 dans un service du domaine, testé d'abord.
- Manifeste (service, récepteur des touches média, permissions) et `keep.xml` (MPL-013).
- Textes du canal de notification en ARB ; procédure sur le Pixel dans `HOWTO.md`.

**Exclusions.** Pochettes (MPL-037) ; Android Auto (MPL-005) ; reprise de la file après un redémarrage ; lecture aléatoire et répétition ; position et déplacement dans la piste dans l'écran de l'application (seule la notification les offre) ; écrans définitifs (MPL-016).

**Critères d'acceptation.**
```gherkin
# language: fr
Fonctionnalité: Lecture en arrière-plan et contrôles du système

  Scénario: Lecture écran verrouillé
    Soit une piste en lecture
    Quand l'utilisateur verrouille le téléphone pendant 15 minutes, téléphone débranché
    Alors la lecture continue et enchaîne les pistes

  Scénario: Commandes de la notification
    Soit une piste en lecture et la notification affichée
    Quand l'utilisateur touche "suivant" dans la notification
    Alors la piste suivante de la file démarre
    Et la notification et l'écran de l'application montrent la nouvelle piste

  Scénario: Touches média
    Soit une piste en lecture et un casque Bluetooth connecté
    Quand l'utilisateur appuie sur la touche lecture/pause du casque
    Alors la lecture se met en pause

  Scénario: Appel entrant
    Soit une piste en lecture
    Quand un appel arrive puis se termine sans autre commande de l'utilisateur
    Alors la lecture se met en pause pendant l'appel
    Et reprend à la fin de l'appel

  Scénario: Autre application audio
    Soit une piste en lecture
    Quand une autre application lance sa propre lecture
    Alors la lecture se met en pause et ne reprend pas d'elle-même

  Scénario: Casque débranché
    Soit une piste en lecture dans un casque
    Quand le casque est débranché
    Alors la lecture se met en pause

  Scénario: Arrêt
    Soit une piste en lecture
    Quand l'utilisateur touche "arrêt" dans la notification
    Alors la lecture s'arrête et la notification disparaît

  Scénario: Fermeture de l'application pendant la lecture
    Soit une piste en lecture
    Quand l'utilisateur fait le geste de retour puis retire l'application des applications récentes
    Alors la lecture continue sans plantage
    Et toucher la notification rouvre l'application sur la piste en cours
```

**Test appareil (Pixel, release).** Lecture écran verrouillé 15 minutes téléphone débranché, notification et écran verrouillé, touches d'un casque Bluetooth, appel entrant, autre application audio, débranchement du casque, atténuation pendant un guidage GPS (BR-005 règle 4), retour arrière et retrait des récentes. Procédure à écrire dans `HOWTO.md`.

**Fiches liées.** UC-002, FR-005, BR-005 (`docs/fonctionnel/`) ; ADR-006 (`docs/technique/decisions/`). Toutes `Active` (validées par le propriétaire le 2026-10-21). Utilise FR-001, BR-002, BR-003 et ADR-005 (`Active`).

**À valider (PO).** Aucun. Validés par le propriétaire le 2026-10-21 : focus audio et débranchement du casque inclus (BR-005) ; autorisation de notification déclarée sans être demandée (FR-005, exigence 11) ; commande « arrêt » (FR-005, exigence 2) ; reprise après un appel (BR-005, règle 3).

#### Livraison — 2026-10-21
Statut : ⚠️ partiel
Résumé : lecture en arrière-plan par `audio_service` (service au premier plan, notification « Lecture », écran verrouillé, touches média) branchée sur le `PlayerController`, et interruptions par `audio_session` (focus audio, débranchement du casque) avec une politique du domaine testée d'abord. `MainActivity` hérite d'`AudioServiceActivity` ; le processus se termine quand `audio_service` détruit son moteur. Rien n'a encore tourné sur le Pixel.
Fiches touchées : UC-002, FR-005, BR-005, ADR-006 : as-built écrits ; ADR-005 : as-built mis à jour ; ligne « À valider » ajoutée à BR-005 (règle 3).
Vérification : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test` → 0 fichier modifié, aucune anomalie, 158 tests passés (`test/domain/playback/interruption_policy_test.dart` : BR-005 ; `test/platform/player_audio_handler_test.dart` et `audio_session_interruptions_test.dart` : FR-005, classement des événements). `flutter gen-l10n` sans écart ; markdownlint et `check-repo.sh` au vert ; `flutter build apk --release` → 77,8 Mo, permissions `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS` ajoutées, pas d'`INTERNET`, 7 icônes `audio_service_*` présentes. Scénarios Gherkin de l'appareil : `HOWTO.md` §12.
Test appareil (Pixel, release) : non testé (Pixel déconnecté d'adb). Émulateur Android 16, release, par adb : service au premier plan `mediaPlayback`, notification, session `PLAYING` avec titre et « arrêt », focus `USAGE_MEDIA`, touches média, perte passagère puis reprise (préviseur de YouTube Music), retour arrière, retrait des récentes, arrêt, changement de piste sans coupure de la session, arrêt après retour arrière puis redémarrage : OK, aucun plantage.
Revue QA : ⚠️ (2 tours, sous-agent à contexte neuf ; lecture, revue obligatoire : une session séparée `>>> REVUE` est possible). Corrigés : demande de focus mise en cache par `audio_session` (un second « lecture » pendant un appel jouait par-dessus), événements traités en série, erreur qui arrêtait la politique, session et focus gardés pendant un changement de piste, moteur détruit par `audio_service` sous un mpv vivant, tests manquants (classement, artiste, album, durée), tests dépendants du temps. Restants : reprise après un long appel en arrière-plan (Android 12+) et touche média après la mort du processus, à vérifier sur le Pixel ; moteur créé sans activité sans écouteur de fin ; fenêtre étroite de fermeture au lancement ; règle 3 de BR-005 (« À valider »). Non vérifié : tout comportement sur le Pixel ; atténuation OpenSL ES (règle 4).
Description de PR : titre `feat(playback): add background playback and system controls (MPL-036)`. What: `audio_service` foreground media service, notification, lock-screen controls and media buttons, routed to the `PlayerController` by a `BaseAudioHandler` under `platform/media_session/`; audio focus and headphone unplugging through `audio_session` behind a new `AudioInterruptions` port, with the BR-005 rules in a domain `InterruptionPolicy`; `MainActivity` extends `AudioServiceActivity` (its cached engine replaces the shared engine of MPL-018) and ends the process when audio_service destroys that engine; `keep.xml` for the notification icons; notification channel texts in ARB; `POST_NOTIFICATIONS` declared, never requested. Why: playback has to go on and be controlled outside the app, and must not play over a call or out of the speaker (UC-002, FR-005, BR-005, ADR-006). How tested: format, `flutter analyze`, `dart analyze` and 158 unit tests green; release APK built (77.8 MB, no `INTERNET`, icons kept); emulator (Android 16, release) over adb: foreground service, notification, session, focus, media keys, transient focus loss and resume, back, task removal, stop, track change; device: not tested (HOWTO §12). Known gaps: Pixel test pending; resuming after a long call in the background and a media button after process death may hit Android 12+ foreground-service limits; seeking during an interruption does not cancel the resume (owner decision pending); new transitive dependencies `flutter_cache_manager`, `http`, `sqflite` (for remote artwork, unused) to review in MPL-026; Kotlin glue without unit tests (CLAUDE.md exception).
Décisions prises en route : processus terminé quand `audio_service` détruit son moteur (mpv ne peut pas être libéré sans l'isolat Dart) ; délai de 0,5 s avant de libérer la session et le focus à l'arrêt, pour le changement de piste ; une demande de focus en échec compte comme un refus.
À valider (PO) : BR-005, règle 3 — un déplacement dans la piste ou « précédent » pendant l'interruption n'annule pas la reprise ; `CLAUDE.md` (règles Android) dit encore que la permission de notification est demandée en natif, contraire à FR-005 exigence 11 validée.

### MPL-018
**Description.** Rendre la bibliothèque du stockage interne réelle : indexer les pistes du téléphone dans la base, les afficher dans une liste minimale et en lire une avec le `PlayerController` de MPL-017. Cadrage du 2026-10-15 : MPL-018 découpé en trois tickets (MPL-018, MPL-037, MPL-038), choix du propriétaire.

**Inclus.**
- Base Drift, schéma v1 (disques, pistes), port `LibraryRepository` (ADR-004).
- Choix des dossiers du stockage interne à indexer, `Music/` proposé par défaut ; indexation par MediaStore de ces dossiers, au démarrage et sur demande, sans lecture des tags (FR-003, BR-004).
- Autorisation `READ_MEDIA_AUDIO` en natif (FR-004).
- Canal natif MediaStore, `TrackSourceOpener` et `VolumeEvents` du stockage interne, câblage du `PlayerController` dans `app/providers/` ; `minSdk` 30 (ADR-005).
- Liste minimale des pistes et barre de lecture temporaire, textes en ARB (UC-001).

**Exclusions.** SSD par SAF, tags lus dans les fichiers, pochettes, test à 10 000 pistes (MPL-037) ; réassociation et retrait d'un disque (MPL-038) ; recherche, tri, filtres ; écrans définitifs (MPL-016) ; notification et arrière-plan (MPL-036) ; éjection (MPL-035).

**Critères d'acceptation.**
```gherkin
# language: fr
Fonctionnalité: Bibliothèque du stockage interne

  Scénario: Premier lancement avec autorisation
    Soit l'application installée pour la première fois et des fichiers audio dans le stockage interne
    Quand l'utilisateur ouvre l'application et accepte l'accès aux fichiers audio
    Alors l'indexation démarre en arrière-plan
    Et la liste affiche les pistes du stockage interne

  Scénario: Choix des dossiers au premier lancement
    Soit l'accès accordé, un dossier "Music" et un dossier de messagerie contenant de l'audio
    Quand la liste des dossiers s'affiche
    Alors "Music" est coché et le dossier de messagerie ne l'est pas
    Et seules les pistes des dossiers cochés sont indexées après confirmation

  Scénario: Dossier décoché
    Soit deux dossiers cochés et leurs pistes indexées
    Quand l'utilisateur décoche l'un des deux
    Alors les pistes de ce dossier disparaissent de la bibliothèque
    Et celles de l'autre dossier restent, avec la même identité interne

  Scénario: Autorisation refusée
    Soit l'accès aux fichiers audio refusé
    Quand l'application s'ouvre
    Alors un message explique pourquoi l'accès est nécessaire
    Et un bouton redemande l'accès, ou ouvre les réglages si Android ne le propose plus

  Scénario: Lecture d'une piste de la liste
    Soit la liste des pistes affichée
    Quand l'utilisateur touche la troisième piste
    Alors la lecture démarre sur cette piste
    Et la file contient toute la liste dans l'ordre affiché

  Scénario: Fichier ajouté
    Soit une piste indexée et un nouveau fichier audio copié dans le stockage interne
    Quand l'utilisateur actualise la bibliothèque
    Alors la nouvelle piste apparaît
    Et l'identité interne de la piste déjà indexée est inchangée

  Scénario: Informations modifiées
    Soit une piste indexée dont le fichier a été modifié
    Quand la bibliothèque est réindexée
    Alors ses informations sont mises à jour
    Et son identité interne est inchangée

  Scénario: Fichier supprimé
    Soit une piste indexée dont le fichier a été supprimé
    Quand la bibliothèque est réindexée
    Alors la piste disparaît de la bibliothèque

  Scénario: Titre absent
    Soit un fichier sans titre dans MediaStore
    Quand la liste s'affiche
    Alors la piste apparaît sous le nom de son fichier

  Scénario: Indexation sans blocage
    Soit une indexation en cours
    Quand l'utilisateur fait défiler la liste ou met la lecture en pause
    Alors l'écran répond pendant l'indexation
```

**Test appareil (Pixel, release).** Premier lancement (autorisation accordée puis refusée), indexation de la bibliothèque réelle, lecture d'une piste, ajout et suppression d'un fichier puis « Actualiser ». Procédure à écrire dans `HOWTO.md`.

**Fiches liées.** UC-001, FR-003, FR-004, BR-004 (`docs/fonctionnel/`) ; ADR-004, ADR-005 (`docs/technique/decisions/`). Toutes `Active` (validées par le propriétaire le 2026-10-15 ; FR-003, UC-001 et ADR-004 après révision pour le choix des dossiers). Utilise FR-001, BR-001 à BR-003 (`Active`).

**À valider (PO).** Aucun. Validés par le propriétaire le 2026-10-21 et devenus des règles : garde-fou contre un résultat vide de MediaStore (FR-003, exigence 8) ; « dialogue d'abord, puis réglages » (FR-004, exigence 4). Réponses reportées (2026-10-15) : `minSdk` 30 accepté (ADR-005) ; pochettes rattachées à MPL-037.

#### Livraison — 2026-10-21
Statut : ✅ fait
Résumé : bibliothèque du stockage interne : base Drift (schéma v1), choix des dossiers (`Music/` par défaut), indexation par MediaStore, autorisation `READ_MEDIA_AUDIO` en natif, écran temporaire de la bibliothèque et barre de lecture branchés sur le `PlayerController`. Le test sur le Pixel a révélé des plantages de mpv à la fermeture de l'activité : `MainActivity` garde désormais un seul moteur Flutter pour le processus.
Fiches touchées : UC-001, FR-003, FR-004, BR-004, ADR-004, ADR-005 : as-built mis à jour ; FR-003 (exigence 8) et FR-004 (exigence 4) révisées après validation du propriétaire (2026-10-21). Nouveau document : `docs/dependency-exceptions.md`.
Vérification : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test` → 0 fichier modifié, aucune anomalie, 129 tests passés. Scénarios Gherkin couverts par `test/features/library/` (premier lancement, autorisation refusée, choix et décochage des dossiers, lecture avec la file dans l'ordre affiché), `test/domain/library/` (ajout, modification, suppression, indexation sans blocage) et `test/data/db/` (identité des pistes). `flutter gen-l10n`, `build_runner` et `drift_dev make-migrations` sans écart ; `check-repo.sh` et markdownlint au vert ; `flutter build apk --release` → 75,9 Mo, `READ_MEDIA_AUDIO` et `READ_EXTERNAL_STORAGE` (jusqu'à l'API 32), pas d'`INTERNET`, `minSdk` 30. Contrat `media_kit` sur le Pixel (`flutter drive --profile`) : 8 réussis, 2 sautés (source par descripteur, hors SSD).
Test appareil (Pixel 10 Pro, Android 17, release, environ 2 600 pistes) : `HOWTO.md` §11, étapes 1 à 10 OK le 2026-10-21 (propriétaire ; étapes 7 et 8 avec un fichier de test placé et retiré par adb, l'étape 8 vérifiée par adb). Plantages de mpv constatés (`SIGSEGV` dans `mpv/mpv core` et `mpv/opener`, rappel de réveil libéré) et deux pistes jouées en même temps, après une fermeture de l'activité par le geste ou la touche retour : reproduits par adb, corrigés, puis rejoués par adb sur la build finale (geste et touche retour pendant la lecture, accueil, réouverture, changement de piste : une seule sortie audio, aucun plantage). Parcours d'autorisation repris par adb avec le nouveau canal (retrait, nouvelle demande et accord, refus définitif puis réglages) : OK. Étape 11 (retour arrière pendant la lecture) par le propriétaire sur la build finale : OK le 2026-10-21.
Revue QA : ✅ (implémentation : 2 tours ; correctif du moteur partagé : 1 tour, sous-agent à contexte neuf ; lecture, autorisations et base de données, revue obligatoire : une session séparée `>>> REVUE` est possible). Corrigés au dernier tour : moteur détruit si un intent le demande (`shouldDestroyEngineWithHost`), demande d'autorisation pendant un changement de configuration, résultat d'autorisation venant d'une autre instance de l'activité, `openAppSettings` sans activité, as-built et bloc Livraison. Limites restantes : dossiers proposés au premier niveau seulement ; deux instances de l'activité (lancement explicite par une autre application) partagent un moteur et la première montre un écran vide. Non vérifié par la revue : comportements sur appareil (vérifiés depuis par adb, voir ci-dessus), compilation Kotlin (faite depuis par la build release).
Description de PR : titre `feat(library): add the internal-storage library (MPL-018)`. What: Drift database (schema v1: disks, chosen folders, tracks) behind a `LibraryRepository` port; folder choice of the internal storage from MediaStore (top-level folders, Music by default); indexing that keeps track identities across rescans (BR-004), refusing an empty MediaStore result while tracks exist; a MediaStore and permission channel written in Kotlin (no plugin); internal-storage `TrackSourceOpener` and `VolumeEvents`; a temporary library screen and playback bar wired to the `PlayerController`; one Flutter engine per process, provided by `MainActivity`, so that closing the activity no longer kills the Dart isolate under a running mpv (part of MPL-036 brought forward, owner decision of 2026-10-21); `minSdk` 30; CI check of generated Drift code and schema. Why: MPL-018 as split on 2026-10-15; the app can now play real tracks; the Pixel test showed mpv crashes and two simultaneous players after a back gesture. How tested: format, `flutter analyze`, `dart analyze` and 129 unit and widget tests green locally; Drift tests on an in-memory database; release APK built (75.9 MB, no `INTERNET`); device: Pixel 10 Pro, Android 17, release build, HOWTO §11 steps 1-11 passed by the owner (step 11 on the final build); back gesture, back key and home during playback replayed over adb on the final build (one audio output, no crash); permission flows replayed over adb. Known gaps: without a foreground service Android may stop the app in the background (MPL-036); folders are offered at the top level only; a second activity instance launched by another app shows a blank screen; `build_runner` held at 2.16.2 and `sqlite3_flutter_libs` 0.6.0+eol pulled by `drift_flutter` (`docs/dependency-exceptions.md`); Kotlin glue has no unit test (CLAUDE.md exception).
Décisions prises en route : dossiers proposés au premier niveau du stockage interne ; `driftDatabase()` de `drift_flutter` pour ouvrir la base ; état « jamais demandé » ajouté à l'autorisation pour ne demander qu'au premier lancement ; deux dépendances en dérogation (`docs/dependency-exceptions.md`) ; un seul moteur Flutter par processus dès MPL-018 et MPL-036 juste après (choix du propriétaire, ligne « À numéroter » dans Décisions).
À valider (PO) : aucun. Garde-fou MediaStore vide (FR-003) et « dialogue d'abord, puis réglages » (FR-004) validés le 2026-10-21.

### MPL-017
**Description.** Poser le projet Flutter de production et le cœur de lecture indépendant du moteur, avec une CI minimale qui permet au code d'arriver sur `main`. Cadrage du 2026-10-15, périmètre découpé validé par le propriétaire.

**Inclus.**
- Projet Flutter à la racine, Android seulement, versions épinglées, `.gitignore`, `HOWTO.md` §2 mis à jour (ADR-001).
- Tests d'architecture (`test/architecture/`) pour les règles de dépendance de `CLAUDE.md`.
- Job `code-checks` (format, analyse, tests) et Dependabot `pub` (ADR-003).
- Ports `AudioEngine`, `VolumeEvents` et `TrackSourceOpener`, avec leurs fakes ; suite de contrat `AudioEngine` ; adaptateur `media_kit` (ADR-002).
- `PlayerController` : commandes de FR-001, retrait d'une piste de la file (FR-002), saut des pistes indisponibles (BR-001), éjection (BR-002), problèmes du moteur (BR-003).

**Exclusions.** Écouteur natif d'éjection et test de retrait sur le Pixel (MPL-035) ; réassociation d'un disque, base Drift, parcours et tags (MPL-018) ; ouverture réelle des pistes MediaStore et SAF (MPL-018, MPL-035) ; notification et arrière-plan (`audio_service`, MPL-036) ; interface (MPL-016) ; CI complète (MPL-026) ; Windows et macOS (MPL-014).

**Critères d'acceptation.**
```gherkin
# language: fr
Fonctionnalité: Fondations du projet de production

  Scénario: Le code ne peut pas arriver sur main sans contrôles
    Soit une pull request qui modifie du code Dart
    Quand la CI s'exécute
    Alors le job "code-checks" lance le format, l'analyse stricte et les tests
    Et il échoue si l'une de ces étapes échoue

  Scénario: Une règle de dépendance est violée
    Soit un fichier de "lib/domain/" qui importe "package:flutter"
    Quand les tests d'architecture s'exécutent
    Alors ils échouent en citant le fichier et l'import interdit

  Scénario: Le moteur respecte son contrat
    Soit la suite de contrat AudioEngine
    Quand elle s'exécute contre le fake en CI et contre l'adaptateur media_kit sur le Pixel
    Alors open ne démarre pas la lecture
    Et completed est émis une seule fois par piste
    Et stop rend la main après la libération des ressources et peut être rappelé sans effet

  Scénario: Enchaînement des pistes
    Soit une file de trois pistes disponibles et la lecture lancée sur la première
    Quand la première piste se termine
    Alors la deuxième piste est chargée et lue
    Et l'intention de lecture reste vraie

  Scénario: Pistes d'un disque absent sautées
    Soit une file A, B, C, D où B et C sont sur un disque indisponible
    Quand A se termine
    Alors D est chargée et lue
    Et un seul signalement indique 2 pistes ignorées et le disque concerné
    Et le moteur n'a jamais reçu B ni C

  Scénario: Aucune piste disponible
    Soit une file dont toutes les pistes sont sur un disque indisponible
    Quand la lecture est demandée
    Alors rien n'est chargé et la lecture reste arrêtée
    Et le signalement indique le nombre de pistes ignorées

  Scénario: Éjection du disque de la piste en cours
    Soit une piste du disque S en cours de lecture
    Quand l'éjection du disque S est annoncée
    Alors le moteur est arrêté et son arrêt terminé
    Et seulement ensuite le disque S est marqué indisponible
    Et la lecture reste arrêtée sur la piste éjectée, avec un signalement

  Scénario: Éjection d'un autre disque
    Soit une piste du stockage interne en cours de lecture et un disque S présent
    Quand l'éjection du disque S est annoncée
    Alors la lecture continue
    Et les pistes de S seront sautées

  Scénario: Échec du moteur sur une piste
    Soit une file A, B et la lecture de A
    Quand le moteur signale un échec sur A
    Alors l'échec est signalé avec la piste concernée
    Et B est chargée et lue

  Scénario: Échecs consécutifs
    Soit une file dont les 3 premières pistes échouent
    Quand le moteur signale le 3e échec consécutif
    Alors la lecture s'arrête avec un signalement

  Scénario: Piste précédente
    Soit la lecture de B dans une file A, B
    Quand "précédent" est demandé à plus de 3 s de lecture
    Alors B reprend au début
    Quand "précédent" est demandé à moins de 3 s de lecture
    Alors A est chargée et lue

  Scénario: Retrait d'une piste de la file
    Soit une file A, B, C et la lecture de A
    Quand B est retirée de la file
    Alors la file devient A, C
    Et A continue d'être lue

  Scénario: Retrait de la piste en cours
    Soit une file A, B, C et la lecture de B
    Quand B est retirée de la file
    Alors C est chargée et lue

  Scénario: Retrait de la seule piste
    Soit une file A et la lecture de A
    Quand A est retirée de la file
    Alors le moteur est arrêté et la file est vide

  Scénario: Avertissement du moteur
    Soit la lecture de A
    Quand le moteur signale un avertissement
    Alors l'état du lecteur ne change pas
    Et l'avertissement est compté
```

**Test appareil (Pixel, release).** Suite de contrat contre l'adaptateur `media_kit` (`flutter test integration_test`) ; l'application se lance en build release.

**Fiches liées.** FR-001, BR-001, BR-002, BR-003 (`docs/fonctionnel/`) ; ADR-001, ADR-002, ADR-003 (`docs/technique/decisions/`) : `Active` (validées par le propriétaire le 2026-10-15). FR-002 (retrait d'une piste de la file, ajoutée le 2026-10-15) : `Active` (validée le 2026-10-15).

**À valider (PO).**
- Aucun. Réponses du propriétaire (2026-10-15) reportées dans les fiches ; `code-checks` est un contrôle requis de `protect-main` depuis le 2026-10-15.


#### Livraison — 2026-10-15
Statut : ⚠️ partiel
Résumé : projet Flutter de production à la racine (Flutter 3.47.7, Android), tests d'architecture, job CI `code-checks`, ports `AudioEngine` / `VolumeEvents` / `TrackSourceOpener` avec fakes et contrat exécutable, `PlayerController` (FR-001, FR-002, BR-001 à BR-003), adaptateur `media_kit`. Rien n'a tourné sur le Pixel ; deux tours de revue QA, points restants ci-dessous.
Fiches touchées : FR-001, FR-002, BR-001, BR-002, BR-003, ADR-001, ADR-002, ADR-003 : as-built mis à jour ; lignes « À valider » ajoutées à FR-002, BR-002, BR-003.
Vérification : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test` → 0 fichier modifié, aucune anomalie, 62 tests passés (scénarios Gherkin du ticket couverts par le groupe correspondant de `test/domain/playback/player_controller_test.dart`, le contrat sur le fake et les tests d'architecture) ; `flutter gen-l10n` sans écart, aucune clé manquante ; `.github/scripts/check-repo.sh` au vert ; `flutter build apk --release` → APK de 64,5 Mo sans permission `INTERNET`. Job `code-checks` sur GitHub : au vert sur la PR #7 (2 min 41 s), comme les contrôles de `docs-ci`.
Test appareil (Pixel, release) : lancement de l'application fait (2026-10-15, propriétaire) : l'écran d'accueil affiche « La bibliothèque apparaîtra ici. » ; contrat `media_kit` (`HOWTO.md` §10) passé le 2026-10-15 en mode profile (`flutter drive --profile`, lancé par Claude Code sur le Pixel) : `All tests passed.` ; `flutter drive` refuse la release, le profile est compilé en natif (AOT). Messages `libOpenSLES: Configuration error: unknown key` dans la sortie, sans effet sur les tests. Non testés sur appareil : éjection, descripteurs `fd://`, lecture en arrière-plan (hors périmètre).
Revue QA : ⚠️ (2 tours, sous-agent à contexte neuf ; lecture et stockage, revue obligatoire : une session séparée `>>> REVUE` est possible). Corrigés : marche arrière bloquée sur une piste illisible, libération d'un descripteur que mpv pouvait encore lire (`idle-active` passe à vrai avant la fermeture du fichier, vérifié dans les sources de mpv v0.39.0 ; `stop()` attend désormais la propriété `path`), compteur d'échecs après arrêt, classement des journaux, traçabilité, en-tête de commit. Restants : délai de 5 s de `stop()` (« À valider » BR-002) ; « précédent » vers une piste illisible (« À valider » BR-003) ; un échec d'ouverture invisible à la fois sur `idle-active` et dans les journaux bloquerait la lecture (risque résiduel, ADR-002) ; une position tardive de la piste précédente peut encore fausser « précédent » (mineur, sans test). Non vérifié par la revue : tout comportement sur appareil (contrat `media_kit` et fichier illisible passés depuis sur le Pixel, en mode profile ; éjection et marge avant l'arrêt par Android non testées), exécution du job sur GitHub.
Description de PR : titre `feat(playback): add production foundations and PlayerController (MPL-017)`. What: Flutter project at the repository root (Flutter 3.47.7, Android only, Gradle 9.3.1, AGP 9.1.1, Kotlin 2.4.0), architecture tests for the CLAUDE.md dependency rules, a minimal `code-checks` CI job and pub Dependabot updates, the `AudioEngine`, `VolumeEvents` and `TrackSourceOpener` ports with fakes and an executable engine contract, an engine-independent `PlayerController` (queue commands, track removal, skipping tracks of absent disks, ejection handling, failure handling), and a `media_kit` adapter. Why: D2 and D3, the MPL-017 scope agreed on 2026-10-15; no code may reach `main` without a code CI job. How tested: format, `flutter analyze`, `dart analyze` and 62 unit and widget tests green locally; release APK built (no `INTERNET` permission); device: Pixel 10 Pro, the app starts in a release build and shows the localized placeholder; the `media_kit` engine contract passes in profile mode (`flutter drive --profile`, HOWTO §10; `flutter drive` refuses release mode). Known gaps: ejection and `fd://` descriptors are not tested on the device (MPL-035); no provider wiring for the controller until the `VolumeEvents` and `TrackSourceOpener` adapters exist (MPL-035, MPL-018); `stop()` may return with a descriptor still open after a 5 s timeout (owner decision pending); end-file is inferred from `idle-active` because `media_kit` does not expose it; libmpv is downloaded at build time without a checksum (MPL-026); `keep.xml` waits for `audio_service` (MPL-036).
Décisions prises en route : Flutter mis à jour de 3.47.6 à 3.47.7 sur le Mac (accord du propriétaire, D30) ; identifiant Android `net.trtl3.musicplayer`, le même que le prototype (choix du propriétaire, ligne proposée dans Décisions) ; AGP 9.1.1 plutôt que 9.2.x (hors de la table de compatibilité de Flutter 3.47.7) ; `dart analyze` ajouté en CI, car `flutter analyze` n'exécute pas le plugin `riverpod_lint` ; `CLAUDE.md` (Outillage, Définition de « terminé ») mis à jour avec `dart analyze` et `flutter drive` (accord du propriétaire ; `--release` corrigé en `--profile` après l'essai sur le Pixel) ; contrat sur appareil lancé par `flutter drive --profile`, car `flutter test integration_test` ne compile qu'en debug et `flutter drive` refuse la release.
À valider (PO) : aucun. Les lignes « À valider » de FR-002, BR-002 et BR-003 ont été validées par le propriétaire le 2026-10-15 et sont devenues des règles (FR-002 exigence 7, BR-002 règle 7, BR-003 règles 3 et 4)

### MPL-029
**Détails — MPL-029.** Désactivé par défaut, opt-in par fonction (pochettes, paroles) ; cache local ; variante de build séparée (`offline` sans `INTERNET`, `enrichi` avec) ; objectif 4 du PRD reformulé. Risques : une requête révèle l'écoute à un tiers ; conditions d'usage et licences des sources (MusicBrainz, Cover Art Archive, LRCLIB, Wikimedia) **non vérifiées** ; le gabarit Flutter déclare `INTERNET` en debug/profile, donc une fonction en ligne ne se valide qu'en build release (D14). API Spotify/Deezer écartées (D9).

## Terminés
| Clé | Titre | Clos le | Note |
|---|---|---|---|
| MPL-002 | Prototype audio Android | 07/10/2026 | Clos (07/10/2026) |
| MPL-017 | Fondations du projet de production : projet Flutter, CI minimale, `PlayerController`, adaptateur `media_kit` | 15/10/2026 | Validé par le propriétaire, PR #7 fusionnée (15/10/2026). Pixel 10 Pro : application lancée en build release ; contrat `media_kit` passé en mode profile. Non testés sur appareil : éjection et descripteurs `fd://` (MPL-035) |
| MPL-018 | Bibliothèque du stockage interne : base Drift, choix des dossiers et indexation par MediaStore, autorisation `READ_MEDIA_AUDIO`, liste et barre de lecture minimales, moteur Flutter unique par processus | 21/10/2026 | Validé par le propriétaire, PR #9 fusionnée (21/10/2026). Pixel 10 Pro, Android 17, release : `HOWTO.md` §11, étapes 1 à 11 OK ; plantages de mpv à la fermeture de l'activité corrigés |
| MPL-003 | Sources de bibliothèque : stockage amovible (SSD USB-C), test Pixel (titre proposé) 🔗 ⚠️ | 08/10/2026 | Terminé avec réserves (08/10/2026) : SSD lu par SAF avec les deux moteurs ; tags non lus pendant le parcours (≈ 39 ms par fichier mesurés) ; retrait pendant la lecture traité en spike seulement (MPL-035) ; voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4 |
| MPL-006 | Auto-test sur échantillon, isolé, exporté | 07/10/2026 | Clos (07/10/2026) : 13 pistes par moteur ; élargissement de l'échantillon MP3 : MPL-034 |
| MPL-007 | Console de test : recherche, tri, filtre par format | 07/10/2026 | Clos (07/10/2026) |
| MPL-008 | Lecture coupée après ~1 min écran verrouillé | — | Résolu (cause initiale non déterminée) |
| MPL-009 | WMA non lu par `just_audio` | 05/10/2026 | Abandonné — WMA = 1,2 % de la bibliothèque, seul `media_kit` le lit, non prioritaire (D16, 05/10/2026) |
| MPL-011 | Écart de volume entre moteurs | — | Clos (accepté, D13) |
| MPL-012 | Permission de notification | — | Résolu |
| MPL-013 | Icônes `audio_service` supprimées en release | — | Résolu |
| MPL-021 | Licence GPL-3.0-or-later (© 2026 Eloi BERTIN) | 06/10/2026 | Résolu (06/10/2026) |
| MPL-022 | Docs : PRD v0.2, README, CHANGELOG, HOWTO, snapshots du Sprint 1 | 06/10/2026 | Résolu (06/10/2026) |
| MPL-023 | `main` orpheline, dépôts séparés, protection de branche | 08/10/2026 | Résolu (08/10/2026) : `main` orpheline, deux dépôts, ruleset `protect-main` appliqué ; push direct refusé (test réel) |
| MPL-024 | CI documentaire (markdownlint, liens, gitleaks, cohérence) | 07/10/2026 | Résolu (07/10/2026) |
| MPL-025 | Audit avant publication (historique, e-mails), puis dépôt public 🔗 | 08/10/2026 | Résolu (08/10/2026) : audit fait, dépôt public depuis le 08/10/2026 |

## Décisions
| Code | Titre | Statut | Justification · items liés |
|---|---|---|---|
| D1 | Projet **open source** ; licence GPL-3.0-or-later ; titulaire Eloi BERTIN (2026) | Tranchée 05/10/2026 | |
| D2 | Moteur audio : `media_kit` (libmpv/FFmpeg) est le **moteur unique** de l'application réelle, derrière une **interface indépendante du moteur** (`PlayerController`, MPL-017) qui permet de changer de moteur plus tard ; `just_audio` n'est pas repris dans l'application réelle, le prototype reste la référence. Motifs : un seul moteur à tester et à maintenir, WMA lisible (D16 : toujours non prioritaire), ReplayGain possible via mpv (MPL-019, D13), même moteur sur Windows et macOS. Conséquences acceptées : les WARN de MPL-010 (sans effet audible constaté) ; poids de l'APK non mesuré (risque à suivre). Tests SSD du 08/10/2026 : les deux moteurs lisent le SSD et réagissent de la même façon au retrait ; remplace la recommandation de `docs/sprints/sprint-1/RESULTS.md` §6 (snapshot Sprint 1) | Tranchée 09/10/2026 | |
| D3 | Gestion d'état et base de données : Base locale : SQLite via **Drift** (requêtes typées, migrations de schéma versionnées, flux réactifs, exécution en isolate, recherche plein texte FTS5 possible). Gestion d'état : **Riverpod**. Motif de la base : le modèle D23 est relationnel (disques, pistes par disque + chemin relatif, playlists mêlant plusieurs disques) ; Isar (état de maintenance en 2026 non vérifié) et ObjectBox (plus de natif, relations moins naturelles) ne sont pas retenus. Reporté à l'implémentation : la version exacte de Riverpod et l'usage ou non de sa génération de code (en plus de celle de Drift) | Tranchée 09/10/2026 | |
| D4 | Nom définitif de l'application | Ouverte | |
| D5 | Canaux de distribution (la release est signée avec la clé debug : TODO avant toute distribution) | Ouverte | |
| D6 | Android Auto et Google Play | Ouverte | |
| D7 | Identifiant d'organisation `net.trtl3` | Tranchée | |
| D8 | Flutter/Dart, codebase unique | Tranchée | |
| D9 | Lecteur local ; aucun catalogue sous licence ; pas de copie de l'identité Spotify/Deezer | Tranchée | |
| D10 | **Android plateforme principale et prioritaire** ; Windows et macOS en pause (MPL-014) ; iOS hors périmètre ; Linux nice to have (MPL-030) | Tranchée (révisée 06/10/2026) | |
| D11 | Android : MediaStore comme voie principale, pas de sélecteur de dossier | Remplacée par D25 | |
| D12 | Android Auto : Épique P2 (MPL-005), architecture audio prévue dès le départ | Tranchée | |
| D13 | `media_kit` avec sa sortie par défaut (OpenSL ES), sans `ao=audiotrack` ; écart léger accepté ; normalisation par ReplayGain (MPL-019) | Tranchée | |
| D14 | Valider tout item en **build release** avant fermeture (HOWTO §6) | Tranchée | |
| D15 | Aucune requête réseau sortante (pas de `INTERNET` en release). Pourra être précisée par D20 | Tranchée | |
| D16 | WMA non prioritaire ; MPL-009 abandonné | Tranchée 05/10/2026 | |
| D17 | `main` orpheline et protégée ; merge par PR avec contrôles au vert ; push libre des branches de travail. Protection appliquée le 08/10/2026 (ruleset `protect-main`), push direct refusé en test réel | Tranchée 05/10/2026 | |
| D18 | Méthodologies hors dépôt | Remplacée par D21 | |
| D19 | Dépôt public après licence + `main` + CI documentaire + audit (MPL-025) | Tranchée 05/10/2026 | |
| D20 | Enrichissement en ligne optionnel : opt-in par fonction, cache local, variante de build séparée. Précisera D15. À trancher avant l'Épique MPL-004 | Ouverte | |
| D21 | Organisation : documents à la racine ; méthodologies dans le dépôt privé `ai-tools` ; snapshots dans `docs/sprints/` | Tranchée 05/10/2026 | |
| D22 | Les fichiers du dépôt sont modifiés par Claude Code ; ce Project rédige les prompts, challenge et relit | Tranchée 06/10/2026 | |
| D23 | Modèle de « source de bibliothèque » : une source est un **disque** : le stockage interne (« Local ») ou un volume amovible, identifié par l'UUID de son système de fichiers. Un disque contient les dossiers choisis par l'utilisateur ; une piste est identifiée par (disque, chemin relatif). Les pistes d'un disque absent restent dans la bibliothèque, grisées ; pendant la lecture, elles sont sautées avec un message (du type « 12 pistes ignorées : SSD absent »). Une playlist peut mêler les pistes de plusieurs disques. Si l'utilisateur ajoute un disque dont les chemins relatifs correspondent à ceux d'un disque absent, l'application propose de le réassocier (playlists, favoris et statistiques conservés). Dans l'interface, la source est le disque (« SSD : 26 pistes, indisponible »), et non chaque dossier comme dans le prototype | Tranchée 09/10/2026 (ouverte depuis le 06/10/2026) | |
| D24 | Le prototype reste dans un dépôt privé séparé (`music-player-prototype`) ; `music-player` ne contient que `main` et ses branches de travail | Tranchée 07/10/2026 | |
| D25 | Android : MediaStore pour le stockage interne, sélecteur Android (SAF) pour le stockage amovible USB ; remplace D11. Accès SSD par SAF vérifié sur le Pixel 10 Pro (MPL-003) ; risque du retrait pendant la lecture traité par le spike (MPL-035) | Tranchée 09/10/2026 | |
| D26 | Toute fonction en ligne (dont la web-radio et l'enrichissement de D20) n'existe que dans une variante de build qui déclare `INTERNET` ; la variante « offline » n'a pas de réseau | Provisoire | |
| D27 | Les exports d'essai (CSV, journaux, logcat) contiennent des titres, des chemins et des identifiants de volume : ils sont analysés par Claude Code dans un dossier hors dépôt, jamais versionnés ; Claude (chat) ne reçoit que des extraits ou des synthèses | Provisoire | |
| D28 | Langue : le code et son historique sont en anglais (identifiants, commentaires, commits, branches, PR, tests, journaux) ; la documentation et les règles sont en français (`PRD.md`, `README.md`, `CHANGELOG.md`, `HOWTO.md`, `CLAUDE.md`, `.claude/commands/`, `docs/`, ADR et documents techniques compris) et seront traduites à la version de production ; textes visibles en fichiers ARB. Table complète : `CLAUDE.md` | Tranchée (révisée 2026-10-15) | Ajoutée au registre le 2026-10-15 (citée par `CLAUDE.md`). Révision du 2026-10-15 : ADR et documents techniques passés de l'anglais au français ; l'historique Git ne se traduit pas |
| D29 | À compléter par le propriétaire | — | Numéro cité nulle part dans le dépôt ; réservé |
| À numéroter | Découpage de MPL-017 : la réassociation d'un disque passe dans MPL-018 ; l'écouteur natif d'éjection et le test sur le Pixel restent dans MPL-035 ; MPL-017 livre les ports et la réaction du contrôleur | Tranchée 2026-10-15 | Réassociation dépendante du modèle de données de MPL-018 ; Kotlin vérifiable sur appareil seulement · MPL-017, MPL-018, MPL-035 |
| À numéroter | Stockage amovible : la lecture arrêtée par une éjection reste arrêtée et ne reprend pas au rebranchement du disque | Tranchée 2026-10-15 | Répond à `SPRINT-2-START.md` §8.3 · BR-002, MPL-017, MPL-035 |
| À numéroter | Identifiant Android de production : `net.trtl3.musicplayer`, le même que le prototype ; l'installation de l'une remplace l'autre sur l'appareil | Tranchée 2026-10-15 | Choix du propriétaire ; nom définitif toujours ouvert (D4) · MPL-017 |
| À numéroter | Découpage de MPL-018 : MPL-018 (stockage interne, base, liste minimale), MPL-037 (SSD par SAF, tags dans les fichiers, test à 10 000 pistes), MPL-038 (réassociation et retrait d'un disque) | Tranchée 2026-10-15 | Ticket trop gros pour un test sur le Pixel en une fois ; MediaStore fournit déjà les tags du stockage interne · MPL-018, MPL-037, MPL-038 |
| À numéroter | `minSdk` 30 au lieu de la valeur du gabarit Flutter (24), écart à D30 | Tranchée 2026-10-15 | `RELATIVE_PATH` de MediaStore (API 29), `StorageVolumeCallback` (API 30) ; seul appareil de test en Android 17 · ADR-005, MPL-018 |
| À numéroter | Le focus audio et le débranchement du casque (`audio_session`) font partie de MPL-036 ; l'autorisation de notification est déclarée sans être demandée | Tranchée 2026-10-21 | `media_kit` ne gère ni focus ni débranchement ; la notification d'une session média s'affiche sans l'autorisation (MPL-012) · BR-005, FR-005, MPL-036 |
| À numéroter | Un seul moteur Flutter par processus dès MPL-018 (`MainActivity` fournit un moteur qui survit à l'activité), sans attendre `audio_service` ; MPL-036 suit immédiatement MPL-018 | Tranchée 2026-10-21 | Fermer l'activité (geste de retour) détruisait l'isolat Dart pendant que mpv tournait : plantages de mpv (rappel de réveil libéré) et deux lecteurs simultanés, constatés sur le Pixel · MPL-018, MPL-036 |
| À numéroter | Stockage interne : l'utilisateur choisit les dossiers à indexer (D23 appliquée au disque « Local »), par une liste tirée de MediaStore, `Music/` proposé par défaut | Tranchée 2026-10-15 | Ne pas indexer sonneries, notes vocales et sons reçus par les messageries ; remplace le choix « tout le stockage interne » du même jour · FR-003, MPL-018 |
| D30 | Dépendances et versions : dernière version stable compatible avec le Flutter épinglé, tout épinglé, Dependabot hebdomadaire, avis de sécurité traités hors cycle, dérogations dans `docs/dependency-exceptions.md`. Détail : `CLAUDE.md` | Provisoire | Ajoutée au registre le 2026-10-15 (citée par `CLAUDE.md`) |
