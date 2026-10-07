# SPRINT-2-START — MusicPlayer

**Version :** 3 · **Mise à jour :** 07/10/2026 (démarrage du sprint : 05/10/2026) · **Préfixe backlog :** MPL
**Clôture de référence :** `docs/sprints/sprint-1/SPRINT-1-CLOSURE.md`
**Dépôts :** `e7oi/music-player` (privé ; `main` orpheline : documentation seulement) · `e7oi/music-player-prototype` (privé, **jamais public** ; branche `mpl-002-audio-prototype` : code du prototype) · méthodologies : dépôt privé `ai-tools`
**Stack :** Flutter 3.47.6 / Dart 3.13.5 · Android (Pixel 10 Pro, build release) · **Licence :** GPL-3.0-or-later, © 2026 Eloi BERTIN

---

## 1. Contexte

MusicPlayer est un lecteur audio local libre, gratuit, sans pub, sans compte, sans télémétrie, avec l'UX d'un service de streaming. **Android est la plateforme principale et prioritaire** (D10). Le prototype audio est validé en grande partie sur le Pixel (lecture, écran verrouillé, notification, contrôles, seek depuis la notification). Restent l'Auto-test des formats, la fluidité de la liste et le test du stockage amovible. En parallèle, le dépôt propre est en place (licence, `main`, documents) ; la CI documentaire est la prochaine étape.

## 2. Deux pistes parallèles

