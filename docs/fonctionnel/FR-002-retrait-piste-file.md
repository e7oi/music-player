# FR-002 — Retirer une piste de la file de lecture

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-017 · **Lié :** FR-001, BR-001

## Besoin

L'utilisateur retire une piste de la file de lecture en cours, sans toucher à la bibliothèque : la piste reste dans la bibliothèque et dans les playlists.

## Exigences

1. Le contrôleur retire de la file la piste désignée par sa position. Les positions suivantes sont décalées ; la piste courante reste la même.
2. Retrait de la piste courante pendant la lecture : le contrôleur passe à la piste disponible suivante (BR-001), comme en fin de piste, et la lecture continue.
3. Retrait de la piste courante en pause : la piste disponible suivante est chargée, en pause.
4. Retrait de la dernière piste de la file alors qu'elle est la piste courante : la lecture s'arrête, comme en fin de file.
5. Retrait de la seule piste de la file : le moteur est arrêté et la file est vide (état inactif).
6. Une position hors de la file est refusée sans changement d'état.
7. Retrait de la piste courante quand la lecture est arrêtée (fin de file, éjection, arrêt) : la piste suivante devient la piste courante, rien n'est chargé et la lecture reste arrêtée (validé par le propriétaire le 2026-10-15).

## Hors périmètre

Retrait de plusieurs pistes en une fois, déplacement d'une piste dans la file, annulation du retrait, interface.

## As-built

MPL-017, 2026-10-15. `PlayerController.removeAt(index)`, qui renvoie `false` pour une position hors de la file ; tests : groupe « FR-002 » de `test/domain/playback/player_controller_test.dart`.

- Exigence 7 : implémentée sans chargement.
