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

Néant (non implémenté).
