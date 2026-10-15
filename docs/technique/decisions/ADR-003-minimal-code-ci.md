# ADR-003 — Job de CI code minimal

**Statut :** Active (validée le 2026-10-15) · **Date :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D17, D30 · **Complété par :** MPL-026

## Contexte

`main` est protégée par le ruleset `protect-main` (D17), avec les contrôles requis de `docs-ci`. Aucun code applicatif ne peut arriver sur `main` sans job de CI code (décision du 2026-10-15).

## Décision

- Nouveau workflow `.github/workflows/code-ci.yml`, déclenché comme `docs-ci` (pull requests et push sur `main`, lancement manuel), `permissions: contents: read`, actions épinglées par SHA de commit.
- Un job `code-checks` sur `ubuntu-24.04`, Flutter épinglé sur la version d'ADR-001 :
  1. `flutter pub get` avec le `pubspec.lock` versionné (`--enforce-lockfile`) ;
  2. `dart format --set-exit-if-changed .` ;
  3. `flutter analyze --fatal-infos` ;
  4. `flutter test` (inclut `test/architecture/` et la suite de contrat contre le fake).
- Pas de build Android, ni de contrôle des vulnérabilités, des licences ou des permissions dans ce job : MPL-026.
- Dependabot reçoit l'écosystème `pub` (hebdomadaire, correctifs et versions mineures groupés, D30).

## Conséquences

- `code-checks` est un contrôle requis de `protect-main` depuis le 2026-10-15, avant que le workflow existe. Tant que `code-ci.yml` n'est pas sur `main`, une pull request ne peut être fusionnée que si elle apporte elle-même le workflow : les documents de cadrage de MPL-017 voyagent donc sur la branche de MPL-017.
- Le job consomme des minutes GitHub Actions à chaque PR, PR de documentation comprises. Pas de filtre de chemins, car un contrôle requis qui ne s'exécute jamais bloque le merge.

## As-built

MPL-017, 2026-10-15. `.github/workflows/code-ci.yml`, job `code-checks` : `flutter pub get --enforce-lockfile`, `dart format --set-exit-if-changed .`, `flutter gen-l10n` suivi de `git diff --exit-code -- lib/l10n` et d'une vérification que `build/untranslated-messages.json` vaut `{}` (clé manquante dans une langue livrée), `flutter analyze --fatal-infos`, `dart analyze --fatal-infos` (plugin `riverpod_lint`), `flutter test`. Action `subosito/flutter-action` v2.23.0 épinglée par SHA. Dependabot : écosystème `pub` hebdomadaire, correctifs et versions mineures groupés.

Première exécution : à la création de la pull request de MPL-017.
