# UC-005 — Parcourir une longue bibliothèque

**Statut :** Brouillon (2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-045 · **Décisions :** D23 · **Lié :** FR-011, FR-012, FR-013, BR-008, UC-001, UC-003, FR-010

## Acteur et but

L'utilisateur a des milliers de pistes réparties sur son téléphone et sur un ou plusieurs disques. Il veut retrouver une piste vite, savoir d'où elle vient et la lancer.

## Préconditions

- L'accès aux fichiers audio est accordé, au moins un dossier est choisi (FR-004, FR-003).

## Scénario nominal

1. L'utilisateur ouvre l'onglet **Pistes** : le titre, les pastilles Actualiser, Dossiers et Disques, la ligne « 2 600 pistes », puis la liste triée par titre.
2. Chaque ligne montre la pochette, le titre, le **repère de la source** et l'artiste, la durée. Les repères distinguent le téléphone et chaque disque (FR-012).
3. Il fait défiler la liste, qui compte plus de cent pistes : une poignée apparaît au bord. Il la touche et glisse jusqu'à une lettre ; la liste suit en temps réel (FR-013).
4. Il touche une piste : elle se lance, avec toute la liste comme file (UC-001).
5. Il fait défiler loin de la piste en cours : le bouton **En cours** apparaît ; il le touche et la liste revient sur la piste (FR-013).

## Variantes

- 1a. La bibliothèque est vide, ou aucun dossier n'est choisi : un état vide propose de choisir des dossiers (FR-011).
- 1b. Le premier parcours est en cours : des lignes en squelette et un bandeau de progression s'affichent (FR-011).
- 1c. Les étiquettes se lisent encore : un bandeau « Lecture des étiquettes : 340 / 2 600 » se met à jour au-dessus de la liste (FR-011, FR-007).
- 2a. Un disque est absent : ses pistes sont grisées, un bandeau l'annonce avec « Voir » vers l'écran des disques, la liste reste visible dessous (BR-008).
- 4a. L'utilisateur touche une piste grisée : un message explique ce qu'il faut brancher, sans erreur de lecture (BR-008).
- 4b. Un fichier ne se lit pas : sa ligne indique « Fichier illisible » et la piste suivante se lance (BR-003, BR-008).
- 5a. Rien ne joue : le bouton mène à la dernière piste jouée de la session, en plus discret (FR-013).

## Hors périmètre

Recherche, tri autre que par titre, playlists, favoris, modification du repère d'un disque (MPL-046), mini-lecteur et lecteur plein écran (MPL-047), vues Albums et Artistes (MPL-048), côté gauche de l'index (MPL-048).

## As-built

À écrire à la livraison de MPL-045.
