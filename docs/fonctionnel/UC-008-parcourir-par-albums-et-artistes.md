# UC-008 — Parcourir sa musique par albums et par artistes

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Lié :** UC-004, UC-005, UC-007, FR-020, FR-021, FR-022, BR-010, ADR-016 · **Source :** `docs/design/HANDOFF.md` §4, §5 (écran 8, états 8a à 8d)

## Acteur et but

L'utilisateur veut retrouver sa musique autrement que par titre : un album précis, tout ce qu'un artiste a dans la bibliothèque, et lancer l'un ou l'autre en entier.

## Préconditions

- La bibliothèque contient des pistes (UC-001, UC-003).

## Scénario nominal

1. L'utilisateur touche l'onglet **Albums** : une grille de pochettes triée par artiste de l'album, avec l'index alphabétique (FR-020).
2. Il touche un album : le **détail** s'ouvre dans l'onglet, la navigation et le mini-lecteur restent visibles ; les pistes sont groupées par disque (FR-020).
3. Il touche « Lire » : l'album se lit dans l'ordre ; ou une piste : la lecture démarre sur elle, avec l'album pour file (FR-022).
4. Il revient (flèche ou geste Retour) à la grille, au même endroit.
5. Il touche l'onglet **Artistes** : une liste d'artistes avec leur initiale, des intercalaires de lettres et l'index (FR-021).
6. Il touche un artiste : albums en carrousel, puis pistes ; « Tout lire » ou « Aléatoire » (FR-021, FR-022).
7. Un appui long sur un album ou un artiste propose « Lire ensuite » et « Ajouter à la file » pour l'ensemble (FR-022).

## Variantes

- 1a. Un album est réparti sur le téléphone et un disque : une seule carte, jusqu'à trois repères de source (BR-010).
- 1b. Un album dont tous les disques sont absents est grisé avec l'icône de prise (BR-010, BR-008).
- 2a. Une piste du détail est sur un disque absent : grisée, toucher explique (BR-008, règle 5).
- 5a. Les pistes sans étiquettes sont sous « Artiste inconnu » et « Album inconnu » (BR-010).
- 7a. La bibliothèque est vide : un message dit de choisir des dossiers dans l'onglet Pistes.

## Hors périmètre

Recherche, autres tris et filtres, playlists, favoris, image d'artiste, regroupement des compilations sans étiquette d'artiste d'album (limite connue de BR-010), côté gauche de l'index (MPL-051), panneau lecteur permanent (MPL-052), retrait d'un album de la bibliothèque.

## As-built

MPL-048, 2026-10-23, test appareil partiel (D14). `lib/features/browse/` (groupes, vues, détails, actions), tests dans `test/features/browse/`. Vu sur le Pixel (release, thème sombre) : grille de 418 albums, détail d'un album avec navigation et mini-lecteur visibles, « Lire », Retour du détail vers la grille. Non vu : artistes, index, ajout à la file, disque absent, paysage, TalkBack, 200 %, fluidité (HOWTO §18).

- Constaté sur la bibliothèque réelle : les fichiers sans étiquette d'artiste sont regroupés sous « Artiste inconnu » avec le nom de leur dossier pour album (MediaStore), d'où de nombreux albums d'une piste en tête de grille.
