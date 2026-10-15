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

Néant (non implémenté).
