# CLAUDE.md — TuneShell (`tuneshell`)

> Le contexte produit et le périmètre sont dans `PRD.md` (§9 décisions, §10 risques). Le backlog et le registre des décisions sont dans `docs/backlog.md` ; `docs/sprints/` contient les snapshots de sprint figés. Ne pas les dupliquer ici.

## Travailler avec le propriétaire

- Parler au propriétaire en français. Tout ce qui est écrit dans le dépôt suit la table de langue ci-dessous.
- Lire l'état réel du dépôt avant d'écrire. Ne rien restaurer de mémoire. Ne rien inventer.
- Ne jamais clore un item sans test réel sur le Pixel, en build release, confirmé par le propriétaire (D14). Écrire « non testé » plutôt que « OK ».
- Ne pas commencer de travail hors de l'item confié (clé MPL). Signaler les manques et les contradictions au lieu de choisir.

## Règles Git et dépôt

- Ne jamais pousser sur `main`. Travailler sur une branche, un commit annulable par correctif. N'ouvrir aucune pull request sans demande ; le propriétaire crée les PR.
- `main` est protégée (ruleset `protect-main`, D17). Aucun code applicatif n'arrive sur `main` sans job de CI code : MPL-017 ajoute un job minimal (format, analyse, tests) ; MPL-026 le complète (vulnérabilités, licences, liste blanche des permissions, empreinte de libmpv).
- L'identité Git est le nom du propriétaire et son adresse noreply GitHub, configurés localement dans chaque clone TuneShell, jamais en global. Vérifier `git config user.name` et `git config user.email` par rapport aux derniers commits (`git log -1 --format='%an <%ae>'`) avant le premier commit.
- Deux dépôts, deux clones. Ne jamais ajouter l'un comme remote de l'autre. `music-player-prototype` est privé et ne devient jamais public.
- Rien de privé dans ce dépôt public : aucun titre de piste, nom d'artiste ou d'album, nom de fichier, chemin sur l'appareil, identifiant de volume ou numéro de série, adresse e-mail. Les exports d'essai (CSV, journaux, logcat) restent hors du dépôt (D27).
- Les documents racine restent à la racine et les snapshots de sprint de `docs/sprints/` sont figés. `.github/scripts/check-repo.sh` doit rester au vert.

## Langue (D28, révisée le 2026-10-15)

| Élément | Langue |
|---|---|
| Identifiants, fichiers, dossiers, tables et colonnes de la base, clés ARB | anglais |
| Commentaires de code, dartdoc, commentaires Kotlin | anglais |
| Messages de commit (Conventional Commits), noms de branches | anglais |
| Titres et descriptions de PR | anglais |
| Noms de tests et de groupes | anglais |
| Messages d'exception, journaux, diagnostics | anglais |
| Textes visibles par l'utilisateur | fichiers ARB, jamais en dur |
| Documentation et règles : `PRD.md`, `README.md`, `CHANGELOG.md`, `HOWTO.md`, `CLAUDE.md`, `.claude/commands/`, `docs/` (backlog, fiches, ADR, documents techniques de référence, snapshots) | français |

Principe : le code et son historique sont en anglais ; la documentation et les règles sont en français. La documentation sera traduite à la version de production ; l'historique Git ne se traduit pas. Un commentaire explique pourquoi, jamais quoi.

## Architecture

Ports et adaptateurs, en version légère. Un seul package Flutter, organisation de `lib/` :

```text
lib/
  main.dart        amorçage seulement
  app/             racine de composition : câblage des providers (app/providers/), routeur, thème
  domain/<zone>/   Dart pur : model/, ports/ (interfaces), services/ (dont PlayerController)
  data/<zone>/     adaptateurs : base Drift, moteur media_kit, scanner
  platform/        côté Dart des canaux Android (SAF, événements de volume) ; le Kotlin est dans android/
  features/<nom>/  présentation : écrans et notifiers Riverpod
  ui/              thème, jetons et composants réutilisables (ADR-010) ; Flutter seul, sans logique métier
  l10n/            fichiers ARB et localisations générées
```

Règles de dépendance (vérifiées par `test/architecture/`, voir Outillage) :

