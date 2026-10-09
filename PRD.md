# PRD — MusicPlayer

**Version :** 0.2 · **Dernière MAJ :** 09/10/2026 · **Préfixe backlog :** MPL · **Licence :** GPL-3.0-or-later

> Le backlog (`MPL-NNN`) et le registre des décisions (`Dn`) sont tenus dans les conversations du Project et figés à chaque clôture de sprint dans `docs/sprints/`. Ce document fixe le produit, le périmètre et les critères de succès.

---

## 1. Problème

Les lecteurs locaux (Winamp, VLC) ont des interfaces datées. Les services de streaming (Spotify, Deezer) ont une excellente expérience, mais gèrent mal les bibliothèques locales, imposent des comptes, de la publicité ou un abonnement, et collectent des données.

## 2. Vision

Un **lecteur audio local, libre (open source), gratuit, sans publicité, sans compte et sans télémétrie**, avec l'expérience d'utilisation d'un service de streaming moderne (accueil dynamique, mix automatiques, pages artiste/album, lecteur plein écran).

## 3. Utilisateur cible

Personne possédant une bibliothèque de fichiers audio (téléphone, disque interne ou externe) qui veut une interface moderne sans dépendre d'un service en ligne.

## 4. Plateformes

| Plateforme | État | Remarque |
|---|---|---|
| Android | **P0 — en cours ; plateforme principale et prioritaire** | Accès aux pistes via MediaStore (`READ_MEDIA_AUDIO`). Prototype audio **validé sur Pixel 10 Pro** (build release) : lecture, arrière-plan écran verrouillé, notification et contrôles, persistance de la liste, Auto-test des formats ; stockage amovible : accès au SSD par le sélecteur Android (SAF) vérifié sur le Pixel dans le prototype (MPL-003, terminé avec réserves) ; retrait pendant la lecture non traité hors prototype (MPL-035) (Android 17) |
| Windows 11 | P0 cible — **en pause** | Reprise après la stabilisation d'Android (MPL-014) |
| macOS | P0 cible — **en pause** | App Sandbox + entitlements ; compilation requiert un Mac (ou CI macOS) |
| iOS | Hors périmètre actuel | Pas d'appareil de test ; même codebase si repris plus tard |
| Linux | Nice to have, non engagé | MPL-030 |

**Stack :** Flutter / Dart (un seul codebase).

## 5. Objectifs

1. Lire fiablement les formats courants (MP3, FLAC, AAC/M4A, OGG/OPUS, WAV ; ALAC à valider). WMA non prioritaire (D16).
2. Indexer une bibliothèque locale (tags, pochettes) avec recherche rapide.
3. Offrir une UX moderne et adaptative (mobile : navigation basse ; desktop : panneau latéral).
4. Respecter la vie privée : aucune donnée ne quitte l'appareil.
5. Garantir la qualité : aucun code n'entre dans `main` sans contrôles de style, de tests et de sécurité au vert (voir §11).

## 6. Non-objectifs

- Aucun catalogue de streaming sous licence.
- Aucune publicité, aucun compte obligatoire, aucune télémétrie.
- Aucune copie de l'identité visuelle de Spotify/Deezer (marque, couleurs, logo, icônes).
- Aucune garantie de lecture du format WMA.

## 7. Périmètre

**MVP (Épique « Lecture locale », MPL-001)**
- Prototype de lecture d'un fichier local sur Android (Windows et macOS en pause)
- Accès aux pistes par MediaStore sur Android ; dossiers persistants avec validation disque externe (MPL-003) pour le reste
- Indexation (tags, pochettes) dans SQLite
- Lecteur : play/pause/seek, file d'attente, mini-lecteur, lecture en arrière-plan
- Contrôles système (écran verrouillé, touches média)

**Phase 3 — P2, non urgent (Épique « Voiture / Android Auto », MPL-005)**
_Prévue après l'Épique « Expérience de type streaming ». L'architecture audio (`audio_service` + arbre média) est conçue dès le départ pour rendre cet ajout peu coûteux._
- Compatibilité **Android Auto** : arbre de navigation média (artistes, albums, playlists, récents) exposé via `MediaBrowserService`, lecture et contrôles depuis l'écran de la voiture. L'interface est fournie par Android Auto (gabarits imposés), pas par Flutter.
- Conception « conduite » : gros boutons, navigation vocale (« joue… »), aucune interaction complexe.
- Hors périmètre pour l'instant : Android Automotive OS (système intégré à la voiture, build distinct) et Apple CarPlay (lié à iOS).

