# BR-008 — Disponibilité des sources et messages de la liste

**Statut :** Brouillon (2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-045 · **Décisions :** D23 · **Lié :** BR-001, BR-003, BR-004, BR-007, FR-011, FR-006 · **Source :** `docs/design/HANDOFF.md` §5 (états 6c et 6d)

## Règles

1. **Disponibilité.** Une piste est disponible si sa source l'est. Le stockage interne l'est toujours ; un disque amovible l'est quand il est monté et que son accès est valable (FR-006.10, FR-006.11). Une piste indisponible reste dans la liste, grisée, jamais retirée (BR-004, règle 5).
2. **Bandeau d'état.** Quand au moins une piste est indisponible, un bandeau d'avertissement s'affiche dans le flux, au-dessus de la liste : « 12 pistes ignorées : T7 Shield absent ». Avec plusieurs disques absents : « 12 pistes ignorées : 2 disques absents ». Pour un accès à renouveler : « 12 pistes ignorées : accès à T7 Shield à renouveler ». Il porte « Voir », qui ouvre l'écran des disques, et un bouton pour le masquer.
3. **Masquer** le bandeau le cache jusqu'au prochain changement d'état des sources : un disque qui part, revient, ou dont l'état change. Le bandeau disparaît de lui-même quand plus aucune piste n'est indisponible.
4. **Pas de bandeau** pendant le premier parcours, tant que la bibliothèque est vide.
5. **Toucher une piste indisponible** ne lance rien et ne signale pas d'erreur : un message dit ce qu'il faut faire, « Branche T7 Shield pour lire cette piste » ou « Renouvelle l'accès à T7 Shield pour lire cette piste ».
6. **Lecture qui saute** (BR-001) : le message de lecture existant « N piste(s) ignorée(s) : disque absent » reste, comme message court. Le bandeau dit l'état, le message dit ce que la lecture vient de faire.
7. **Fichier illisible** (BR-003) : la ligne passe en « Fichier illisible » pour la session ; le message court dit « Impossible de lire « Bastion » : fichier endommagé. Piste suivante lancée. ».
8. Aucun de ces états ne tient à la couleur seule : icône de prise débranchée ou d'erreur, plus du texte (BR-007, règle 3).

## À valider (PO)

- Règle 2 : les formulations pour plusieurs disques et pour l'accès à renouveler sont de moi ; la maquette ne montre qu'un SSD absent.
- Règle 6 : le message court de BR-001 est gardé en plus du bandeau.
- Règle 7 : le bouton « Détails » de la maquette n'est pas construit : la conception ne dit pas ce qu'il ouvre.

## As-built

À écrire à la livraison de MPL-045.
