# FR-018 — File d'attente

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** UC-007, FR-001, FR-002, FR-012, FR-017, FR-019, BR-001, BR-007, BR-009, ADR-015 · **Source :** `docs/design/HANDOFF.md` §5 (état 5c), `Lecteur.dc.html`

## Besoin

Voir ce qui va être joué, le réordonner, et vider la suite, sans quitter le lecteur. La file d'une écoute lancée depuis la liste contient toute la bibliothèque (UC-001) : jusqu'à plusieurs milliers de lignes.

## Exigences

1. **Feuille.** Le bouton « À suivre » du lecteur (FR-017.8) ouvre une feuille modale qui se règle en hauteur ; on la ferme en la glissant vers le bas ou par le geste Retour.
2. **En-tête.** « File d'attente » ; « {n} pistes · {durée} · aléatoire » avec n = toute la file, durée = somme des durées connues, « aléatoire » seulement si le mode est actif ; bouton « Vider la suite », désactivé quand il n'y a pas de suite.
3. **Piste en cours.** Une section « En cours » avec la piste courante, surlignée comme dans la liste. La toucher ne fait rien.
4. **Suite.** Une section « À suivre » avec les pistes après la courante, dans l'ordre où elles seront jouées. Les pistes déjà passées ne sont pas listées. Chaque ligne fait 64 dp : repère de source, titre, artiste, durée, poignée de déplacement.
5. **Réordonner.** Glisser la poignée déplace la piste dans la suite (BR-009, règle 6). TalkBack offre « Monter » et « Descendre » ; la poignée a le libellé « Déplacer {titre} ». Seule la suite se déplace.
6. **Lire une piste.** Toucher une ligne de la suite la lit (BR-009, règle 8) ; la feuille reste ouverte.
7. **Piste indisponible.** Ligne grisée, icône de prise débranchée, deuxième ligne « {artiste} · non connecté, sera ignorée » ; le repère garde sa couleur (BR-001, FR-012).
8. **Retirer une piste.** Glisser une ligne de la suite sur le côté la retire de la file (FR-002, BR-009, règle 9) ; la piste reste dans la bibliothèque. Pour TalkBack, la ligne a l'action « Retirer de la file ». Une `SnackBar` brève dit « {titre} retirée de la file ». La piste en cours n'est pas retirable ici.
9. **Vider la suite.** Retire toutes les pistes après la courante (BR-009, règle 7) ; la lecture continue ; la feuille montre alors une suite vide. Sans confirmation.
10. **Fluidité.** La liste est construite à la demande : une file de 7 500 pistes s'ouvre sans attente visible et défile sans à-coups. Les mises à jour de position ne la redessinent pas.
11. **Suivi.** Quand la piste change, que le mode aléatoire change ou qu'une piste est déplacée, la feuille se met à jour sans se fermer.
12. **Règles d'interface.** Jetons seulement, clair et sombre, texte à 200 % sans rien couper, animations réduites respectées (BR-007).
13. **Textes.** Dans les fichiers ARB, en français mot pour mot des maquettes (« File d'attente », « {n} pistes · {durée} · aléatoire », « Vider la suite », « En cours », « À suivre », « Déplacer {titre} », « non connecté, sera ignorée »), plus « Retirer de la file » et « {titre} retirée de la file » (de moi), avec la version anglaise.

## Hors périmètre

Ajouter des pistes à la file (FR-019), annuler un retrait, enregistrer la file comme playlist, annuler « Vider la suite », retirer plusieurs pistes à la fois, liste des pistes déjà jouées.

## À valider (PO)

- Exigence 6 : toucher une ligne la lit ; la conception ne le dit pas.
- Exigence 9 : « Vider la suite » sans confirmation ni annulation ; exigence 8 : le retrait non plus n'a pas d'annulation ; la file se refait en relançant une piste depuis la liste.
- Exigence 4 : les pistes passées sont masquées ; « précédent » les atteint toujours.
- Exigence 2 : la durée totale est la somme des durées connues ; elle est basse tant que les étiquettes d'un disque ne sont pas toutes lues.

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). `showQueueSheet` et `QueueSheet` (`lib/features/player/queue_sheet.dart`), `QueueModel` (`queue_model.dart`, lignes construites à la demande, durée totale calculée une fois par état). Tests : `test/features/player/queue_model_test.dart`, `queue_sheet_test.dart`.

- Feuille modale avec `DraggableScrollableSheet` ; la suite est une `SliverReorderableList` (poignée `ReorderableDragStartListener`) ; chaque ligne est un `Dismissible` (sans animation de repli) dont la clé est l'identifiant d'entrée du lecteur (`PlayerState.entryIds`), stable quand la file change.
- TalkBack : la liste réordonnable de Flutter ajoute « Monter », « Descendre », « Au début », « À la fin » ; « Retirer de la file » est une action personnalisée de la ligne.
- L'en-tête (titre, résumé, « Vider la suite ») passe à la ligne aux grands textes.
- Le test de glissé vérifie que la piste monte, pas sa place exacte.
- Le message de retrait est affiché dans la feuille : elle a son propre `ScaffoldMessenger` et `Scaffold`, sans quoi le `SnackBar` de la page derrière restait caché sous elle (vu sur le Pixel, 2026-10-23).
