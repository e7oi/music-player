# Backlog — MusicPlayer
Préfixe : MPL · Prochaine clé : MPL-037 · Dernière MAJ : 2026-10-15

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
| MPL-017 | Tâche technique | P0 | Fondations du projet de production (D2, D3 tranchées le 09/10/2026). Inclut un job de CI minimale (format, analyse, tests) pour que du code puisse arriver sur `main` (décision du 2026-10-15) ; MPL-026 la complète. Périmètre (recadré le 2026-10-15) : projet Flutter, tests d'architecture, port `AudioEngine` et son contrat, adaptateur `media_kit`, `PlayerController` indépendant du moteur, dont le retrait d'une piste de la file (FR-002) ; exigences issues de D23 : saut des pistes absentes avec message ; réaction à l'éjection derrière le port `VolumeEvents` (côté natif : MPL-035). Réassociation d'un disque : MPL-018 | En cours | — | — |
| MPL-018 | Récit | P0 | Indexation : tags, pochettes, SQLite, test à 10 000 pistes (lié à D23 ; note : le modèle de données dépend de D23, disque + chemin relatif ; lecture des tags mesurée à ≈ 39 ms par fichier sur SAF, ≈ 100 s pour 2 600 fichiers, à faire en arrière-plan) ; inclut la réassociation d'un nouveau disque (D23), reprise de MPL-017 le 2026-10-15, et le retrait d'un disque externe de la bibliothèque (demande du propriétaire du 2026-10-15 ; sort des playlists, favoris et statistiques du disque à trancher au cadrage) | À faire | MPL-001 | — |
| MPL-019 | Récit | P2 | Normalisation du volume (ReplayGain, préampli) | À faire | MPL-004 | — |
| MPL-020 | Épique | P0 | Épique « Qualité, CI et documentation » | En cours | — | — |
| MPL-026 | Tâche technique | P1 | CI code Flutter : format, analyse, tests, vulnérabilités, licences, **liste blanche des permissions** du manifest, vérification de l'empreinte de libmpv 🔗 | Bloqué | MPL-020 | MPL-017 |
| MPL-027 | Tâche technique | P1 | Tests fonctionnels `integration_test` + procédure appareil réel 🔗 | Bloqué | MPL-020 | MPL-017 |
| MPL-028 | Tâche technique | P1 | Fraîcheur des docs (en-têtes, modèle de PR, étape `/endSprint`) | À faire | MPL-020 | — |
| MPL-029 | Récit | P2 | Enrichissement en ligne opt-in (pochettes, paroles, métadonnées manquantes) 🔗 ⚠️ | Bloqué | MPL-004 | D20, MPL-018 |
| MPL-030 | Récit | P2 | Support Linux (desktop) — nice to have, non engagé 🔗 | Bloqué | — | D2 |
| MPL-031 | Tâche technique | P2 | Test négatif de la CI dans un dépôt privé jetable | À faire | MPL-020 | — |
| MPL-033 | Récit | P2 | Lecture de web-radio (France Info, Radio-Canada, France Inter, Radio Nova, CBC...), Phase 2 🔗 | Bloqué | MPL-004 | D26 |
| MPL-034 | Tâche technique | P2 | Auto-test : davantage de MP3 dans l'échantillon (92 % de la bibliothèque), un MP3 illisible gardé comme témoin, pistes en erreur signalées (« flaggées ») dans l'interface — (possible depuis MPL-003) | À faire | MPL-001 | — |
| MPL-035 | Tâche technique | P2 | Retrait du stockage amovible pendant la lecture : écouteur natif d'éjection puis `stop()` et fermeture du descripteur dans `PlayerController` (indépendant du moteur) ; vérifier la marge sous charge et avec d'autres descripteurs ouverts ; retirer le récepteur `ACTION_MEDIA_*` ; pas de reprise au rebranchement (décidé le 2026-10-15) ; descripteur proxy gardé comme alternative non testée. Voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3 🔗 MPL-017, D25. Depuis le 2026-10-15 : MPL-017 livre le port `VolumeEvents` et la réaction du contrôleur (BR-002) ; ce ticket livre l'adaptateur natif et le test sur le Pixel | Bloqué | MPL-001 | MPL-017 |
| MPL-036 | Tâche technique | P0 | Notification et lecture en arrière-plan dans l'application réelle (`audio_service`, écran verrouillé, contrôles système, touches média), branchées sur le `PlayerController` ; reprendre les acquis du prototype (`android/app/src/main/res/raw/keep.xml`, absent depuis MPL-017 faute d'`audio_service` ; permission de notification en natif dans `MainActivity`) | Bloqué | MPL-001 | MPL-017 |

