# ADR-001 — Projet Flutter à la racine du dépôt

**Statut :** Active (validée le 2026-10-15) · **Date :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D2, D3, D7, D8, D10, D30

## Contexte

`CLAUDE.md` fixe un seul package Flutter, avec une organisation de `lib/` en ports et adaptateurs vérifiée par `test/architecture/`. `HOWTO.md` §2 décrit encore la commande du prototype, qui créait l'application dans un sous-dossier `musicplayer/`.

## Décision

- L'application de production est un seul package Flutter à la racine du dépôt (`pubspec.yaml`, `lib/`, `test/`, `integration_test/`, `android/`), créé avec `flutter create --org net.trtl3 --platforms=android` (D7). Windows et macOS ne sont pas générés tant qu'ils sont en pause (D10, MPL-014).
- Flutter est épinglé sur la dernière version stable au jour du démarrage du ticket, dans `pubspec.yaml` (`environment.flutter`) et en CI ; `pubspec.lock` est versionné (D30). La version exacte est notée dans la section as-built.
- Dépendances au départ : `flutter_riverpod` (providers écrits à la main, sans génération de code), `media_kit` et ses bibliothèques Android, `meta`, `collection` ; en développement : `very_good_analysis`, `riverpod_lint`. Drift n'est pas ajouté avant que MPL-018 en ait besoin.
- `test/architecture/` vérifie les règles d'import de `CLAUDE.md` en analysant les directives `import` de `lib/`.
- `HOWTO.md` §2 est mis à jour pour l'organisation à la racine.

## Conséquences

- Les documents racine et l'application partagent la racine ; `check-repo.sh` continue de fonctionner (il ne contrôle que les documents et les fichiers suivis interdits).
- `.gitignore` reçoit les entrées Flutter et Android (`build/`, `.dart_tool/`, `android/local.properties`, …).

## Alternatives examinées

- Application dans `musicplayer/` (organisation du prototype) : chaque étape de CI et chaque commande demande un dossier de travail, et les chemins de `CLAUDE.md` seraient faux. Écartée.

## As-built

MPL-017, 2026-10-15.

- Flutter 3.47.7 (Dart 3.13.5), épinglé dans `pubspec.yaml` (`environment.flutter: 3.47.7`) et dans `code-ci.yml`.
- Android : Gradle 9.3.1 (wrapper avec `distributionSha256Sum`), Kotlin 2.4.0, AGP 9.1.1, `compileSdk` et `targetSdk` 36, `minSdk` 24, NDK 28.2.13676358 (valeurs du gabarit). AGP 9.2.x existe, mais la table de compatibilité de Flutter 3.47.7 s'arrête à AGP 9.1 avec Gradle 9.3.1 (maximum connu) : 9.1.1 est la dernière version couverte.
- Identifiant Android `net.trtl3.musicplayer`, le même que le prototype (choix du propriétaire, 2026-10-15) : l'une remplace l'autre sur l'appareil.
- Dépendances : `flutter_riverpod` 3.4.3, `media_kit` 1.2.6, `media_kit_libs_audio` 1.0.7, `intl` 0.20.3 (imposé par `flutter_localizations`), `meta`, `collection` ; développement : `very_good_analysis` 11.0.0, `riverpod_lint` 3.1.9. Le plugin `riverpod_lint` est déclaré dans `analysis_options.yaml` avec sa version : elle est à tenir alignée sur la dépendance de développement.
- `flutter analyze` n'exécute pas les plugins d'analyse : `dart analyze --fatal-infos` est lancé en plus, en local et en CI.
- `public_member_api_docs` est désactivée : la dartdoc est écrite là où elle explique un contrat ou une raison, pas sur chaque membre.
- La syntaxe de constructeur `new(...)` de Dart 3.13 est imposée par la règle `unnecessary_type_name_in_constructor`.
- Localisation : `lib/l10n/app_en.arb` (modèle) et `app_fr.arb` ; code généré dans `lib/l10n/generated/`, versionné, exclu de l'analyse et des tests d'architecture.
- `ProviderScope` en place, aucun provider : le câblage du `PlayerController` attend les adaptateurs `VolumeEvents` et `TrackSourceOpener` (MPL-035, MPL-018).
- Build release : APK multi-ABI de 64,5 Mo ; aucune permission `INTERNET`. Le build télécharge libmpv depuis GitHub sans vérifier d'empreinte (MPL-026).
