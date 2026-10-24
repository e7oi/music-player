# FR-020 — Vue Albums et détail d'un album

**Statut :** Brouillon · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Lié :** UC-008, FR-009, FR-010, FR-012, FR-013, FR-022, BR-007, BR-008, BR-010, ADR-016 · **Source :** `docs/design/HANDOFF.md` §5 (écran 8, 8a et 8b), `Albums.dc.html`

## Besoin

Parcourir la bibliothèque par albums, sous forme de pochettes, et voir un album piste par piste.

## Exigences

### Grille (8a)

1. **En-tête.** Titre « Albums » ; ligne « {n} albums » et, à droite, le libellé de tri « Artiste de l'album » (non interactif, comme FR-011.5).
2. **Grille.** Cartes de pochette carrée (rayon 16), titre en une ligne, puis « {artiste} · {année} » (sans année : « {artiste} »). Deux colonnes en portrait ; plus de colonnes quand la largeur le permet (une carte d'au moins 160 dp, jusqu'à six colonnes).
3. **Repères.** Les repères de source de l'album (BR-010, règle 4) sont avant l'artiste, jusqu'à trois côte à côte.
4. **Sans pochette** : tuile neutre avec une note (FR-010). **Album inconnu** : sous-titre « Artiste inconnu · {n} pistes » comme la maquette.
5. **Indisponible** (BR-010, règle 9) : pochette à 35 %, titre et sous-titre grisés, icône de prise, et libellé TalkBack « …, indisponible : {disque} non connecté ». Toucher ouvre quand même le détail.
6. **Index alphabétique** (`AlphabetScroller`, FR-013.1) sur l'artiste de l'album ; la poignée n'existe que si la grille dépasse environ 100 albums ; son rectangle est exclu du geste Retour (ADR-016).
7. **États.** Chargement (indicateur) tant que la bibliothèque n'est pas lue ; bibliothèque vide : « Aucun album » et « Choisis des dossiers dans l'onglet Pistes. » (voir À valider).

### Détail (8b)

8. **Ouverture.** Toucher une carte ouvre le détail dans l'onglet : la barre de navigation et le mini-lecteur restent. Retour par la flèche de l'en-tête ou le geste Retour ; la grille retrouve sa position.
9. **En-tête.** Pochette de 152 dp, titre, artiste de l'album (`primary`), « {année} · {genre} » puis « {n} disques · {n} pistes · {durée} » (disques seulement s'il y en a plusieurs ; genre le plus fréquent). Boutons « Lire » et « Aléatoire » (FR-022).
10. **Pistes.** Groupées sous « Disque 1 », « Disque 2 »… quand l'album compte plusieurs disques, sans intercalaire sinon. Chaque ligne : numéro (▶ pour la piste en cours, sinon le numéro de piste, ou la position si absent), titre, repère de source si l'album a plusieurs sources, durée. Ligne en cours surlignée (`nowPlayingRow`).
11. **Toucher une piste** lit l'album en commençant par elle (FR-022). Une piste indisponible est grisée ; la toucher explique (BR-008, règle 5).
12. **Accessibilité.** Libellés de carte « {titre}, {artiste · année} » ; ligne « Piste 3, {titre}, 4:18, en lecture » ; boutons de 48 dp ; texte à 200 % sans coupure (les lignes grandissent).
13. **Règles d'interface.** Jetons seulement, clair et sombre, animations réduites respectées (BR-007) ; pochettes en miniatures décodées à la taille d'affichage.
14. **Textes.** Dans les fichiers ARB, en français mot pour mot des maquettes (« Albums », « {n} albums », « Artiste de l'album », « Lire », « Aléatoire », « Disque {n} », « {n} disques · {n} pistes · {durée} »), avec la version anglaise.

## Hors périmètre

Recherche, autre tri, filtre, modification des étiquettes, pochette d'album choisie à la main, retrait d'un album, partage.

## À valider (PO)

- Exigence 2 : nombre de colonnes selon la largeur (la conception ne montre que deux colonnes).
- Exigence 7 : textes de l'état vide, absents de la conception.
- Exigence 9 : « {année} · {genre} » omet ce qui manque ; l'en-tête ne montre « disques » qu'au-delà d'un disque.
- Exigence 10 : pas d'intercalaire « Disque 1 » pour un album d'un seul disque (la maquette n'en montre qu'avec deux).
- Détail dans l'onglet (et non en plein écran) : choix de ADR-016.

## As-built

À écrire à la livraison.
