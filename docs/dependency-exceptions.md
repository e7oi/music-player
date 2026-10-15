# Dérogations de dépendances

Dépendances retenues en retard sur l'amont, ou en fin de vie (D30, `CLAUDE.md`). Chaque ligne a une date de revue à 90 jours au plus.

| Paquet | Version retenue | Dernière version | Blocage | Inscrite le | Revue au plus tard | Ticket |
|---|---|---|---|---|---|---|
| `build_runner` (développement) | 2.16.2 | 2.17.1 | 2.17 exige `build` 5 ; `drift_dev` 2.35.1 ne l'accepte pas encore | 2026-10-15 | 2027-01-13 | MPL-018 |
| `sqlite3_flutter_libs` (transitive, par `drift_flutter` 0.3.1) | 0.6.0+eol | 0.6.0+eol (paquet en fin de vie) | `drift_flutter` 0.3.1 en dépend encore ; SQLite est fourni par les *build hooks* de `sqlite3` 3.7.1 | 2026-10-15 | 2027-01-13 | MPL-018 |
