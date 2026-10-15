# Backlog — MusicPlayer
Préfixe : MPL · Prochaine clé : MPL-036 · Dernière MAJ : 2026-10-15

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
| MPL-017 | Tâche technique | P0 | Fondations du projet de production (D2, D3 tranchées le 09/10/2026). Inclut un job de CI minimale (format, analyse, tests) pour que du code puisse arriver sur `main` (décision du 2026-10-15) ; MPL-026 la complète. Périmètre : `PlayerController` indépendant du moteur, avec l'intégration de MPL-035 ; exigences issues de D23 : saut des pistes absentes avec message, réassociation d'un nouveau disque | À faire | — | — |
| MPL-018 | Récit | P0 | Indexation : tags, pochettes, SQLite, test à 10 000 pistes (lié à D23 ; note : le modèle de données dépend de D23, disque + chemin relatif ; lecture des tags mesurée à ≈ 39 ms par fichier sur SAF, ≈ 100 s pour 2 600 fichiers, à faire en arrière-plan) | À faire | MPL-001 | — |
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
| MPL-035 | Tâche technique | P2 | Retrait du stockage amovible pendant la lecture : écouteur natif d'éjection puis `stop()` et fermeture du descripteur dans `PlayerController` (indépendant du moteur) ; vérifier la marge sous charge et avec d'autres descripteurs ouverts ; retirer le récepteur `ACTION_MEDIA_*` ; décider de la reprise au rebranchement ; descripteur proxy gardé comme alternative non testée. Voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3 🔗 MPL-017, D25 | À faire | MPL-001 | — |

## Détails
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
| D28 | Langue : tout ce qui fait partie du code et de son historique est en anglais (identifiants, commentaires, commits, branches, PR, tests, logs) ; la prose produit et processus que lit le propriétaire reste en français (`PRD.md`, `README.md`, `CHANGELOG.md`, `HOWTO.md`, `docs/`) ; textes visibles en fichiers ARB. Table complète : `CLAUDE.md` | Tranchée | Ajoutée au registre le 2026-10-15 (citée par `CLAUDE.md`) |
| D29 | À compléter par le propriétaire | — | Numéro cité nulle part dans le dépôt ; réservé |
| D30 | Dépendances et versions : dernière version stable compatible avec le Flutter épinglé, tout épinglé, Dependabot hebdomadaire, avis de sécurité traités hors cycle, dérogations dans `docs/dependency-exceptions.md`. Détail : `CLAUDE.md` | Provisoire | Ajoutée au registre le 2026-10-15 (citée par `CLAUDE.md`) |
