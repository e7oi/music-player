# ADR-006 — `audio_service` et `audio_session` pour la lecture en arrière-plan

**Statut :** Active (validée le 2026-10-21) · **Date :** 2026-10-21 · **Ticket :** MPL-036 · **Décisions :** D2, D12, D30 · **Fiches :** FR-005, BR-005, UC-002

## Contexte

FR-005 demande un service au premier plan, une session média (notification, écran verrouillé, touches média) et BR-005 la gestion du focus audio et du débranchement du casque. `media_kit` ne fournit rien de cela. Le prototype a validé `audio_service` sur le Pixel (MPL-008, MPL-012, MPL-013). MPL-018 a déjà dû garder un seul moteur Flutter par processus (objet `Shared` de `MainActivity.kt`) pour que la fermeture de l'activité ne tue pas l'isolat Dart sous mpv.

## Décision

- **Paquets** : `audio_service` 0.18.19 (service au premier plan, session média, notification, touches média) et `audio_session` 0.2.4 (focus audio, débranchement), les dernières versions (D30), du même auteur. Session média prête pour Android Auto plus tard (D12).
- **Moteur Flutter** : `MainActivity` hérite d'`AudioServiceActivity`, dont le moteur est mis en cache par `audio_service` et survit à l'activité ; `audio_service` refuse un autre moteur. L'objet `Shared` de MPL-018 disparaît. `shouldDestroyEngineWithHost()` reste forcé à `false`. Le moteur d'`audio_service` est créé au démarrage du processus par une classe `Application` (`TuneShellApplication`), qui y enregistre une seule fois le canal MediaStore (ADR-005) : le processus peut démarrer sans activité (touche média, navigateur de médias). L'activité se rattache au canal et s'en détache comme aujourd'hui (révisé le 2026-10-21, validé par le propriétaire).
- **Adaptateur de session** : une classe `BaseAudioHandler` sous `platform/media_session/`. Elle traduit les commandes du système en appels au `PlayerController` et l'état du contrôleur (`PlayerState`) en `MediaItem` et `PlaybackState`. Elle n'a aucune logique de lecture (FR-005, exigence 5).
- **Interruptions** : port `AudioInterruptions` dans `domain/playback/ports/` (demande de focus, flux d'événements : perte durable, perte passagère, atténuation, fin d'interruption, débranchement), implémenté sous `platform/` avec `audio_session`. Les règles de BR-005 sont dans un service du domaine, testé d'abord avec un fake du port ; le contrôleur reste sans dépendance au système.
- **Câblage** : `AudioService.init` dans `main.dart`, avec un `ProviderContainer` créé avant `runApp` et passé à `UncontrolledProviderScope`, pour que l'adaptateur et l'interface partagent le même `PlayerController`.
- **Android** : service `AudioService` de type `mediaPlayback` et récepteur des touches média dans le manifeste ; permissions `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `POST_NOTIFICATIONS` ; retour de `android/app/src/main/res/raw/keep.xml` pour les icônes `audio_service_*` que la réduction des ressources supprime en release (MPL-013, `CLAUDE.md`).

## Conséquences

- Deux dépendances de plus, qui touchent la lecture et les notifications : toute version majeure exige un test sur le Pixel avant le merge (`CLAUDE.md`).
- Le service au premier plan prend un verrou de réveil pendant la lecture : la lecture écran verrouillé ne dépend plus de la chance (MPL-008).
- Le code Kotlin et le comportement sur appareil (notification, écran verrouillé, appel, casque) sont des exceptions au test d'abord : procédure dans `HOWTO.md`, résultat « testé » ou « non testé ».

## Alternatives examinées

- **Service et session média écrits en Kotlin** : aucune dépendance, mais une quantité de code natif sans test unitaire, à réécrire pour Android Auto. Écarté.
- **Garder l'objet `Shared` et ajouter `audio_service`** : `audio_service` détecte un moteur qui n'est pas le sien et ne fonctionne plus. Écarté.
- **Focus audio en Kotlin dans le canal existant** : possible, mais `audio_session` couvre déjà focus et débranchement avec des événements typés. Écarté.

## As-built

MPL-036, 2026-10-21.

- `MainActivity` hérite d'`AudioServiceActivity` et ne fait que se rattacher au canal MediaStore et s'en détacher ; `shouldDestroyEngineWithHost()` reste forcé à `false`.
- `TuneShellApplication` (`android:name` du manifeste) crée au démarrage du processus le moteur mis en cache par `audio_service` et y enregistre le canal MediaStore (ADR-005) et l'écouteur de fin du processus, avant que Dart puisse appeler. Le processus peut en effet démarrer sans activité, par le service (touche média, navigateur de médias) : le moteur exécutait alors `main()` sans canal, et la bibliothèque restait sur l'écran de chargement à l'ouverture de l'application (constaté sur le Pixel le 2026-10-21, HOWTO §12, étape 12).
- `lib/main.dart` crée le `ProviderContainer`, appelle `startSystemPlayback` (`lib/app/system_playback.dart`) puis lance l'interface avec `UncontrolledProviderScope`.
- Nom et description du canal de notification : ARB (`notificationChannelName`, `notificationChannelDescription`), dans la langue du téléphone au démarrage du processus.
- APK release : 77,8 Mo ; permissions `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS` ajoutées, pas d'`INTERNET` ; les 7 icônes `audio_service_*` présentes.
- Fin du processus avec le moteur : `audio_service` détruit son moteur quand son service s'arrête sans activité attachée ; un écouteur du cycle de vie du moteur termine alors le processus (`TuneShellApplication.kt`), pour que mpv ne survive pas à l'isolat Dart.
- Dépendances transitives ajoutées par `audio_service` : `flutter_cache_manager` (avec `http`), `sqflite` et `js`, pour les pochettes distantes, inutilisées ici. Aucune permission `INTERNET` fusionnée. À examiner par MPL-026 (licences, vulnérabilités).
- Limite connue de la fin du processus : si l'utilisateur rouvre l'application à l'instant où le service s'arrête, l'application peut se fermer au lancement (fenêtre étroite).
