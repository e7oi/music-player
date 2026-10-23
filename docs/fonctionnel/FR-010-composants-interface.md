# FR-010 — Composants d'interface réutilisables

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-016 · **Lié :** FR-008, FR-009, BR-007, ADR-010 · **Source :** `docs/design/HANDOFF.md` §4, §6, §6.1

## Besoin

Les éléments d'interface que plusieurs écrans partagent existent une fois, dans tous leurs états, avant que les écrans ne les utilisent.

## Exigences

1. **Composants livrés** : `ArtworkTile`, `SourceMark`, `TrackTile`, `StatusBanner`, `ProgressBanner`, `DiskCard`, `JumpToCurrentFab`, `AlphabetScroller`. `MiniPlayer` (MPL-047) et `ActionChip` avec `Badge` (MPL-045) viennent avec leurs lots.
2. **Indépendance** : un composant reçoit des valeurs simples et des fonctions de rappel ; il n'importe ni le domaine, ni Riverpod, ni la base. Ses textes lui sont passés ou viennent des fichiers ARB.
3. **États** :
   - `TrackTile` : normal, en lecture, sans pochette, indisponible, illisible, en chargement (hauteur fixe de 64 dp) ;
   - `DiskCard` : connecté, parcours en cours, absent, accès à renouveler ;
   - `StatusBanner` : erreur, avertissement, information, avec action et fermeture ;
   - `ProgressBanner` : déterminé ou indéterminé, mises à jour au plus 4 fois par seconde ;
   - `ArtworkTile` : tailles 48, 96, 152 et 348 dp, tuile neutre sans pochette, opacité de 35 % si indisponible ;
   - `SourceMark` : cercle, carré, losange, triangle, hexagone, plus une variante contour au-delà de quatre disques ; 12 dp, 24 dp en légende ;
   - `JumpToCurrentFab` : piste en cours au-dessus ou au-dessous, « dernière jouée » à l'arrêt, replié en icône pendant un défilement rapide ;
   - `AlphabetScroller` : au repos (poignée), en glissé (colonne avec effet loupe et bulle), grille de lettres.
4. **Index alphabétique** (`HANDOFF.md` §6.1) : poignée visible seulement si la liste dépasse environ 100 éléments ; activation uniquement par un appui sur la poignée suivi d'un glissé, jamais par le défilement normal ; la liste suit le doigt en temps réel ; retour haptique léger à chaque changement de lettre ; « # » regroupe chiffres et symboles ; accents et casse repliés ; lettres sans élément grisées et sautées ; toucher la poignée sans glisser ouvre une grille « Aller à la lettre » ; côté gauche si le réglage (MPL-048) est actif.
5. **Gestes système** : seule la poignée est exclue du geste Retour d'Android (zone d'exclusion déclarée par un canal natif sous `platform/`, ADR-010).
6. **Accessibilité** : zone tactile d'au moins 48 dp ; libellé `Semantics` pour chaque bouton-icône et chaque ligne (par exemple « …, source SSD ») ; l'index se règle par les gestes d'ajustement de TalkBack ; un état n'est jamais porté par la couleur seule (BR-007).
7. **Page de démonstration** : une page montre chaque composant dans chaque état, en clair et en sombre, avec une liste factice de 5 000 éléments pour l'index ; elle n'existe que dans les builds debug et profile (ADR-010).
8. **Pas de branchement aux données** dans ce ticket : les composants ne remplacent pas encore les lignes des écrans (MPL-045 à MPL-048), sauf `StatusBanner`, qui remplace la bannière d'échec d'indexation de la bibliothèque (BR-007, règle 2).

## Hors périmètre

Repère de source enregistré en base (`markIndex`, MPL-045 et MPL-046), tri et regroupement réels des albums et artistes, panneau lecteur.

## À valider (PO)

- Exigence 5 : le canal natif d'exclusion de geste est du Kotlin sans test unitaire (exception de `CLAUDE.md`), vérifié par la procédure du `HOWTO.md`.
- Exigence 7 : la page de démonstration n'est pas dans la build release ; le propriétaire la valide en profile sur le Pixel.

## As-built

À écrire à la livraison de MPL-016.