1. `domain/` n'importe que `dart:core`, `dart:async`, `dart:math`, `dart:convert`, `package:meta`, `package:collection` et lui-même. Jamais Flutter, `dart:io`, `dart:ui`, Drift, Riverpod, `media_kit`, `audio_service`.
2. `data/` et `platform/` n'importent que `domain/` (plus leur propre paquet tiers). Jamais `features/` ni `app/`.
3. `features/` n'importe que `domain/`, `l10n/`, `ui/` et `app/providers/`. Jamais `data/` ni `platform/`.
4. `package:media_kit` n'est importé que sous `data/audio/`. Drift seulement sous `data/db/`. `package:flutter/services.dart` (canaux) seulement sous `platform/` et `app/`, et sous `ui/` pour `HapticFeedback` seulement.
5. Toujours des imports de package (`always_use_package_imports`) ; aucun import relatif sous `lib/`.
6. `ui/` n'importe que Flutter, `l10n/` et lui-même. Jamais `domain/`, `data/`, `platform/`, `app/`, `features/` ni Riverpod : un composant reçoit des valeurs simples et des fonctions de rappel (ADR-010).
7. Un port par frontière réelle (moteur, événements de volume, ouverture des sources, dépôts). Un fake dans `test/` compte comme seconde implémentation. Pas de port sans frontière, pas de cérémonie « une classe par cas d'usage », pas de couche application séparée.

## Interface (MPL-016)

