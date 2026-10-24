# FR-022 — Lire un album ou un artiste, l'ajouter à la file

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Lié :** UC-007, UC-008, FR-017, FR-019, FR-020, FR-021, BR-001, BR-009, BR-010, ADR-015, ADR-016 · **Source :** `docs/design/HANDOFF.md` §5 (8b, 8d), demande du propriétaire (FR-019, hors périmètre)

## Besoin

Lancer un album ou un artiste en entier, dans l'ordre ou mélangé, ou le mettre dans la file sans interrompre la lecture.

## Exigences

1. **Ordre.** Toute file faite à partir d'un album, d'un artiste ou de l'ajout d'un groupe suit l'ordre de BR-010 : pour un album, numéro de disque puis numéro de piste ; pour un artiste, ses albums dans l'ordre de BR-010 règle 7, chacun dans cet ordre (décision du propriétaire du 2026-10-23).
2. **Lire** (détail d'un album) et **Tout lire** (détail d'un artiste) : la file devient les pistes du groupe dans cet ordre ; la lecture démarre sur la première piste ; l'aléatoire est désactivé (BR-009, règle 2).
3. **Aléatoire** : l'aléatoire est activé (BR-009, règle 3) et la file devient les pistes du groupe ; la lecture démarre sur une piste du groupe tirée au hasard, les autres sont mélangées derrière elle. Le mode reste actif ensuite : le bouton du lecteur le montre.
4. **Toucher une piste** d'un détail : la file devient les pistes du groupe, la lecture démarre sur cette piste ; le mode aléatoire reste tel qu'il était (BR-009, règle 3 le met en tête).
5. Les pistes indisponibles restent dans la file et sont sautées (BR-001). Un groupe entièrement indisponible : rien ne démarre, le message de BR-008 règle 5 est dit.
6. **Provenance de la file** (FR-017.2) : « Album · {titre} » ou « Artiste · {nom} » à la place de « Pistes · Titre A→Z ».
7. **Appui long** sur une carte d'album ou une ligne d'artiste : menu « Lire ensuite » et « Ajouter à la file » pour toutes les pistes du groupe, dans l'ordre de BR-010 ; mêmes règles, messages et actions TalkBack que FR-019 (le message nomme l'album ou l'artiste, « {n} pistes » ajoutées).
8. Sur une file vide, « Lire ensuite » et « Ajouter à la file » démarrent la lecture (BR-009, règle 11) ; la provenance est alors celle du groupe.
9. Textes dans les fichiers ARB, en français et en anglais : « Lecture ensuite : {nom} », « Ajouté à la file : {nom} ».

## Hors périmètre

Ajout d'une sélection de plusieurs groupes, « Lire depuis cette piste » sans changer de file, enregistrer en playlist.

## À valider (PO)

- Exigence 2 : « Lire » coupe l'aléatoire ; d'autres lecteurs gardent le mode. Choix : l'utilisateur qui veut mélanger touche « Aléatoire ».
- Exigence 3 : « Aléatoire » démarre sur une piste tirée au hasard (revue QA du 2026-10-23 : démarrer toujours sur la première n'avait pas de sens).
- Exigence 4 : la file est celle du groupe, pas celle de la liste de pistes.
- Exigence 7 : l'appui long sur un artiste ajoute toutes ses pistes, dans l'ordre des albums.

## As-built

MPL-048, 2026-10-23, test appareil partiel (D14). `playGroup`, `playOrExplain`, `explainUnavailable` (`group_actions.dart`), `showTracksMenu` et `applyTracksAction` (`features/player/track_menu.dart`, qui sert aussi aux pistes seules), `QueueOrigin` scellée (`AlbumOrigin`, `ArtistOrigin`). Tests : `browse_views_test.dart`.

- « Lire » éteint l'aléatoire avant de poser la file ; « Aléatoire » l'allume ; toucher une piste laisse le mode.
- Un groupe sans piste disponible n'ouvre pas la file et dit quoi faire ; toucher une piste indisponible du détail l'explique.
- « Aléatoire » tire la piste de départ au hasard (`Random`) ; les autres boutons et toucher une piste démarrent où il est dit.
- Sur une file vide, « Lire ensuite » et « Ajouter à la file » posent la provenance du groupe (`origin`), puis démarrent la lecture ; sur une file qui joue, la provenance ne change pas.
- Les cartes, lignes d'artiste et pistes des détails offrent « Lire ensuite » et « Ajouter à la file » à TalkBack (`menuSemanticsActions`).
- La confirmation de l'ajout nomme l'album ou l'artiste (« Ajouté à la file : … »).
