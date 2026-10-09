# SPRINT-2-START — MusicPlayer

**Version :** 5 · **Mise à jour :** 09/10/2026 (démarrage du sprint : 05/10/2026) · **Préfixe backlog :** MPL
**Clôture de référence :** `docs/sprints/sprint-1/SPRINT-1-CLOSURE.md`
**Dépôts :** `e7oi/music-player` (public depuis le 08/10/2026 ; `main` orpheline : documentation seulement) · `e7oi/music-player-prototype` (privé, **jamais public** ; branches `mpl-002-audio-prototype` et `mpl-003-saf-prototype` (jamais fusionnée) : code du prototype) · méthodologies : dépôt privé `ai-tools`
**Stack :** Flutter 3.47.6 / Dart 3.13.5 · Android (Pixel 10 Pro, build release) · **Licence :** GPL-3.0-or-later, © 2026 Eloi BERTIN

---

## 1. Contexte

MusicPlayer est un lecteur audio local libre, gratuit, sans pub, sans compte, sans télémétrie, avec l'UX d'un service de streaming. **Android est la plateforme principale et prioritaire** (D10). Le prototype audio est clos (MPL-002, 006, 007 : lecture, écran verrouillé, notification, contrôles, Auto-test des formats, fluidité de la liste ; résultats dans `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md`). L'accès au SSD par SAF a été testé sur le Pixel (MPL-003, terminé avec réserves : le retrait pendant la lecture n'est traité qu'en spike, MPL-035). Le dépôt est public depuis le 08/10/2026, `main` protégée et testée, CI documentaire en place.

## 2. Deux pistes parallèles