**Phase 2 (Épique « Expérience de type streaming », MPL-004)**
- Accueil dynamique (récemment ajoutés / écoutés / plus joués)
- Mix automatiques depuis les tags (genre, décennie, artiste, « redécouvre »)
- Pages artiste et album, playlists
- Gapless, crossfade, égaliseur, minuteur de sommeil
- Normalisation du volume (ReplayGain, MPL-019)
- Paroles synchronisées (`.lrc` / tags)
- Lecture de web-radio (France Info, Radio-Canada, France Inter, Radio Nova, CBC...) (MPL-033), fonction en ligne soumise à D26

**Transversal — Épique « Qualité, CI et documentation » (MPL-020)**
- Licence, `main` protégé, CI documentaire puis CI code, tests fonctionnels, fraîcheur des documents, publication du dépôt

**Extensions possibles (non engagées)**
- Podcasts (RSS)
- Connexion à un serveur perso (Navidrome, Jellyfin, Subsonic)
- Linux desktop (nice to have, non engagé ; MPL-030)

## 8. Critères de succès

- Lecture d'un fichier local validée par test réel **en build release** sur Android (puis Windows et macOS à la reprise)
- Auto-test des formats réussi sur un échantillon représentatif
- Bibliothèque de 10 000 pistes indexée et navigable sans lenteur perceptible (bibliothèque de test actuelle : 2 624 pistes, 92 % MP3 ; inventaire du Sprint 1 : `docs/sprints/sprint-1/SPRINT-1-CLOSURE.md` §3)
- Lecture en arrière-plan stable sur Android
- Aucune requête réseau sortante dans l'usage de base, dans la variante offline (la build release ne déclare pas `INTERNET` ; `ACCESS_NETWORK_STATE`, ajoutée par une dépendance, est tolérée) ; les fonctions en ligne (web-radio, enrichissement) n'existent que dans une variante de build qui déclare `INTERNET` (D26)

## 9. Décisions structurantes (état au 09/10/2026)

Le registre complet (`Dn`) est tenu dans le backlog. Résumé des décisions qui fixent ce document :

