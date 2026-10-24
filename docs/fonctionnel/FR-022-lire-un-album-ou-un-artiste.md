# FR-022 — Lire un album ou un artiste, l'ajouter à la file

**Statut :** Brouillon · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Lié :** UC-007, UC-008, FR-017, FR-019, FR-020, FR-021, BR-001, BR-009, BR-010, ADR-015, ADR-016 · **Source :** `docs/design/HANDOFF.md` §5 (8b, 8d), demande du propriétaire (FR-019, hors périmètre)

## Besoin

Lancer un album ou un artiste en entier, dans l'ordre ou mélangé, ou le mettre dans la file sans interrompre la lecture.

## Exigences

1. **Lire** (détail d'un album) et **Tout lire** (détail d'un artiste) : la file devient les pistes du groupe dans l'ordre de BR-010 ; la lecture démarre sur la première piste ; l'aléatoire est désactivé (BR-009, règle 2).
2. **Aléatoire** : l'aléatoire est activé (BR-009, règle 3) et la file devient les pistes du groupe, la lecture démarre. Le mode reste actif ensuite : le bouton du lecteur le montre.
3. **Toucher une piste** d'un détail : la file devient les pistes du groupe, la lecture démarre sur cette piste ; le mode aléatoire reste tel qu'il était (BR-009, règle 3 le met en tête).
4. Les pistes indisponibles restent dans la file et sont sautées (BR-001). Un groupe entièrement indisponible : rien ne démarre, le message de BR-008 règle 5 est dit.
5. **Provenance de la file** (FR-017.2) : « Album · {titre} » ou « Artiste · {nom} » à la place de « Pistes · Titre A→Z ».
6. **Appui long** sur une carte d'album ou une ligne d'artiste : menu « Lire ensuite » et « Ajouter à la file » pour toutes les pistes du groupe, dans l'ordre de BR-010 ; mêmes règles, messages et actions TalkBack que FR-019 (le message nomme l'album ou l'artiste, « {n} pistes » ajoutées).
7. Sur une file vide, « Lire ensuite » et « Ajouter à la file » démarrent la lecture (BR-009, règle 11) ; la provenance est alors celle du groupe.
8. Textes dans les fichiers ARB, en français et en anglais : « Lecture ensuite : {nom} », « Ajouté à la file : {nom} ».

## Hors périmètre

Ajout d'une sélection de plusieurs groupes, « Lire depuis cette piste » sans changer de file, enregistrer en playlist.

## À valider (PO)

- Exigence 1 : « Lire » coupe l'aléatoire ; d'autres lecteurs gardent le mode. Choix : l'utilisateur qui veut mélanger touche « Aléatoire ».
- Exigence 3 : la file est celle du groupe, pas celle de la liste de pistes.
- Exigence 6 : l'appui long sur un artiste ajoute toutes ses pistes, dans l'ordre des albums.

## As-built

À écrire à la livraison.