**Piste A — appareil (Pixel).** Avant la session : recompiler et réinstaller la build release depuis le HEAD de `mpl-002-audio-prototype` (l'app installée peut être antérieure au code actuel).

| Ordre | Clé | Action | Pourquoi |
|---|---|---|---|
| A1 | MPL-002 / 006 | « Auto-test échantillon » **sans filtre actif**, deux moteurs (~13 pistes : FLAC, M4A, WMA, OPUS, OGG inclus). Pas de modification de code | L'échantillon est tiré de la liste filtrée ; le résultat à 3 pistes venait très probablement d'un filtre actif |
| A2 | MPL-007 | Fluidité du défilement (2 624 pistes), recherche, tri, exports `.txt`/`.csv`, « Rejouer les échecs » — même session que A1 | Une seule session sur appareil |
| A3 | MPL-003 | **Diagnostic SSD** (Samsung T7 Shield) : commandes `adb` en mode sans fil, puis décision A (requête MediaStore multi-volumes) ou B (sélecteur Android, SAF) | Test d'architecture : peut changer D2, D3 et MPL-018 |
| A4 | D2 | Trancher le moteur audio avec les résultats A1 et A3 | Débloque MPL-017 |

**État au 09/10/2026 :** A1 à A3 réalisées (voir §3 et `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md`) ; A4 : D2 tranchée le 09/10/2026 (`media_kit` moteur unique). Piste B : B1 à B3 réalisées.

**Piste B — dépôt et qualité.**

| Ordre | Clé | Action | Bloqué par |
|---|---|---|---|
| B1 | MPL-024 | CI documentaire (markdownlint, liens, gitleaks, contrôles de cohérence), Dependabot des actions, `.gitignore` | — |
| B2 | MPL-025 | Audit avant publication (historique, e-mails des commits, relecture), puis dépôt `music-player` **public** | MPL-024 |
| B3 | MPL-023 (fin) | Protection de `main` appliquée, vérifiée par un test réel (push direct refusé) | Dépôt public (voir §5) |

**Ensuite :** MPL-016 (maquettes, peut démarrer en parallèle), MPL-017 (fondations ; D2 et D3 tranchées le 09/10/2026), MPL-018, puis MPL-026 et MPL-027, MPL-028 à tout moment.

## 3. Snapshot du backlog

| Clé | Type | Prio | Titre | Parent | Statut |
|---|---|---|---|---|---|
| MPL-001 | 🗂️ | 🔺 | Épique « Lecture locale » | — | En cours |
| MPL-002 | 🔧 | 🔺 | Prototype audio Android | 001 | ✅ Clos (07/10/2026) |
| MPL-003 | 📖 | 🔺 | Sources de bibliothèque : stockage amovible (SSD USB-C), test Pixel (titre proposé) 🔗 ⚠️ | 001 | ✅ Terminé avec réserves (08/10/2026) : SSD lu par SAF avec les deux moteurs ; tags non lus pendant le parcours (≈ 39 ms par fichier mesurés) ; retrait pendant la lecture traité en spike seulement (MPL-035) ; voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4 |
| MPL-004 | 🗂️ | 🔸 | Épique « Expérience de type streaming » | — | ⬜ À faire |
| MPL-005 | 🗂️ | ▫️ | Épique « Voiture / Android Auto » 🔗 dépend de 001 ⚠️ D6 | — | ⬜ À faire |
| MPL-006 | 🔧 | 🔺 | Auto-test sur échantillon, isolé, exporté | 001 | ✅ Clos (07/10/2026) : 13 pistes par moteur ; élargissement de l'échantillon MP3 : MPL-034 |
| MPL-007 | 🔧 | 🔺 | Console de test : recherche, tri, filtre par format | 002 | ✅ Clos (07/10/2026) |
| MPL-008 | 🐛 | 🔺 | Lecture coupée après ~1 min écran verrouillé | 002 | ✅ Résolu (cause initiale non déterminée) |
| MPL-009 | 🐛 | ▫️ | WMA non lu par `just_audio` | — | ⛔ Abandonné — WMA = 1,2 % de la bibliothèque, seul `media_kit` le lit, non prioritaire (D16, 05/10/2026) |
| MPL-010 | 🐛 | ▫️ | Avertissements de décodage `media_kit` sans effet audible constaté : FLAC avec étiquettes ID3 ; MP3 avec données non-MPEG après la dernière trame (MP3 A, MP3 B ; voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.5) | — | 🐞 Bug actif (origine des octets et fréquence dans la bibliothèque non établies ; pas de changement de code) |
| MPL-011 | 🔧 | ▫️ | Écart de volume entre moteurs | 002 | ✅ Clos (accepté, D13) |
| MPL-012 | 🔧 | 🔺 | Permission de notification | 002 | ✅ Résolu |
| MPL-013 | 🐛 | 🔺 | Icônes `audio_service` supprimées en release | 002 | ✅ Résolu |
| MPL-014 | 🔧 | ▫️ | Prototype audio Windows et macOS | — | ⏸️ En pause |
| MPL-015 | 🔧 | ▫️ | Revoir dialogue et bandeau de permission ⚠️ un seul appareil testé | — | ⬜ À faire |
| MPL-016 | 🔧 | 🔺 | Maquettes UI/UX dans Claude Design (note : prévoir l'état « sources indisponibles » sans écraser la liste de pistes, défaut observé dans le prototype MPL-003) | — | ⬜ À faire |
| MPL-017 | 🔧 | 🔺 | Fondations du projet de production (D2, D3 tranchées le 09/10/2026). Périmètre : `PlayerController` indépendant du moteur, avec l'intégration de MPL-035 ; exigences issues de D23 : saut des pistes absentes avec message, réassociation d'un nouveau disque | — | ⬜ À faire |
| MPL-018 | 📖 | 🔺 | Indexation : tags, pochettes, SQLite, test à 10 000 pistes (lié à D23 ; note : le modèle de données dépend de D23, disque + chemin relatif ; lecture des tags mesurée à ≈ 39 ms par fichier sur SAF, ≈ 100 s pour 2 600 fichiers, à faire en arrière-plan) | 001 | ⬜ À faire |
| MPL-019 | 📖 | ▫️ | Normalisation du volume (ReplayGain, préampli) | 004 | ⬜ À faire |
| MPL-020 | 🗂️ | 🔺 | Épique « Qualité, CI et documentation » | — | En cours |
| MPL-021 | 🔧 | 🔺 | Licence GPL-3.0-or-later (© 2026 Eloi BERTIN) | 020 | ✅ Résolu (06/10/2026) |
| MPL-022 | 🔧 | 🔺 | Docs : PRD v0.2, README, CHANGELOG, HOWTO, snapshots du Sprint 1 | 020 | ✅ Résolu (06/10/2026) |
| MPL-023 | 🔧 | 🔺 | `main` orpheline, dépôts séparés, protection de branche | 020 | ✅ Résolu (08/10/2026) : `main` orpheline, deux dépôts, ruleset `protect-main` appliqué ; push direct refusé (test réel) |
| MPL-024 | 🔧 | 🔺 | CI documentaire (markdownlint, liens, gitleaks, cohérence) | 020 | ✅ Résolu (07/10/2026) |
| MPL-025 | 🔧 | 🔺 | Audit avant publication (historique, e-mails), puis dépôt public 🔗 | 020 | ✅ Résolu (08/10/2026) : audit fait, dépôt public depuis le 08/10/2026 |
| MPL-026 | 🔧 | 🔸 | CI code Flutter : format, analyse, tests, vulnérabilités, licences, **liste blanche des permissions** du manifest, vérification de l'empreinte de libmpv 🔗 | 020 | 🔒 Bloqué par MPL-017 |
| MPL-027 | 🔧 | 🔸 | Tests fonctionnels `integration_test` + procédure appareil réel 🔗 | 020 | 🔒 Bloqué par MPL-017 |
| MPL-028 | 🔧 | 🔸 | Fraîcheur des docs (en-têtes, modèle de PR, étape `/endSprint`) | 020 | ⬜ À faire |
| MPL-029 | 📖 | ▫️ | Enrichissement en ligne opt-in (pochettes, paroles, métadonnées manquantes) 🔗 ⚠️ | 004 | 🔒 Bloqué par D20, MPL-018 |
| MPL-030 | 📖 | ▫️ | Support Linux (desktop) — nice to have, non engagé 🔗 | — | 🔒 Bloqué par D2 |
| MPL-031 | 🔧 | ▫️ | Test négatif de la CI dans un dépôt privé jetable | 020 | ⬜ À faire |
| MPL-033 | 📖 | ▫️ | Lecture de web-radio (France Info, Radio-Canada, France Inter, Radio Nova, CBC...), Phase 2 🔗 | 004 | 🔒 Bloqué par D26 |
| MPL-034 | 🔧 | ▫️ | Auto-test : davantage de MP3 dans l'échantillon (92 % de la bibliothèque), un MP3 illisible gardé comme témoin, pistes en erreur signalées (« flaggées ») dans l'interface | 001 | ⬜ À faire (possible depuis MPL-003) |
| MPL-035 | 🔧 | ▫️ | Retrait du stockage amovible pendant la lecture : écouteur natif d'éjection puis `stop()` et fermeture du descripteur dans `PlayerController` (indépendant du moteur) ; vérifier la marge sous charge et avec d'autres descripteurs ouverts ; retirer le récepteur `ACTION_MEDIA_*` ; décider de la reprise au rebranchement ; descripteur proxy gardé comme alternative non testée. Voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3 🔗 MPL-017, D25 | 001 | ⬜ À faire |

**Note sur MPL-023 et MPL-025.** La protection de `main` ne s'applique qu'en dépôt public (ou forfait payant) ; or la publication exige l'audit (MPL-025). MPL-025 n'est donc pas bloqué par la fin de MPL-023 : MPL-023 se ferme après la publication, avec un test réel.

**Détails — MPL-029.** Désactivé par défaut, opt-in par fonction (pochettes, paroles) ; cache local ; variante de build séparée (`offline` sans `INTERNET`, `enrichi` avec) ; objectif 4 du PRD reformulé. Risques : une requête révèle l'écoute à un tiers ; conditions d'usage et licences des sources (MusicBrainz, Cover Art Archive, LRCLIB, Wikimedia) **non vérifiées** ; le gabarit Flutter déclare `INTERNET` en debug/profile, donc une fonction en ligne ne se valide qu'en build release (D14). API Spotify/Deezer écartées (D9).

## 4. Registre des décisions (`Dn`)

| Code | Décision | Statut |
|---|---|---|
| D1 | Projet **open source** ; licence GPL-3.0-or-later ; titulaire Eloi BERTIN (2026) | Tranchée 05/10/2026 |
| D2 | Moteur audio : `media_kit` (libmpv/FFmpeg) est le **moteur unique** de l'application réelle, derrière une **interface indépendante du moteur** (`PlayerController`, MPL-017) qui permet de changer de moteur plus tard ; `just_audio` n'est pas repris dans l'application réelle, le prototype reste la référence. Motifs : un seul moteur à tester et à maintenir, WMA lisible (D16 : toujours non prioritaire), ReplayGain possible via mpv (MPL-019, D13), même moteur sur Windows et macOS. Conséquences acceptées : les WARN de MPL-010 (sans effet audible constaté) ; poids de l'APK non mesuré (risque à suivre). Tests SSD du 08/10/2026 : les deux moteurs lisent le SSD et réagissent de la même façon au retrait ; remplace la recommandation de `docs/sprints/sprint-1/RESULTS.md` §6 (snapshot Sprint 1) | Tranchée 09/10/2026 |
| D3 | Gestion d'état et base de données : Base locale : SQLite via **Drift** (requêtes typées, migrations de schéma versionnées, flux réactifs, exécution en isolate, recherche plein texte FTS5 possible). Gestion d'état : **Riverpod**. Motif de la base : le modèle D23 est relationnel (disques, pistes par disque + chemin relatif, playlists mêlant plusieurs disques) ; Isar (état de maintenance en 2026 non vérifié) et ObjectBox (plus de natif, relations moins naturelles) ne sont pas retenus. Reporté à l'implémentation : la version exacte de Riverpod et l'usage ou non de sa génération de code (en plus de celle de Drift) | Tranchée 09/10/2026 |
| D4 | Nom définitif de l'application | Ouverte |
| D5 | Canaux de distribution (la release est signée avec la clé debug : TODO avant toute distribution) | Ouverte |
| D6 | Android Auto et Google Play | Ouverte |
| D7 | Identifiant d'organisation `net.trtl3` | Tranchée |
| D8 | Flutter/Dart, codebase unique | Tranchée |
| D9 | Lecteur local ; aucun catalogue sous licence ; pas de copie de l'identité Spotify/Deezer | Tranchée |
| D10 | **Android plateforme principale et prioritaire** ; Windows et macOS en pause (MPL-014) ; iOS hors périmètre ; Linux nice to have (MPL-030) | Tranchée (révisée 06/10/2026) |
| D11 | Android : MediaStore comme voie principale, pas de sélecteur de dossier | Remplacée par D25 |
| D12 | Android Auto : Épique P2 (MPL-005), architecture audio prévue dès le départ | Tranchée |
| D13 | `media_kit` avec sa sortie par défaut (OpenSL ES), sans `ao=audiotrack` ; écart léger accepté ; normalisation par ReplayGain (MPL-019) | Tranchée |
| D14 | Valider tout item en **build release** avant fermeture (HOWTO §6) | Tranchée |
| D15 | Aucune requête réseau sortante (pas de `INTERNET` en release). Pourra être précisée par D20 | Tranchée |
| D16 | WMA non prioritaire ; MPL-009 abandonné | Tranchée 05/10/2026 |
| D17 | `main` orpheline et protégée ; merge par PR avec contrôles au vert ; push libre des branches de travail. Protection appliquée le 08/10/2026 (ruleset `protect-main`), push direct refusé en test réel | Tranchée 05/10/2026 |
| D18 | Méthodologies hors dépôt | Remplacée par D21 |
| D19 | Dépôt public après licence + `main` + CI documentaire + audit (MPL-025) | Tranchée 05/10/2026 |
| D20 | Enrichissement en ligne optionnel : opt-in par fonction, cache local, variante de build séparée. Précisera D15. À trancher avant l'Épique MPL-004 | **Ouverte** |
| D21 | Organisation : documents à la racine ; méthodologies dans le dépôt privé `ai-tools` ; snapshots dans `docs/sprints/` | Tranchée 05/10/2026 |
| D22 | Les fichiers du dépôt sont modifiés par Claude Code ; ce Project rédige les prompts, challenge et relit | Tranchée 06/10/2026 |
| D23 | Modèle de « source de bibliothèque » : une source est un **disque** : le stockage interne (« Local ») ou un volume amovible, identifié par l'UUID de son système de fichiers. Un disque contient les dossiers choisis par l'utilisateur ; une piste est identifiée par (disque, chemin relatif). Les pistes d'un disque absent restent dans la bibliothèque, grisées ; pendant la lecture, elles sont sautées avec un message (du type « 12 pistes ignorées : SSD absent »). Une playlist peut mêler les pistes de plusieurs disques. Si l'utilisateur ajoute un disque dont les chemins relatifs correspondent à ceux d'un disque absent, l'application propose de le réassocier (playlists, favoris et statistiques conservés). Dans l'interface, la source est le disque (« SSD : 26 pistes, indisponible »), et non chaque dossier comme dans le prototype | Tranchée 09/10/2026 (ouverte depuis le 06/10/2026) |
| D24 | Le prototype reste dans un dépôt privé séparé (`music-player-prototype`) ; `music-player` ne contient que `main` et ses branches de travail | Tranchée 07/10/2026 |
| D25 | Android : MediaStore pour le stockage interne, sélecteur Android (SAF) pour le stockage amovible USB ; remplace D11. Accès SSD par SAF vérifié sur le Pixel 10 Pro (MPL-003) ; risque du retrait pendant la lecture traité par le spike (MPL-035) | Tranchée 09/10/2026 |
| D26 | Toute fonction en ligne (dont la web-radio et l'enrichissement de D20) n'existe que dans une variante de build qui déclare `INTERNET` ; la variante « offline » n'a pas de réseau | **Provisoire** |
| D27 | Les exports d'essai (CSV, journaux, logcat) contiennent des titres, des chemins et des identifiants de volume : ils sont analysés par Claude Code dans un dossier hors dépôt, jamais versionnés ; Claude (chat) ne reçoit que des extraits ou des synthèses | **Provisoire** |

## 5. Définition de « terminé » pour le prototype Android

| # | Critère | État |
|---|---|---|
| 1 | Lecture, pause, seek d'un fichier local | ✅ |
| 2 | Lecture écran verrouillé > 15 min avec enchaînement | ✅ |
| 3 | Notification, canal et contrôles | ✅ |
| 4 | Seek depuis la notification | ✅ |
| 5 | Persistance au redémarrage, touches des écouteurs | ✅ persistance de la liste après redémarrage (07/10/2026) ; touches des écouteurs : non précisé |
| 6 | Auto-test échantillon non filtré, deux moteurs (~13 pistes) | ✅ A1 (07/10/2026, 13 pistes par moteur) |
| 7 | Fluidité (2 624 pistes), recherche, tri, exports | ✅ A2 (07/10/2026) |
| 8 | Lecture d'une piste du SSD avec les deux moteurs ; comportement au débranchement | ✅ avec réserves, A3 (08/10/2026) : lecture avec les deux moteurs ; retrait traité en spike seulement (MPL-035) |
| 9 | Décision D2 | ✅ A4 (09/10/2026) |
| 10 | « Tout » sur 2 624 pistes (≈ 4 h par moteur) | Optionnel |

## 6. Règles critiques à ne pas casser

1. Jamais de fermeture sans test réel en build release + confirmation explicite. Écrire « non testé » plutôt que « OK ».
2. Conserver `android/app/src/main/res/raw/keep.xml` (commit `38cbf32`).
3. Adaptateur `media_kit` : `playing` = intention de lecture (commit `d6f041c`).
4. Permission de notification en natif dans `MainActivity` (commit `cf79f4f`) ; pas de `permission_handler`.
5. Pendant un Auto-test, ne pas toucher à l'app.
6. Tests d'arrière-plan : téléphone débranché.
7. Un correctif = un commit annulable. Push libre des branches de travail ; **`main` uniquement par pull request** (D17), jamais de push direct (protection appliquée depuis le 08/10/2026).
8. Aucune télémétrie, aucun réseau sortant (D15, sous réserve de D20).
9. Pas de gain de volume arbitraire (ReplayGain, MPL-019).
10. `media_kit` sur Android : chemin de fichier, pas d'URI `content://`.
11. **Deux dépôts, deux clones distincts.** Ne jamais ajouter l'un comme remote de l'autre. `music-player-prototype` ne devient jamais public.
12. `music-player` est public depuis le 08/10/2026 (fin de MPL-025) : aucun contenu personnel dans les fichiers versionnés (D27).
13. Identité Git `Eloi BERTIN <228106+e7oi@users.noreply.github.com>`, configurée **dans les clones MusicPlayer seulement** (pas en global).
14. Les fichiers du dépôt sont modifiés par Claude Code (D22) ; les prompts interdisent tout push sur `main`.
15. La branche `mpl-002-audio-prototype` reste intacte jusqu'à la fermeture de MPL-002, puis reçoit l'étiquette `prototype-sprint1`.

## 7. Risques ouverts

- **Stockage amovible** : le SSD n'est pas indexé par MediaStore ; accès par SAF vérifié sur le Pixel (MPL-003, terminé avec réserves). **Retrait pendant la lecture** : sans traitement, Android tue l'app (`vold`, `SIGINT`) ; arrêt préalable du moteur essayé en spike seulement (5 essais, un appareil, un SSD), marge sous charge non vérifiée (MPL-035).
- **Publication** : l'historique complet est public depuis le 08/10/2026 (audit MPL-025 fait) ; toute fuite dans un fichier versionné est durable.
- Release signée avec la clé debug ; build qui télécharge libmpv depuis github.com sans empreinte vérifiée ; licence libmpv sur Windows et macOS non vérifiée sur un build de l'app ; un seul appareil testé.
- Cause initiale de MPL-008 inconnue ; volume jamais mesuré en dB ; OpenSL ES à surveiller ; indexation, SQLite et gapless non essayés ; Android Auto et Google Play (D6).
- Minutes de GitHub Actions limitées en dépôt privé (la CI documentaire est légère).

## 8. Questions en attente

1. ~~Persistance après redémarrage~~ : persistance de la liste confirmée sur le Pixel (07/10/2026).
2. ~~Diagnostic SSD~~ : fait (MPL-003, voir `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md`).
3. **Reprise de la lecture au rebranchement** du stockage amovible : décision produit à prendre (MPL-035).

## 9. Sources

- Dépôts liés au Project : `e7oi/music-player` (documents, snapshots), `e7oi/music-player-prototype` (code du prototype).
- Méthodologies : `ai-tools` (privé) et copies du Project (`backlog-methodology.md` v2.2, `sprint-methodology.md` v1.1, `init-methodology.md`, `synthese-conversation-*.md`).

---

*SPRINT-2-START.md v5 — 09/10/2026 · à placer dans `docs/sprints/sprint-2/` du dépôt `music-player` (via MPL-024)*