| Code | Décision | Statut |
|---|---|---|
| D1 | Projet open source ; licence GPL-3.0-or-later | Tranchée 05/10/2026 |
| D2 | Moteur audio : `media_kit` (libmpv/FFmpeg) est le **moteur unique** de l'application réelle, derrière une **interface indépendante du moteur** (`PlayerController`, MPL-017) qui permet de changer de moteur plus tard ; `just_audio` n'est pas repris dans l'application réelle, le prototype reste la référence. Motifs : un seul moteur à tester et à maintenir, WMA lisible (D16 : toujours non prioritaire), ReplayGain possible via mpv (MPL-019, D13), même moteur sur Windows et macOS. Conséquences acceptées : les WARN de MPL-010 (sans effet audible constaté) ; poids de l'APK non mesuré (risque à suivre). Tests SSD du 08/10/2026 : les deux moteurs lisent le SSD et réagissent de la même façon au retrait ; remplace la recommandation de `docs/sprints/sprint-1/RESULTS.md` §6 (snapshot Sprint 1) | Tranchée 09/10/2026 |
| D3 | Base locale : SQLite via **Drift** (requêtes typées, migrations de schéma versionnées, flux réactifs, exécution en isolate, recherche plein texte FTS5 possible). Gestion d'état : **Riverpod**. Motif de la base : le modèle D23 est relationnel (disques, pistes par disque + chemin relatif, playlists mêlant plusieurs disques) ; Isar (état de maintenance en 2026 non vérifié) et ObjectBox (plus de natif, relations moins naturelles) ne sont pas retenus. Reporté à l'implémentation : la version exacte de Riverpod et l'usage ou non de sa génération de code (en plus de celle de Drift) | Tranchée 09/10/2026 |
| D4 | Nom définitif de l'application | Ouverte |
| D5 | Canaux de distribution (stores, téléchargement direct, F-Droid) | Ouverte |
| D6 | Android Auto et Google Play (apps non installées via le Play Store non visibles dans Android Auto hors mode développeur, à revérifier) | Ouverte |
| D7 | Identifiant d'organisation `net.trtl3` | Tranchée |
| D10 | Android d'abord ; Windows et macOS en pause ; iOS hors périmètre | Tranchée |
| D11 | MediaStore comme voie principale, pas de sélecteur de dossier | Remplacée par D25 |
| D13 | `media_kit` avec sa sortie par défaut (OpenSL ES), sans `ao=audiotrack` ; écart léger accepté ; normalisation par ReplayGain (MPL-019) | Tranchée |
| D16 | WMA non prioritaire | Tranchée 05/10/2026 |
| D20 | Enrichissement en ligne optionnel, variante de build séparée, opt-in, cache local ; préciserait D15 (« aucun réseau sortant ») | Ouverte |
| D21 | Organisation : documents à la racine, méthodologies dans le dépôt privé `ai-tools`, snapshots dans `docs/sprints/` | Tranchée 05/10/2026 |
| D23 | Modèle de « source de bibliothèque » : une source est un **disque** : le stockage interne (« Local ») ou un volume amovible, identifié par l'UUID de son système de fichiers. Un disque contient les dossiers choisis par l'utilisateur ; une piste est identifiée par (disque, chemin relatif). Les pistes d'un disque absent restent dans la bibliothèque, grisées ; pendant la lecture, elles sont sautées avec un message (du type « 12 pistes ignorées : SSD absent »). Une playlist peut mêler les pistes de plusieurs disques. Si l'utilisateur ajoute un disque dont les chemins relatifs correspondent à ceux d'un disque absent, l'application propose de le réassocier (playlists, favoris et statistiques conservés). Dans l'interface, la source est le disque (« SSD : 26 pistes, indisponible »), et non chaque dossier comme dans le prototype | Tranchée 09/10/2026 |
| D24 | Le prototype reste dans un dépôt privé séparé | Tranchée |
| D25 | Android : MediaStore pour le stockage interne, sélecteur Android (SAF) pour le stockage amovible USB ; remplace D11. Accès SSD par SAF vérifié sur le Pixel 10 Pro (MPL-003) ; risque du retrait pendant la lecture traité par le spike (MPL-035) | Tranchée 09/10/2026 |
| D26 | Toute fonction en ligne (dont la web-radio et l'enrichissement de D20) n'existe que dans une variante de build qui déclare `INTERNET` ; la variante « offline » n'a pas de réseau | Provisoire |

## 10. Risques

- **Audio multiplateforme** : couche la plus fragmentée de l'écosystème Flutter → prototype en premier.
- **Licence de libmpv/FFmpeg embarqués par `media_kit`** : LGPL v3 mesurée sur le binaire Android ; Windows et macOS vérifiées sur les archives épinglées par le paquet, pas sur un build de l'application (voir `docs/sprints/sprint-1/RESULTS.md` §5). D1 réduit fortement ce risque : une application GPL-3.0-or-later reste compatible avec une build GPL de libmpv.
- **Build qui télécharge libmpv depuis github.com** : pas de build hors ligne reproductible.
- **Release signée avec la clé debug** (TODO dans `build.gradle.kts`) : à traiter avant toute distribution (D5).
- **Android** : scoped storage et service d'arrière-plan ; un seul appareil testé ; disque externe à valider.
- **SSD USB-C non visible des applications** : accès par le sélecteur Android, lecture `media_kit` à prototyper.
- **Retrait du SSD pendant la lecture** : sans arrêt préalable du moteur, Android tue l'app (`vold` détecte un descripteur ouvert sur le volume et envoie `SIGINT`, environ 1 s après l'éjection). Mitigation (arrêt du moteur dès l'annonce d'éjection) essayée en spike seulement : 5 essais, un Pixel, un SSD ; marge sous charge non vérifiée (MPL-035).
- **Poids de l'APK de `media_kit`** (libmpv/FFmpeg) : non mesuré ; à suivre (D2).
- **Dépendance à des fonctions Android précises** (SAF, éjection de volume) : à retester sur d'autres appareils et versions d'Android (D25).
- **macOS** : sandbox et entitlements ; accès disque qui échoue silencieusement si mal configuré.
- **Android Auto** : exige une architecture média native (service + session média), des critères de qualité Google pour être listé sur Google Play, et un test sur émulateur DHU ou en voiture.
- **Publication du dépôt** : expose l'historique complet ; le dépôt est public depuis le 08/10/2026, audit fait (MPL-025).

## 11. Qualité, licence et dépôt

- **Licence :** GPL-3.0-or-later (fichier `LICENSE` à la racine). Titulaire du copyright : Eloi BERTIN (2026).
- **Branches :** `main` est protégée (ruleset appliqué depuis le 08/10/2026, test de refus du push direct réussi) ; toute modification passe par une pull request. Les branches de travail peuvent être poussées librement.
- **Contrôles avant merge sur `main` :** format, analyse statique stricte, tests unitaires et widgets, détection de secrets, vulnérabilités et licences des dépendances, liste blanche des permissions du manifest de la build release, documentation à jour.
- **Tests fonctionnels :** sur appareil réel, en build release, avant la fermeture d'un item.
- **Visibilité :** dépôt public depuis le 08/10/2026 (après la mise en place de la licence, de la protection de `main` et de l'audit).
- **Documentation :** le dépôt est la source de vérité.
