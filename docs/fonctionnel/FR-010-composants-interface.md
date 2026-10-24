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

MPL-016, 2026-10-23. `lib/ui/widgets/` : `source_mark`, `artwork_tile`, `track_tile`, `status_banner`, `progress_banner`, `disk_card`, `jump_to_current_fab`, `alphabet_scroller`, `alphabet_index` (regroupement des lettres, effet loupe, lettre sous le doigt) ; `lib/ui/demo/` (galerie et liste de 5 000 lignes) ; canal natif `GestureExclusionChannel.kt` et `lib/platform/gesture_exclusion_channel.dart`. Tests : `test/ui/widgets/`, `test/platform/gesture_exclusion_channel_test.dart`.

- Écart : la poignée de l'index a la zone tactile de Design (32 × 64 dp), plus étroite que les 48 dp de l'exigence 6 ; la grille « Aller à la lettre » et les gestes d'ajustement de TalkBack sont les alternatives.
- L'effet loupe suit une courbe ajustée sur les valeurs de Design (26 / 18 / 14 / 11 dp) : un sommet arrondi, sans palier. La bulle est décalée de la largeur de la colonne et du déplacement maximal des lettres, pour ne pas les recouvrir (corrigé après le test sur le Pixel).
- La valeur d'accessibilité de la poignée est le nombre d'éléments tant qu'aucune lettre n'est choisie (Flutter exige une valeur dès que l'action « augmenter » existe).
- `StatusBanner` remplace la bannière d'échec d'indexation de la bibliothèque, et `ProgressBanner` la progression des tags (FR-010.8). Les lignes réelles de la liste ne passent pas encore par `TrackTile` (MPL-045).
- `TrackTile` : le libellé `Semantics` par défaut ajoute l'état en mots (`playingLabel`, `unavailableLabel`, `unreadableLabel`) ; la hauteur est fixe à 64 dp jusqu'à 1,3 fois la taille du texte (`TsSize.fixedRowMaxTextScale`), minimale au-delà, sans débordement à 200 % (test).
- `StatusBanner` refuse un bouton de fermeture sans libellé (assertion). `ProgressBanner` n'est pas limité par lui-même : `tagProgressProvider` limite les mises à jour à quatre par seconde (`app/providers/throttle.dart`, testé), la fin de lecture passe toujours.
- Le rectangle de la poignée est rapporté à chaque changement de contrainte (rotation, bandeau), et `null` quand la poignée disparaît. Le dernier rapport écrit remplace tout : plusieurs index vivants à la fois (onglets Pistes, Albums, Artistes dans un `IndexedStack`) devront fusionner leurs rectangles (MPL-045, MPL-048).
- Écarts avec `HANDOFF.md` §6.1, non faits : la colonne apparaît et disparaît sans fondu de 150 ms ; la bulle est un cercle, pas une goutte pointant vers le doigt ; les lettres de la colonne suivent l'échelle de texte du système.
- `JumpToCurrentFab` : le libellé `Semantics` ne dit pas la direction (portée par l'icône).
- Les textes de la galerie sont des exemples fictifs, non traduits (page absente de la release).
- Testé sur le Pixel 10 Pro le 2026-10-23 (build profile, par adb) : galerie en clair (lignes, repères, cartes de disque, bandeaux, progressions, pochettes) conforme aux captures ; liste de 5 000 lignes : poignée, colonne avec effet loupe, bulle, saut en temps réel, disparition de la colonne après le lâcher, grille de lettres (Q, X, Y grisés) ; glissé horizontal depuis la poignée sans Retour, depuis le bord ailleurs avec Retour. **Non testé** : galerie en sombre, vibration, TalkBack, côté gauche, fluidité (`gfxinfo` ne compte pas les images de Flutter).
- MPL-047, 2026-10-23 : `MiniPlayer` et `MiniPlayerProgress` (`lib/ui/widgets/mini_player.dart`) et `ToggleIconButton` sont ajoutés (FR-016, FR-017). `ArtworkTile` gagne `fade` (opacité autre que celle de l'indisponibilité) ; `JumpToCurrentFab` gagne `showArrow`. Tests : `mini_player_test.dart`, `jump_to_current_fab_test.dart`.
- MPL-048, 2026-10-23 : `AlbumCard`, `ArtistTile` et `ArtistAvatar` sont ajoutés (`lib/ui/widgets/`, FR-020, FR-021). Tests : `album_card_test.dart`.