## Détails
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
Vérification : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test` → 0 fichier modifié, aucune anomalie, 62 tests passés (scénarios Gherkin du ticket couverts par le groupe correspondant de `test/domain/playback/player_controller_test.dart`, le contrat sur le fake et les tests d'architecture) ; `flutter gen-l10n` sans écart, aucune clé manquante ; `.github/scripts/check-repo.sh` au vert ; `flutter build apk --release` → APK de 64,5 Mo sans permission `INTERNET`. Job `code-checks` sur GitHub : jamais exécuté (première exécution à la création de la PR).
Test appareil (Pixel, release) : non testé. Procédure : `HOWTO.md` §10 (contrat `media_kit` en build release), puis lancement de l'application.
Revue QA : ⚠️ (2 tours, sous-agent à contexte neuf ; lecture et stockage, revue obligatoire : une session séparée `>>> REVUE` est possible). Corrigés : marche arrière bloquée sur une piste illisible, libération d'un descripteur que mpv pouvait encore lire (`idle-active` passe à vrai avant la fermeture du fichier, vérifié dans les sources de mpv v0.39.0 ; `stop()` attend désormais la propriété `path`), compteur d'échecs après arrêt, classement des journaux, traçabilité, en-tête de commit. Restants : délai de 5 s de `stop()` (« À valider » BR-002) ; « précédent » vers une piste illisible (« À valider » BR-003) ; un échec d'ouverture invisible à la fois sur `idle-active` et dans les journaux bloquerait la lecture (risque résiduel, ADR-002) ; une position tardive de la piste précédente peut encore fausser « précédent » (mineur, sans test). Non vérifié : tout comportement sur appareil (contrat `media_kit`, fichier illisible, éjection, marge avant l'arrêt par Android), exécution du job sur GitHub.
Description de PR : titre `feat(playback): add production foundations and PlayerController (MPL-017)`. What: Flutter project at the repository root (Flutter 3.47.7, Android only, Gradle 9.3.1, AGP 9.1.1, Kotlin 2.4.0), architecture tests for the CLAUDE.md dependency rules, a minimal `code-checks` CI job and pub Dependabot updates, the `AudioEngine`, `VolumeEvents` and `TrackSourceOpener` ports with fakes and an executable engine contract, an engine-independent `PlayerController` (queue commands, track removal, skipping tracks of absent disks, ejection handling, failure handling), and a `media_kit` adapter. Why: D2 and D3, the MPL-017 scope agreed on 2026-10-15; no code may reach `main` without a code CI job. How tested: format, `flutter analyze`, `dart analyze` and 62 unit and widget tests green locally; release APK built (no `INTERNET` permission); device: not tested (the contract against `media_kit` runs with `flutter drive --release`, HOWTO §10). Known gaps: nothing runs on the Pixel yet; no provider wiring for the controller until the `VolumeEvents` and `TrackSourceOpener` adapters exist (MPL-035, MPL-018); `stop()` may return with a descriptor still open after a 5 s timeout (owner decision pending); end-file is inferred from `idle-active` because `media_kit` does not expose it; libmpv is downloaded at build time without a checksum (MPL-026); `keep.xml` waits for `audio_service` (MPL-036).
Décisions prises en route : Flutter mis à jour de 3.47.6 à 3.47.7 sur le Mac (accord du propriétaire, D30) ; identifiant Android `net.trtl3.musicplayer`, le même que le prototype (choix du propriétaire, ligne proposée dans Décisions) ; AGP 9.1.1 plutôt que 9.2.x (hors de la table de compatibilité de Flutter 3.47.7) ; `dart analyze` ajouté en CI, car `flutter analyze` n'exécute pas le plugin `riverpod_lint` ; `CLAUDE.md` (Outillage, Définition de « terminé ») mis à jour avec `dart analyze` et `flutter drive --release` (accord du propriétaire) ; contrat sur appareil lancé par `flutter drive --release`, car `flutter test integration_test` ne compile qu'en debug.
À valider (PO) : lignes « À valider » de FR-002 (retrait de la piste courante quand la lecture est arrêtée), BR-002 (délai de 5 s de `stop()`), BR-003 (remise à zéro du compteur d'échecs, « précédent » vers une piste illisible)

### MPL-029
**Détails — MPL-029.** Désactivé par défaut, opt-in par fonction (pochettes, paroles) ; cache local ; variante de build séparée (`offline` sans `INTERNET`, `enrichi` avec) ; objectif 4 du PRD reformulé. Risques : une requête révèle l'écoute à un tiers ; conditions d'usage et licences des sources (MusicBrainz, Cover Art Archive, LRCLIB, Wikimedia) **non vérifiées** ; le gabarit Flutter déclare `INTERNET` en debug/profile, donc une fonction en ligne ne se valide qu'en build release (D14). API Spotify/Deezer écartées (D9).

## Terminés
| Clé | Titre | Clos le | Note |
|---|---|---|---|
| MPL-002 | Prototype audio Android | 07/10/2026 | Clos (07/10/2026) |
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
| D30 | Dépendances et versions : dernière version stable compatible avec le Flutter épinglé, tout épinglé, Dependabot hebdomadaire, avis de sécurité traités hors cycle, dérogations dans `docs/dependency-exceptions.md`. Détail : `CLAUDE.md` | Provisoire | Ajoutée au registre le 2026-10-15 (citée par `CLAUDE.md`) |