- La conception (Claude Design v0.4) est dans `docs/design/` : `HANDOFF.md` fait foi, puis les jetons, puis les sources `*.dc.html`, puis les captures. Les règles d'interface sont dans BR-007 ; les composants dans FR-010.
- Les couleurs, rayons, espacements et tailles viennent de `lib/ui/theme/tuneshell_tokens.dart` : jamais de littéral dans `features/` ni `ui/widgets/` (test `test/architecture/style_literals_test.dart`). Un jeton qui manque s'ajoute au fichier et se signale dans la PR.
- Un état qui dure (source absente, erreur, progression) est un composant dans le flux au-dessus de la liste, jamais par-dessus (`StatusBanner`, `ProgressBanner`).
- Pas de fichier golden : un test de widget par état de composant, des assertions de comportement (taille tactile, `Semantics`, saut de l'index).

## Contrat du moteur audio (D2)

`media_kit` est le seul moteur, derrière le port `AudioEngine` de `domain/playback/ports/`. Il n'y a pas de sélecteur de moteur (`engineFactories` et `switchEngine` sont propres au prototype et ne sont pas repris).

- Écrire le contrat en dartdoc sur l'interface et sous forme de suite exécutable `test/contract/audio_engine_contract.dart`, lancée contre `FakeAudioEngine` en CI et contre l'adaptateur `media_kit` dans `integration_test/` sur un appareil.
- `open` charge sans démarrer la lecture et peut rendre la main avant que la durée soit connue ; la durée arrive sur `durationStream`. L'état `loading` n'est pas garanti.
- `play()` rend la main dès que la lecture est demandée. `playing` est l'intention et reste vrai d'une piste à l'autre.
- `completed` est émis une fois par piste.
- `stop()` ne rend la main qu'une fois que le moteur a cessé de lire et libéré toutes ses ressources, descripteurs de fichiers compris. Il est idempotent. Seule exception (BR-002, règle 7) : si le moteur n'a pas fermé le fichier dans le délai, `stop()` rend la main et le descripteur est libéré plus tard, jamais pendant que le moteur peut le lire.
- Les problèmes du moteur sont typés : `sealed class EngineIssue` avec `EngineFailure` (fatal pour la piste en cours : le contrôleur saute ou signale) et `EngineWarning` (ne change jamais l'état, journalisé et compté). Les adaptateurs classent ; le contrôleur traite tous les cas (`switch` exhaustif). Un `end-file` avec une raison d'erreur est toujours un échec ; les messages non classés sont des avertissements de type `unclassified`. Les tests de classement utilisent des messages réels enregistrés (MPL-010).

## Stockage et volumes amovibles (D25, D23)

- Stockage interne : MediaStore et chemin de fichier. Stockage amovible : SAF, et `media_kit` le lit par `fd://N` obtenu avec `openFileDescriptor` + `detachFd`. Jamais de `content://` direct (fuite d'un descripteur par piste) ni de `/proc/self/fd/N` (EACCES).
- L'éjection d'un volume passe par le port `VolumeEvents` (`domain/storage/ports/`), implémenté dans `platform/` avec un EventChannel et un `StorageVolumeCallback` natif. Le contrôleur n'importe jamais de canal.
- À l'annonce `ejecting` du disque de la piste en cours : `await engine.stop()` d'abord, puis marquer le disque indisponible. Ne jamais fermer un descripteur que le moteur lit encore. Le côté natif ne ferme pas de descripteur de lui-même.
- Une piste est identifiée par (disque, chemin relatif) ; le disque par l'UUID de son système de fichiers. Les pistes d'un disque absent restent dans la bibliothèque, grisées, et sont sautées pendant la lecture avec un message.

## Règles Android reprises du prototype

- Conserver `android/app/src/main/res/raw/keep.xml` (sinon les icônes de notification sont supprimées en release).
- L'état `playing` de l'adaptateur est l'intention de lire, pas l'état momentané du moteur.
- La permission de notification (`POST_NOTIFICATIONS`) est déclarée sans être demandée (FR-005, exigence 11) ; ne pas ajouter `permission_handler`.
- Aucune télémétrie ni réseau en release (D15, D26). `INTERNET` n'est déclarée que dans une variante de build en ligne dédiée.

## Tests

- Test d'abord pour `domain/` et la logique d'état (notifiers Riverpod) : rouge, vert, refactorisation. Un correctif de bug commence par un test qui échoue quand le bug est reproductible hors appareil.
- Préférer les fakes aux mocks pour les ports. Les tests Drift utilisent une base en mémoire ; les migrations de schéma sont testées à partir des dumps de schéma versionnés.
- Exceptions au test d'abord, à mentionner dans la PR : le code natif Kotlin de liaison (SAF, callbacks de stockage) et les protocoles sur appareil (lecture en arrière-plan, écran verrouillé, éjection, SSD) : une procédure écrite dans `HOWTO.md` remplace le test unitaire et le résultat est rapporté comme testé ou non testé ; la mise en page (les tests de widgets vérifient le comportement, pas de fichiers golden) ; le code généré ; le câblage trivial dans `app/`.
- Une logique livrée sans test est signalée comme dette dans la description de PR, jamais passée sous silence.
- Tests sur appareil : Pixel 10 Pro, build release, `adb` en Wi-Fi quand le SSD occupe le port USB-C, `ANDROID_SERIAL` s'il y a plusieurs appareils, téléphone débranché pour les tests d'arrière-plan, ne pas toucher à l'app pendant un Auto-test.

## Outillage

Les commandes ci-dessous existent une fois MPL-017 livré ; ne pas les supposer avant.

- Format : `dart format --set-exit-if-changed .`
- Analyse : `flutter analyze --fatal-infos` puis `dart analyze --fatal-infos`, avec `very_good_analysis`, `strict-casts`, `strict-inference`, `strict-raw-types` et le plugin d'analyse `riverpod_lint`. `flutter analyze` n'exécute pas les plugins d'analyse : seul `dart analyze` lance `riverpod_lint`.
- Tests : `flutter test` (inclut `test/architecture/`). Tests sur appareil avec `flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/<fichier>_test.dart` : `flutter drive` refuse la release, et le profile est compilé en natif (AOT) comme elle ; `flutter test integration_test` ne compile qu'en debug. Le test réel de l'application reste en build release (D14). Procédure : `HOWTO.md` §10.
- Code généré : Drift seulement (`dart run build_runner build --delete-conflicting-outputs`) ; les fichiers `*.g.dart` sont versionnés, marqués `linguist-generated`, exclus de l'analyse, et la CI vérifie qu'ils sont à jour avec `git diff --exit-code` après régénération. Les providers Riverpod sont écrits à la main : pas de génération de code Riverpod, pas de `freezed`.
- Localisation : `flutter gen-l10n` ; fichiers générés versionnés sous `lib/l10n/` ; la CI échoue si une clé manque dans une langue livrée.

## Dépendances et versions (D30, provisoire)

- Utiliser la dernière version stable des langages, outils et bibliothèques, pour la sécurité, les fonctions et les performances, tant que la version de Flutter épinglée la prend en charge. L'outil Flutter fait office de matrice de compatibilité : Gradle, AGP et Kotlin ne dépassent jamais les valeurs `maxKnownAndSupported*` de `packages/flutter_tools/lib/src/android/gradle_utils.dart` au tag Flutter épinglé, et `compileSdk`, `targetSdk`, `minSdk` et le NDK partent des valeurs par défaut du gabarit Flutter (`FlutterExtension.kt`).
- Tout épingler : version de Flutter dans `pubspec.yaml` et en CI, `pubspec.lock` versionné, wrapper Gradle avec `distributionSha256Sum`, GitHub Actions par SHA de commit, libmpv par SHA-256 (MPL-026). Pas de `any`, pas de dépendance git ou path, pas de préversion sur `main`.
- Mises à jour par Dependabot (hebdomadaire) : correctifs et versions mineures groupés ; chaque version majeure dans sa propre PR ; SDK Flutter, wrapper Gradle, AGP et Kotlin mis à jour à la main.
- Une version majeure qui touche la lecture, le stockage ou les notifications (`media_kit`, `audio_service`, Gradle, AGP) exige un test rapide sur appareil avant le merge.
- Les avis de sécurité (GitHub Advisory Database, affichés par `dart pub get`) sont traités hors cycle. `ignored_advisories` dans `pubspec.yaml` exige une justification écrite. Une analyse de vulnérabilités de `pubspec.lock` tourne en CI (MPL-026).
- Une dépendance en retard sur l'amont (bibliothèques natives, bibliothèques Android de `media_kit`) est une dérogation : noter le paquet, la version retenue, le blocage et une date de revue sous 90 jours dans `docs/dependency-exceptions.md`.
- Les bibliothèques natives (libmpv, FFmpeg) sont hors périmètre ici (prompt séparé).

## Commits et pull requests

- Conventional Commits avec la clé du backlog : `type(scope): imperative summary (MPL-018)`, en-tête de 72 caractères au plus, corps qui explique pourquoi.
- Types : `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`. Scopes : `library`, `playback`, `storage`, `db`, `ui`, `l10n`, `deps`, `ci`, `android`.
- Plusieurs clés si nécessaire : `(MPL-017, MPL-035)`. Un changement cassant ajoute `!`.
- Description de PR (en anglais) : ce qui change, pourquoi, comment c'est testé (appareil et résultat, ou « not tested »), limites connues. Merge en squash ; le titre de la PR est l'en-tête du commit.

## Flux de travail (Claude Code seulement)

Rôle : analyste + tech lead / développeur dans une seule session. Le propriétaire (PO) décide et ferme les tickets. Claude Chat n'écrit ni ne modifie ce projet (au plus du brainstorming en lecture seule).

### Cadrer avant de coder

Tout ticket non trivial commence par `/cadrer` (`.claude/commands/cadrer.md`), en mode plan : challenger la demande, écrire les fiches UC/BR/FR en `Brouillon` dans `docs/fonctionnel/`, les ADR dans `docs/technique/decisions/` (`ADR-NNN-<slug>.md`), et le ticket dans `docs/backlog.md`, puis **s'arrêter** pour la validation du propriétaire. Pas de code tant que les fiches concernées ne sont pas `Active`.

- `docs/backlog.md` est écrit et tenu par toi ; le propriétaire relit le diff. Statuts : À faire → En cours (tu commences) → À tester (tu livres) → Terminé ; Bloqué reste possible. Tu passes un ticket à Terminé seulement sur l'ordre explicite du propriétaire (« validé »), après le test réel sur appareil (D14) **et** après le merge de la PR.
- Idée en vrac (« note au backlog : X ») : une ligne « À faire » dans Actifs avec une description d'une ligne, sans fiches ni `/cadrer`.
- Une décision prise en discussion, tranchée ou écartée : une ligne dans la section Décisions (Tranchée / Ouverte / Provisoire / Écartée) avec le motif. Une discussion sans décision n'est écrite nulle part. Ne numérote pas une décision toi-même : propose la ligne, le propriétaire attribue le `Dn`.
- Fiche absente ou en `Brouillon` au moment d'implémenter : s'arrêter et le dire. Ne jamais modifier une BR `Active` de ta propre initiative : un écart ou un cas non couvert devient une ligne `À valider`. Décision d'architecture ou de périmètre non tranchée : s'arrêter et demander.
- Dès que `docs/fonctionnel/` contient des fiches avec identifiants, mettre `@implements` / `@verifies` / `@decision` en dartdoc juste au-dessus du symbole qui implémente ou teste la règle.

### Branches et pull requests

- Un ticket = une branche `mpl-NNN-<slug>`, créée depuis `main` quand le ticket passe « En cours ». Tous les commits du ticket (code, fiches, as-built, bloc Livraison) y vivent. Jamais de push sur `main`.
- Livrer « À tester » = branche poussée, vérification au vert, description de PR (quoi, pourquoi, comment testé, limites connues) écrite dans le bloc Livraison. Le propriétaire crée la PR et teste sur le Pixel.
- Sur « validé » : attendre le merge en squash du propriétaire, puis `git switch main && git pull`, supprimer la branche locale et distante, et clore le ticket (Terminé, déplacé dans Terminés). `main` est protégée, donc le commit de clôture (`docs(backlog): close ticket after owner validation (MPL-NNN)`) va sur la branche du ticket suivant, ou sur une courte branche `docs/close-mpl-NNN` si le propriétaire le veut tout de suite.
- Les changements de documentation sans ticket vont sur une branche `docs/<slug>`, eux aussi par PR.

### Définition de « terminé »

1. Besoin compris (fiches `Active` lues).
2. Implémenté, test d'abord pour `domain/` et la logique d'état.
3. Vérification au vert et scénarios Gherkin du ticket au vert ; citer la commande et le résultat. Avant MPL-017 : `.github/scripts/check-repo.sh`. Ensuite : `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && dart analyze --fatal-infos && flutter test`. Ce qui ne se vérifie que sur appareil reste « non testé » jusqu'à la confirmation du propriétaire (D14).
4. Documentation as-built des fiches touchées mise à jour dans le même commit.
5. Revue QA ✅ (ci-dessous), ou non requise.

Un point manquant donne le statut ⚠️ dans le bloc Livraison, jamais ✅.

### Revue QA : automatique

Sauf pour les correctifs rapides sans logique (style, texte, configuration), lancer un sous-agent à contexte neuf en mode revue. Ne lui donner que le ticket, les identifiants des fiches et le diff, jamais ton raisonnement. Bloquants : corriger et relancer (2 tours au plus), puis ⚠️. Lecture, accès au stockage, permissions, migrations de base : revue obligatoire, et signaler au propriétaire qu'une session séparée `>>> REVUE` est possible.

Mode revue : observer, ne rien corriger. Lire les fiches et le diff avant la livraison du développeur. Vérifier : BR/FR respectées et scénarios Gherkin couverts par un test, cas limites, tags de traçabilité, standards (ce fichier), sécurité et données privées (aucun titre de piste, chemin ou identifiant de volume dans le dépôt, D27), fiches as-built, changements hors périmètre. Chaque constat cite l'identifiant de la règle et fichier:ligne. « Non vérifié » est obligatoire.

### Fin de tâche

Ajouter (ou mettre à jour) un bloc **Livraison** sous le ticket dans la section « Détails » de `docs/backlog.md`, commité avec la tâche, et passer le ticket à « À tester » (statut ⚠️ ou ❌ : le laisser « En cours » ou « Bloqué »). Format :

```text
#### Livraison — AAAA-MM-JJ
Statut : ✅ fait / ⚠️ partiel / ❌ bloqué
Résumé : <2-3 lignes>
Fiches touchées : <IDs, as-built mis à jour ou inchangées>
Vérification : <commande> → <résultat : tests unitaires et scénarios>
Test appareil (Pixel, release) : <fait / non testé>
Revue QA : ✅ / ⚠️ / non requise (<motif>) — Non vérifié : <ou « rien »>
Description de PR : <titre = en-tête de commit ; quoi, pourquoi, comment testé, limites>
Décisions prises en route : <ou « aucune »>
À valider (PO) : <ou « aucun »>
```
