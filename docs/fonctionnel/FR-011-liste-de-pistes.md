# FR-011 — Liste de pistes de la bibliothèque

**Statut :** Brouillon (2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-045 · **Décisions :** D23 · **Lié :** UC-005, FR-003, FR-007, FR-010, FR-012, FR-013, BR-007, BR-008 · **Source :** `docs/design/HANDOFF.md` §5 (écran 3 et états 6a à 6d), `Bibliotheque.dc.html` · **Remplace dans l'interface :** l'écran temporaire de MPL-018 (UC-001)

## Besoin

L'onglet Pistes montre la bibliothèque comme la conception le décrit, fluide pour plus de 5 000 pistes, sans que rien ne recouvre la liste.

## Exigences

1. **En-tête.** Titre « Pistes ». Un bouton Rechercher, désactivé, avec l'infobulle « Rechercher (bientôt) » : l'emplacement existe, la recherche non. Pas de menu « plus d'options » (la conception ne dit pas ce qu'il contient).
2. **Pastilles d'action** sous l'en-tête : **Actualiser** (réindexe, FR-003.7), **Dossiers** (choix des dossiers, FR-003.4), **Disques** (écran des disques, UC-003). Elles remplacent les trois icônes de la barre d'application. La pastille Disques porte un badge ambre « N absent » quand un disque est absent ou à accès perdu. Zone tactile de 48 dp, pastille visible de 36 dp.
3. **Ordre dans le flux**, du haut vers le bas, rien par-dessus (BR-007, règle 2) : en-tête, pastilles, bandeau de progression, bandeau d'état (BR-008), ligne de compte et de tri, liste.
4. **Progression.** Pendant la lecture des tags (FR-007) : « Lecture des étiquettes : 340 / 2 600 », barre déterminée, mise à jour au plus quatre fois par seconde. Pendant le premier parcours, bibliothèque encore vide : « Recherche des fichiers audio… », barre indéterminée, lignes en squelette et ligne de compte « Recherche en cours… ».
5. **Ligne de compte** : « 2 600 pistes · 12 indisponibles », nombres écrits selon la langue ; la partie « indisponibles » n'apparaît que s'il y en a. À côté, le libellé du tri « Titre A→Z », non interactif : il n'y a qu'un tri.
6. **Lignes** : `TrackTile` de 64 dp (FR-010) avec la pochette (miniature, FR-007.6), le titre (nom de fichier s'il manque, FR-003.5), le repère de la source avant l'artiste (FR-012), l'artiste (« Artiste inconnu » s'il manque, à l'affichage seulement), la durée. États :
   - **en lecture** : la piste en cours, ligne teintée et égaliseur ;
   - **sans pochette** : tuile neutre ;
   - **indisponible** : source absente ou à accès perdu, ligne grisée, icône de prise débranchée, sous-titre « Artiste · non connecté » ;
   - **illisible** : le moteur a échoué sur cette piste pendant la session (BR-003) ; sous-titre « Fichier illisible » en couleur d'erreur. Une piste dont seule la lecture des tags a échoué (WMA, FR-007.5) reste une ligne normale ;
   - **chargement** : squelette.
7. **Tri.** Par titre affiché, sans tenir compte de la casse ni des accents : « Écris-moi » se range parmi les E. Les titres qui commencent par un chiffre ou un symbole viennent d'abord, comme le groupe « # » de l'index (FR-013). À titre égal, par chemin puis identifiant, pour un ordre stable.
8. **Toucher une ligne** disponible : la piste se lance, la file est toute la liste affichée dans son ordre (UC-001, FR-001). Une ligne indisponible reste touchable : un message explique quoi brancher ou renouveler, rien ne se lance (BR-008).
9. **États vides.** Bibliothèque vide : « Ta bibliothèque est vide », « Aucun fichier audio dans le dossier choisi (Music). Ajoute d'autres dossiers ou actualise. », boutons « Choisir des dossiers » et « Actualiser ». Aucun dossier choisi : « Aucun dossier choisi », « Choisis au moins un dossier pour que TuneShell trouve ta musique. », bouton « Choisir des dossiers ».
10. **Hauteur des lignes** fixe de 64 dp tant que l'échelle du texte ne dépasse pas 1,3, variable au-delà (BR-007, règle 9). La liste défile à 60 images par seconde pour plus de 5 000 pistes (profile, Pixel).
11. **Mises à jour** : pendant la lecture des tags, la base émet par lots ; la liste ne se reconstruit pas plus de deux fois par seconde.
12. **TalkBack** : chaque ligne lit « titre, artiste, durée, état, source SSD » (FR-010.6, FR-012.5).
13. Textes en français mot pour mot des maquettes et en anglais, dans les fichiers ARB (BR-007, règle 8). Thème clair et sombre, portrait et paysage.

## Hors périmètre

Recherche, autres tris, filtres, playlists, favoris, menu « plus d'options », action « Détails » du message de lecture illisible, modification des dossiers et des disques eux-mêmes (MPL-044, MPL-046).

## À valider (PO)

- Exigence 1 : pas de menu « plus d'options » tant que la conception n'en définit pas le contenu.
- Exigence 4 : « N trouvés » de la maquette n'est pas affiché : le parcours rend sa liste d'un coup, sans compteur en cours de route.
- Exigence 5 : « Titre A→Z » est un libellé, pas un contrôle.
- Exigence 6 : « illisible » ne vaut que pour la session (pas de mémoire entre deux lancements) ; « Artiste inconnu » remplace un artiste absent à l'affichage ; le message d'un échec de lecture garde sa forme actuelle de barre de message, sans bouton « Détails ».
- Exigence 7 : le tri actuel place les titres accentués après le Z ; il change pour le tri sans accents (la bibliothèque s'affiche dans un autre ordre).
- Exigence 11 : limite de deux reconstructions par seconde, à ajuster à la mesure.

## As-built

À écrire à la livraison de MPL-045.