**Piste A — appareil (Pixel).** Avant la session : recompiler et réinstaller la build release depuis le HEAD de `mpl-002-audio-prototype` (l'app installée peut être antérieure au code actuel).

| Ordre | Clé | Action | Pourquoi |
|---|---|---|---|
| A1 | MPL-002 / 006 | « Auto-test échantillon » **sans filtre actif**, deux moteurs (~13 pistes : FLAC, M4A, WMA, OPUS, OGG inclus). Pas de modification de code | L'échantillon est tiré de la liste filtrée ; le résultat à 3 pistes venait très probablement d'un filtre actif |
| A2 | MPL-007 | Fluidité du défilement (2 624 pistes), recherche, tri, exports `.txt`/`.csv`, « Rejouer les échecs » — même session que A1 | Une seule session sur appareil |
| A3 | MPL-003 | **Diagnostic SSD** (Samsung T7 Shield) : commandes `adb` en mode sans fil, puis décision A (requête MediaStore multi-volumes) ou B (sélecteur Android, SAF) | Test d'architecture : peut changer D2, D3 et MPL-018 |
| A4 | D2 | Trancher le moteur audio avec les résultats A1 et A3 | Débloque MPL-017 |

**Piste B — dépôt et qualité.**

| Ordre | Clé | Action | Bloqué par |
|---|---|---|---|
| B1 | MPL-024 | CI documentaire (markdownlint, liens, gitleaks, contrôles de cohérence), Dependabot des actions, `.gitignore` | — |
| B2 | MPL-025 | Audit avant publication (historique, e-mails des commits, relecture), puis dépôt `music-player` **public** | MPL-024 |
| B3 | MPL-023 (fin) | Protection de `main` appliquée, vérifiée par un test réel (push direct refusé) | Dépôt public (voir §5) |

**Ensuite :** MPL-016 (maquettes, peut démarrer en parallèle), MPL-017 (fondations, bloqué par D2 et D3), MPL-018, puis MPL-026 et MPL-027, MPL-028 à tout moment.

## 3. Snapshot du backlog

| Clé | Type | Prio | Titre | Parent | Statut |
|---|---|---|---|---|---|
| MPL-001 | 🗂️ | 🔺 | Épique « Lecture locale » | — | En cours |
| MPL-002 | 🔧 | 🔺 | Prototype audio Android | 001 | En cours : reste l'Auto-test des formats (seek depuis la notification : validé) |
| MPL-003 | 📖 | 🔺 | Sources de bibliothèque : stockage amovible (SSD USB-C), test Pixel (titre proposé) 🔗 ⚠️ | 001 | ⬜ À faire (diagnostic `adb` en attente) |
| MPL-004 | 🗂️ | 🔸 | Épique « Expérience de type streaming » | — | ⬜ À faire |
| MPL-005 | 🗂️ | ▫️ | Épique « Voiture / Android Auto » 🔗 dépend de 001 ⚠️ D6 | — | ⬜ À faire |
| MPL-006 | 🔧 | 🔺 | Auto-test sur échantillon, isolé, exporté | 001 | 📤 Prompt livré ; amendement pondéré (≥10 MP3 variés) optionnel, proposé |
| MPL-007 | 🔧 | 🔺 | Console de test : recherche, tri, filtre par format | 002 | 📤 Prompt livré, reste à vérifier (fluidité, exports) |
| MPL-008 | 🐛 | 🔺 | Lecture coupée après ~1 min écran verrouillé | 002 | ✅ Résolu (cause initiale non déterminée) |
| MPL-009 | 🐛 | ▫️ | WMA non lu par `just_audio` | — | ⛔ Abandonné — WMA = 1,2 % de la bibliothèque, seul `media_kit` le lit, non prioritaire (D16, 05/10/2026) |
| MPL-010 | 🐛 | ▫️ | FLAC avec étiquettes ID3 : avertissement `media_kit` sans effet audible | — | 🐞 Bug actif |
| MPL-011 | 🔧 | ▫️ | Écart de volume entre moteurs | 002 | ✅ Clos (accepté, D13) |
| MPL-012 | 🔧 | 🔺 | Permission de notification | 002 | ✅ Résolu |
| MPL-013 | 🐛 | 🔺 | Icônes `audio_service` supprimées en release | 002 | ✅ Résolu |
| MPL-014 | 🔧 | ▫️ | Prototype audio Windows et macOS | — | ⏸️ En pause |
| MPL-015 | 🔧 | ▫️ | Revoir dialogue et bandeau de permission ⚠️ un seul appareil testé | — | ⬜ À faire |
| MPL-016 | 🔧 | 🔺 | Maquettes UI/UX dans Claude Design | — | ⬜ À faire |
| MPL-017 | 🔧 | 🔺 | Fondations du projet de production 🔗 bloqué par D2, D3 (et MPL-003, proposé) | — | 🔒 Bloqué |
| MPL-018 | 📖 | 🔺 | Indexation : tags, pochettes, SQLite, test à 10 000 pistes (lié à D23) | 001 | ⬜ À faire |
| MPL-019 | 📖 | ▫️ | Normalisation du volume (ReplayGain, préampli) | 004 | ⬜ À faire |
| MPL-020 | 🗂️ | 🔺 | Épique « Qualité, CI et documentation » | — | En cours |
| MPL-021 | 🔧 | 🔺 | Licence GPL-3.0-or-later (© 2026 Eloi BERTIN) | 020 | ✅ Résolu (06/10/2026) |
| MPL-022 | 🔧 | 🔺 | Docs : PRD v0.2, README, CHANGELOG, HOWTO, snapshots du Sprint 1 | 020 | ✅ Résolu (06/10/2026) |
| MPL-023 | 🔧 | 🔺 | `main` orpheline, dépôts séparés, protection de branche | 020 | En cours : `main` orpheline, branche par défaut, deux dépôts ✅ ; protection **non appliquée** (dépôt privé, forfait gratuit) |
| MPL-024 | 🔧 | 🔺 | CI documentaire (markdownlint, liens, gitleaks, cohérence) | 020 | 📤 Prompt livré (07/10/2026) |
| MPL-025 | 🔧 | 🔺 | Audit avant publication (historique, e-mails), puis dépôt public 🔗 | 020 | 🔒 Bloqué par MPL-024 |
| MPL-026 | 🔧 | 🔸 | CI code Flutter : format, analyse, tests, vulnérabilités, licences, **liste blanche des permissions** du manifest, vérification de l'empreinte de libmpv 🔗 | 020 | 🔒 Bloqué par MPL-017 |
| MPL-027 | 🔧 | 🔸 | Tests fonctionnels `integration_test` + procédure appareil réel 🔗 | 020 | 🔒 Bloqué par MPL-017 |
| MPL-028 | 🔧 | 🔸 | Fraîcheur des docs (en-têtes, modèle de PR, étape `/endSprint`) | 020 | ⬜ À faire |
| MPL-029 | 📖 | ▫️ | Enrichissement en ligne opt-in (pochettes, paroles, métadonnées manquantes) 🔗 ⚠️ | 004 | 🔒 Bloqué par D20, MPL-018 |
| MPL-030 | 📖 | ▫️ | Support Linux (desktop) — nice to have, non engagé 🔗 | — | 🔒 Bloqué par D2 |

**Note sur MPL-023 et MPL-025.** La protection de `main` ne s'applique qu'en dépôt public (ou forfait payant) ; or la publication exige l'audit (MPL-025). MPL-025 n'est donc pas bloqué par la fin de MPL-023 : MPL-023 se ferme après la publication, avec un test réel.

**Détails — MPL-029.** Désactivé par défaut, opt-in par fonction (pochettes, paroles) ; cache local ; variante de build séparée (`offline` sans `INTERNET`, `enrichi` avec) ; objectif 4 du PRD reformulé. Risques : une requête révèle l'écoute à un tiers ; conditions d'usage et licences des sources (MusicBrainz, Cover Art Archive, LRCLIB, Wikimedia) **non vérifiées** ; le gabarit Flutter déclare `INTERNET` en debug/profile, donc une fonction en ligne ne se valide qu'en build release (D14). API Spotify/Deezer écartées (D9).

## 4. Registre des décisions (`Dn`)

| Code | Décision | Statut |
|---|---|---|
| D1 | Projet **open source** ; licence GPL-3.0-or-later ; titulaire Eloi BERTIN (2026) | Tranchée 05/10/2026 |
| D2 | Moteur audio : `media_kit` unique, `just_audio` en repli Android. Le prototype démarre sur `just_audio` | **Provisoire** (dépend de l'Auto-test et du test SSD) |
| D3 | Gestion d'état et base de données | Ouverte |
| D4 | Nom définitif de l'application | Ouverte |
| D5 | Canaux de distribution (la release est signée avec la clé debug : TODO avant toute distribution) | Ouverte |
| D6 | Android Auto et Google Play | Ouverte |
| D7 | Identifiant d'organisation `net.trtl3` | Tranchée |
| D8 | Flutter/Dart, codebase unique | Tranchée |
| D9 | Lecteur local ; aucun catalogue sous licence ; pas de copie de l'identité Spotify/Deezer | Tranchée |
| D10 | **Android plateforme principale et prioritaire** ; Windows et macOS en pause (MPL-014) ; iOS hors périmètre ; Linux nice to have (MPL-030) | Tranchée (révisée 06/10/2026) |
| D11 | Android : MediaStore comme voie principale, pas de sélecteur de dossier (à revoir selon MPL-003) | Tranchée |
| D12 | Android Auto : Épique P2 (MPL-005), architecture audio prévue dès le départ | Tranchée |
| D13 | Volume : build B3 (`media_kit`, sans `ao=audiotrack`) ; normalisation par ReplayGain (MPL-019) | Tranchée |
| D14 | Valider tout item en **build release** avant fermeture (HOWTO §6) | Tranchée |
| D15 | Aucune requête réseau sortante (pas de `INTERNET` en release). Pourra être précisée par D20 | Tranchée |
| D16 | WMA non prioritaire ; MPL-009 abandonné | Tranchée 05/10/2026 |
| D17 | `main` orpheline et protégée ; merge par PR avec contrôles au vert ; push libre des branches de travail. La protection n'est pas appliquée tant que le dépôt est privé : en attendant, discipline (jamais de push direct) | Tranchée 05/10/2026 |
| D18 | Méthodologies hors dépôt | Remplacée par D21 |
| D19 | Dépôt public après licence + `main` + CI documentaire + audit (MPL-025) | Tranchée 05/10/2026 |
| D20 | Enrichissement en ligne optionnel : opt-in par fonction, cache local, variante de build séparée. Précisera D15. À trancher avant l'Épique MPL-004 | **Ouverte** |
| D21 | Organisation : documents à la racine ; méthodologies dans le dépôt privé `ai-tools` ; snapshots dans `docs/sprints/` | Tranchée 05/10/2026 |
| D22 | Les fichiers du dépôt sont modifiés par Claude Code ; ce Project rédige les prompts, challenge et relit | Tranchée 06/10/2026 |
| D23 | Modèle de « source de bibliothèque » : identifiant de volume, pistes disponibles ou indisponibles selon la présence du SSD, playlists pouvant mêler plusieurs sources | **Ouverte** (06/10/2026) |
| D24 | Le prototype reste dans un dépôt privé séparé (`music-player-prototype`) ; `music-player` ne contient que `main` et ses branches de travail | Tranchée 07/10/2026 |

## 5. Définition de « terminé » pour le prototype Android

| # | Critère | État |
|---|---|---|
| 1 | Lecture, pause, seek d'un fichier local | ✅ |
| 2 | Lecture écran verrouillé > 15 min avec enchaînement | ✅ |
| 3 | Notification, canal et contrôles | ✅ |
| 4 | Seek depuis la notification | ✅ |
| 5 | Persistance au redémarrage, touches des écouteurs | ✅ selon la clôture du Sprint 1 ; `RESULTS.md` §10 laissait « redémarrage » non testé — **à confirmer** |
| 6 | Auto-test échantillon non filtré, deux moteurs (~13 pistes) | ⬜ A1 |
| 7 | Fluidité (2 624 pistes), recherche, tri, exports | ⬜ A2 |
| 8 | Lecture d'une piste du SSD avec les deux moteurs ; comportement au débranchement | ⬜ A3 |
| 9 | Décision D2 | ⬜ A4 |
| 10 | « Tout » sur 2 624 pistes (≈ 4 h par moteur) | Optionnel |

## 6. Règles critiques à ne pas casser

1. Jamais de fermeture sans test réel en build release + confirmation explicite. Écrire « non testé » plutôt que « OK ».
2. Conserver `android/app/src/main/res/raw/keep.xml` (commit `38cbf32`).
3. Adaptateur `media_kit` : `playing` = intention de lecture (commit `d6f041c`).
4. Permission de notification en natif dans `MainActivity` (commit `cf79f4f`) ; pas de `permission_handler`.
5. Pendant un Auto-test, ne pas toucher à l'app.
6. Tests d'arrière-plan : téléphone débranché.
7. Un correctif = un commit annulable. Push libre des branches de travail ; **`main` uniquement par pull request** (D17), jamais de push direct, même si la protection n'est pas appliquée.
8. Aucune télémétrie, aucun réseau sortant (D15, sous réserve de D20).
9. Pas de gain de volume arbitraire (ReplayGain, MPL-019).
10. `media_kit` sur Android : chemin de fichier, pas d'URI `content://`.
11. **Deux dépôts, deux clones distincts.** Ne jamais ajouter l'un comme remote de l'autre. `music-player-prototype` ne devient jamais public.
12. `music-player` reste privé jusqu'à la fin de MPL-025.
13. Identité Git `Eloi BERTIN <228106+e7oi@users.noreply.github.com>`, configurée **dans les clones MusicPlayer seulement** (pas en global).
14. Les fichiers du dépôt sont modifiés par Claude Code (D22) ; les prompts interdisent tout push sur `main`.
15. La branche `mpl-002-audio-prototype` reste intacte jusqu'à la fermeture de MPL-002, puis reçoit l'étiquette `prototype-sprint1`.

## 7. Risques ouverts

- **Stockage amovible** : le SSD n'apparaît pas dans « Scanner MediaStore ». Cause non établie : requête limitée au volume principal, ou volume non indexé par Android. Impact possible sur D2, D3, MPL-017 et MPL-018.
- **Protection de `main`** non appliquée en dépôt privé gratuit : repose sur la discipline jusqu'à la publication.
- **Publication** : l'historique complet devient public ; e-mails des commits, chemins personnels, secrets à auditer (MPL-025).
- Release signée avec la clé debug ; build qui télécharge libmpv depuis github.com sans empreinte vérifiée ; licence libmpv sur Windows et macOS non vérifiée sur un build de l'app ; un seul appareil testé.
- Cause initiale de MPL-008 inconnue ; volume jamais mesuré en dB ; OpenSL ES à surveiller ; indexation, SQLite et gapless non essayés ; Android Auto et Google Play (D6).
- Minutes de GitHub Actions limitées en dépôt privé (la CI documentaire est légère).

## 8. Questions en attente

1. **Persistance après redémarrage** testée sur le Pixel ? (clôture du Sprint 1 : oui ; `RESULTS.md` §10 : non testé). Conditionne la formulation « validé partiellement » du PRD et du README.
2. **Diagnostic SSD** : sorties de `adb shell sm list-volumes all`, `ls /storage`, et de la requête `content://media/<uuid>/audio/media` (débogage sans fil).

## 9. Sources

- Dépôts liés au Project : `e7oi/music-player` (documents, snapshots), `e7oi/music-player-prototype` (code du prototype).
- Méthodologies : `ai-tools` (privé) et copies du Project (`backlog-methodology.md` v2.2, `sprint-methodology.md` v1.1, `init-methodology.md`, `synthese-conversation-*.md`).

---

*SPRINT-2-START.md v3 — 07/10/2026 · à placer dans `docs/sprints/sprint-2/` du dépôt `music-player` (via MPL-024)*
