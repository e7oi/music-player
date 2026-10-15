# ADR-002 — Ports de lecture : AudioEngine, VolumeEvents, TrackSourceOpener

**Statut :** Active (validée le 2026-10-15) · **Date :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D2, D23, D25 · **Fiches :** FR-001, BR-001, BR-002, BR-003

## Contexte

D2 garde `media_kit` comme moteur unique, derrière un `PlayerController` indépendant du moteur. Le sélecteur de moteur du prototype n'est pas repris. Le contrôleur doit aussi réagir à l'éjection d'un volume amovible (D25) et sauter les pistes des disques absents (D23), sans importer de canal ni de base de données.

## Décision

Trois ports sous `domain/`, chacun sur une frontière réelle, chacun avec un fake dans `test/` :

| Port | Emplacement | Adaptateur de production | Livré par |
|---|---|---|---|
| `AudioEngine` | `domain/playback/ports/` | `data/audio/` sur `media_kit` | MPL-017 |
| `VolumeEvents` | `domain/storage/ports/` | `platform/` sur un EventChannel et `StorageVolumeCallback` | port et fake : MPL-017 ; adaptateur : MPL-035 |
| `TrackSourceOpener` | `domain/storage/ports/` | résout (disque, chemin relatif) en chemin de fichier (stockage interne) ou en `fd://N` (SAF) | port et fake : MPL-017 ; adaptateurs : MPL-018 / MPL-035 |

Contrat d'`AudioEngine`, écrit en dartdoc sur l'interface et sous forme de suite exécutable `test/contract/audio_engine_contract.dart` :

- `open` charge sans démarrer la lecture et peut rendre la main avant que la durée soit connue ; la durée arrive sur `durationStream`. L'état `loading` n'est pas garanti.
- `play()` rend la main dès que la lecture est demandée ; `playing` est l'intention et reste vrai d'une piste à l'autre.
- `completed` est émis une fois par piste.
- `stop()` ne rend la main qu'une fois que le moteur a cessé de lire et libéré toutes ses ressources, descripteurs de fichiers compris ; il est idempotent.
- Les problèmes sont une `sealed class EngineIssue` avec `EngineFailure` et `EngineWarning`. L'adaptateur classe : un `end-file` avec une raison d'erreur est toujours un échec ; les messages non classés sont des avertissements de type `unclassified`.

La suite tourne contre `FakeAudioEngine` en CI et contre l'adaptateur `media_kit` dans `integration_test/` sur le Pixel, avec un court fichier audio synthétique généré pour le test (aucun contenu personnel, D27).

`VolumeEvents` expose l'ensemble des disques disponibles et un flux d'événements `mounted` / `ejecting` / `removed` identifiés par l'UUID du système de fichiers. Dans MPL-017, la disponibilité des disques est tenue en mémoire par le contrôleur ; la persistance arrive avec MPL-018.

## Conséquences

- `PlayerController` est du Dart pur, entièrement testable avec des fakes (BR-001 à BR-003).
- Dans MPL-017, l'application ne lit de l'audio que par le test de contrat de l'adaptateur sur appareil ; les vraies sources de pistes arrivent avec MPL-018 et MPL-035.
- Les tests de classement à partir de messages réels enregistrés restent dans MPL-010.

## Alternatives examinées

- Garder un sélecteur de moteur (`engineFactories`, `switchEngine`) : propre au prototype, écarté par D2.
- Contrôleur à l'écoute directe d'un canal : enfreint la règle 2 des dépendances et n'est pas testable hors appareil. Écarté.

## As-built

MPL-017, 2026-10-15.

- Fichiers : `lib/domain/playback/ports/audio_engine.dart`, `lib/domain/storage/ports/volume_events.dart`, `lib/domain/storage/ports/track_source_opener.dart` ; modèle dans `lib/domain/*/model/` ; contrôleur dans `lib/domain/playback/services/player_controller.dart` ; adaptateur dans `lib/data/audio/media_kit_audio_engine.dart` ; fakes dans `test/fakes/`.
- `DiskId` est un *extension type* sur `String` (égalité de chaîne, utilisable en constante).
- `media_kit` n'expose pas l'événement `end-file` de mpv. L'adaptateur observe la propriété `idle-active` : avec `keep-open=yes`, mpv ne passe à l'état inactif que lorsqu'un fichier est déchargé ou n'a pas pu être lu. Un retour à l'état inactif après le début du chargement, sans arrêt demandé, vaut donc `end-file` avec erreur, et devient un échec (`openFailed` avant que la piste soit prête, `playbackFailed` ensuite). Tant que la durée du fichier n'est pas connue, les journaux d'erreur des préfixes `file`, `stream` et `cplayer` (« Failed to… ») signalent aussi un échec d'ouverture, au cas où mpv passerait d'occupé à inactif trop vite pour que la propriété change de façon visible. Les autres messages `warn` et `error` sont des avertissements `unclassified` (MPL-010). Risque résiduel : un fichier illisible dont l'échec n'est ni visible sur `idle-active` ni annoncé par ces journaux laisserait la lecture bloquée ; le test de contrat sur appareil le vérifie avec un fichier illisible.
- `idle-active` passe à vrai dès qu'un arrêt est demandé, avant que mpv ferme le fichier (`stop_play == PT_STOP`, `player/command.c` de mpv v0.39.0). `stop()` attend donc que la propriété `path` soit vide : mpv ne l'efface qu'après la fermeture du démultiplexeur (`play_current_file`, `player/loadfile.c`). L'attente dure 5 s au plus (sondage toutes les 10 ms). Passé ce délai, `stop()` rend la main (dépassement journalisé), mais le descripteur n'est libéré qu'après une fermeture confirmée lors d'un arrêt suivant, ou à `dispose()` : jamais pendant que mpv peut le lire. Ce cas contredit le contrat de `stop()` : voir « À valider » de BR-002.
- Limite connue : un événement de position de la piste précédente arrivé après le chargement de la suivante peut encore fausser « précédent » (non couvert par un test).
- `DescriptorMediaSource` (`fd://N`) est géré par l'adaptateur, mais aucun code ne l'utilise encore. Le contrat le vérifie sur le fake, pas sur appareil (MPL-035).
- Les journaux de mpv vont dans le journal local de l'appareil (`dart:developer`), jamais dans un fichier versionné (D27).
- Exécution du contrat sur appareil : `HOWTO.md` §10, en mode profile via `flutter drive` (`test_driver/integration_test.dart`), car `flutter drive` refuse la release. Passé sur le Pixel 10 Pro le 2026-10-15 (`All tests passed.`, 6 tests exécutés, 2 ignorés : descripteurs). Le cas d'un fichier illisible est donc couvert sur appareil pour ce fichier de test ; le chemin `fd://` ne l'est pas (MPL-035).
