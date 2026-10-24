# FR-021 — Vue Artistes et détail d'un artiste

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Lié :** UC-008, FR-009, FR-010, FR-013, FR-020, FR-022, BR-007, BR-008, BR-010, ADR-016 · **Source :** `docs/design/HANDOFF.md` §5 (écran 8, 8c et 8d), `Artistes.dc.html`

## Besoin

Retrouver un artiste et tout ce que la bibliothèque contient de lui, regroupé par artiste de l'album (BR-010).

## Exigences

### Liste (8c)

1. **En-tête.** Titre « Artistes » ; ligne « {n} artistes · regroupés par artiste de l'album ».
2. **Lignes** de 64 dp : avatar rond de 48 dp avec l'initiale du nom (« ? » pour « Artiste inconnu »), nom, puis « {n} albums · {n} pistes » (« {n} pistes sans étiquette » pour l'artiste inconnu). Les avatars alternent deux teintes (`primaryContainer`, `secondaryContainer`) ; aucune image d'artiste.
3. **Intercalaires** de lettres (« # », « A », « C »…) ; « Artiste inconnu » est sous « # » (BR-010, règle 7).
4. **Index alphabétique** à droite, comme FR-020.6 : saut à l'intercalaire, retour haptique, grille « Aller à la lettre ».
5. **Indisponible** (BR-010, règle 9) : avatar et textes grisés, « {n} albums · {n} pistes · {disque} non connecté ». Toucher ouvre le détail.
6. **États.** Chargement ; bibliothèque vide : « Aucun artiste » et « Choisis des dossiers dans l'onglet Pistes. ».

### Détail (8d)

7. **Ouverture** dans l'onglet, comme FR-020.8.
8. **En-tête.** Avatar de 96 dp, nom, « {n} albums · {n} pistes · {durée} » (durée en « 2 h 04 »), boutons « Tout lire » et « Aléatoire » (FR-022).
9. **Albums** : section « Albums », carrousel horizontal de cartes (pochette, titre, année) ; toucher une carte ouvre le détail de l'album (FR-020), avec retour vers l'artiste.
10. **Pistes** : section « Pistes », toutes les pistes de l'artiste dans l'ordre des albums (BR-010, règles 6 et 7), chaque ligne avec pochette, titre, nom de l'album et durée, repère de source, état en cours / indisponible comme `TrackTile`. Toucher une ligne lit les pistes de l'artiste en commençant par elle (FR-022).
11. **Accessibilité** : « {nom}, {n} albums · {n} pistes » ; boutons de 48 dp ; texte à 200 % sans coupure.
12. **Règles d'interface et textes** : comme FR-020.13 et FR-020.14 (« Artistes », « {n} artistes · regroupés par artiste de l'album », « Tout lire », « Aléatoire », « Albums », « Pistes »), avec la version anglaise.

## Hors périmètre

Image d'artiste, biographie, « artistes similaires », pistes où l'artiste n'apparaît qu'en « feat. » (BR-010, règle 5), recherche.

## À valider (PO)

- Exigence 10 : l'ordre des pistes d'un artiste est celui de ses albums, pas l'ordre alphabétique des titres de la maquette.
- Exigence 2 : l'alternance des teintes d'avatar suit la maquette ; elle est décorative.
- Exigence 6 : textes de l'état vide de moi.

## As-built

À écrire à la livraison.
