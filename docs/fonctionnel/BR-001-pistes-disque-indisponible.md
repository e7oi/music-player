# BR-001 — Pistes d'un disque indisponible pendant la lecture

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D23

## Règle

Quand le contrôleur doit charger une piste (démarrage, piste suivante, fin de piste, piste précédente) et que le disque de cette piste est indisponible, il ne la charge pas : il passe à la piste disponible suivante dans le sens du déplacement. Les pistes sautées restent dans la file.

Chaque série de pistes sautées d'affilée produit un seul signalement typé : nombre de pistes ignorées dans cette série et disque(s) concerné(s). Une nouvelle série produit un nouveau signalement ; il n'y a pas de cumul sur la session (validé par le propriétaire le 2026-10-15). Le texte affiché (du type « 12 pistes ignorées : SSD absent », D23) relève de l'interface et des fichiers ARB, pas du contrôleur.

## Cas limites

- Aucune piste disponible jusqu'au bout de la file dans le sens du déplacement : la lecture s'arrête, avec le signalement des pistes ignorées.
- File entièrement indisponible au démarrage : rien n'est chargé, la lecture reste arrêtée, avec le signalement.
- Le moteur n'est jamais appelé pour une piste dont le disque est indisponible.

## As-built

Néant (non implémenté).
