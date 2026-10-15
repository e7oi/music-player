# FR-001 — Commandes de lecture d'une file de pistes

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D2, D23

## Besoin

L'application lit une file de pistes avec un seul moteur (`media_kit`, D2), sans que la logique de lecture dépende de ce moteur. Le `PlayerController` porte cette logique ; l'interface (MPL-016) et la notification ne font que l'appeler.

## Exigences

1. Le contrôleur reçoit une file ordonnée de pistes et un index de départ. Une piste est identifiée par (disque, chemin relatif) (D23).
2. Commandes : lire, mettre en pause, se positionner (seek), piste suivante, piste précédente, arrêter.
3. « Piste précédente » : si la position dépasse 3 s, la piste courante reprend au début ; sinon le contrôleur passe à la piste disponible précédente (validé par le propriétaire le 2026-10-15).
4. « Lecture » désigne l'intention de lire : elle reste vraie d'une piste à l'autre, y compris pendant le chargement de la suivante.
5. À la fin d'une piste, le contrôleur passe à la suivante disponible (BR-001). À la fin de la file, la lecture s'arrête ; la file est conservée.
6. Le contrôleur expose un état observable : piste courante et son index, intention de lecture, position, durée (connue ou non), état (inactif, chargement, prêt, arrêté).
7. Les problèmes du moteur sont traités selon BR-003 ; l'éjection d'un disque selon BR-002.

## Hors périmètre

Lecture aléatoire, répétition, gapless, fondu enchaîné, persistance de la file après redémarrage, notification et lecture en arrière-plan (`audio_service`, MPL-036), interface.

## As-built

Néant (non implémenté).
