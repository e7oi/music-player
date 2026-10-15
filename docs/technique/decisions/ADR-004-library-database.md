# ADR-004 — Base de la bibliothèque : Drift, schéma v1

**Statut :** Active (validée le 2026-10-15) · **Date :** 2026-10-15 · **Ticket :** MPL-018 · **Décisions :** D3, D23 · **Fiches :** FR-003, BR-004 · **Révisé le 2026-10-15 :** table des dossiers choisis

## Contexte

D3 retient SQLite par Drift. D23 impose un modèle relationnel : disques, pistes par (disque, chemin relatif). `CLAUDE.md` fixe les règles : Drift seulement sous `data/db/`, code généré versionné, migrations testées depuis les dumps de schéma.

## Décision

- Port `LibraryRepository` dans `domain/library/ports/` : lire les disques, observer les pistes (flux), appliquer le résultat d'une indexation pour un disque (ajouts, modifications, suppressions) en une transaction. Fake en mémoire dans `test/`.
- Adaptateur Drift dans `data/db/`, base ouverte dans un isolate d'arrière-plan (`NativeDatabase.createInBackground`).
- Schéma v1 :
  - `disks` : `id` (clé interne), `key` (identifiant stable : fixe pour le stockage interne, UUID du système de fichiers pour un disque amovible, BR-004), `label`, `kind` (interne / amovible).
  - `disk_folders` : `disk_id`, `relative_path` du dossier choisi (FR-003.2) ; unicité (`disk_id`, `relative_path`).
  - `tracks` : `id` (clé interne, stable, BR-004.2), `disk_id`, `relative_path`, unicité (`disk_id`, `relative_path`), les informations de FR-003.5, `indexed_at`.
- Le schéma v1 est exporté (`drift_dev schema dump`) dans `drift_schemas/` ; chaque version suivante ajoute son dump et un test de migration.
- Dépendances : `drift` et `sqlite3_flutter_libs` ; `drift_dev` et `build_runner` en développement (D30).
- La CI régénère le code Drift et vérifie qu'il est à jour (`git diff --exit-code`), comme pour la localisation.

## Conséquences

- Les identifiants de volume ne sont stockés que dans la base de l'appareil, jamais dans le dépôt (D27).
- La recherche plein texte (FTS5) pourra s'ajouter par migration ; elle n'est pas dans v1.

## Alternatives examinées

- Lire MediaStore à chaque affichage, sans base : impossible pour le SSD (pas dans MediaStore) et pour les playlists qui mêlent plusieurs disques (D23). Écartée.

## As-built

Néant (non implémenté).
