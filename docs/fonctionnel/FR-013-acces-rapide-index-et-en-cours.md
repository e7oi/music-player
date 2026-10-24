# FR-013 — Accès rapide : index alphabétique et bouton « En cours »

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-045 · **Lié :** UC-005, FR-010, FR-011, BR-007, ADR-013 · **Source :** `docs/design/HANDOFF.md` §5 (écran 3, états 3c et 3d), §6, §6.1

## Besoin

Dans une liste de milliers de pistes, aller à une lettre ou revenir à la piste qui joue sans faire défiler à la main. Les idées viennent du propriétaire (MPL-042 et MPL-043).

## Exigences

1. **Index alphabétique.** L'`AlphabetScroller` (FR-010.4) entoure la liste de pistes. Ses lettres viennent des titres affichés ; un glissé jusqu'à une lettre place la liste sur le premier titre de ce groupe, en temps réel (`jumpTo`, sans animation). La poignée n'existe que si la liste compte plus de 100 pistes. Elle est à droite ; le côté gauche est un réglage (MPL-048).
2. **Geste Retour.** La poignée est exclue du geste Retour d'Android par le canal natif (ADR-010) : le rectangle de la poignée, converti en pixels physiques, est envoyé à chaque changement et retiré quand la poignée disparaît ou que la vue Pistes n'est plus au premier plan.
3. **Bouton « En cours »** (`JumpToCurrentFab`). Il apparaît quand la piste en cours existe dans la liste affichée et que sa ligne est hors de l'écran ; la flèche indique le sens (vers le haut ou vers le bas) ; il disparaît quand la ligne est visible. Il se replie en icône pendant que la liste défile et se déplie un court instant après l'arrêt.
4. **Dernière jouée.** Quand rien ne joue, le bouton mène à la dernière piste jouée de la session, en variante discrète « Dernière jouée ».
5. **Toucher le bouton** fait défiler la liste jusqu'à centrer la ligne, puis la met brièvement en évidence. Si la piste n'est pas dans la liste affichée, le bouton n'est pas montré.
6. **Place.** Le bouton est en bas à droite de la zone de liste, à 16 dp du bas, au-dessus de la barre de lecture. La liste garde un espace de 88 dp en bas pour que sa dernière ligne reste atteignable (`TsSize.listBottomInset`).
7. Textes en français et en anglais dans les fichiers ARB : « En cours », « Dernière jouée », « Aller à la lettre », « {n} pistes », « Lettre {x}, {n} pistes ».

## Hors périmètre

Mémoire de la dernière piste jouée entre deux lancements (« Reprendre là où j'en étais », MPL-048), ouverture du lecteur plein écran depuis le bouton (MPL-047), index dans Albums et Artistes (MPL-048), côté gauche (MPL-048).

## À valider (PO)

- Exigence 3 : le bouton se replie pendant que la liste défile, quelle que soit la vitesse (la conception parle de « défilement rapide » sans seuil).
- Exigence 4 : « dernière jouée » ne survit pas à la fermeture de l'application.
- Exigence 5 : sans la piste dans la liste, pas de bouton, faute de lecteur plein écran pour la variante de la conception.

## As-built

Livré par MPL-045 (2026-10-23), test appareil en attente (D14).
- Index : `AlphabetScroller` entoure le `CustomScrollView` ; `onLetterSelected` fait `jumpTo(premier indice × 64)`. Le rectangle de la poignée part vers `gestureExclusionProvider` converti en pixels ; il est retiré à la sortie de la vue et quand la vue n'est plus au premier plan (`TickerMode`).
- Bouton : `jumpDirection` et `jumpOffset` (fonctions pures testées) ; visibilité déduite du défilement, repli pendant le défilement et dépliage 600 ms après l'arrêt, `animateTo` qui centre la ligne puis éclairage d'une seconde. « Dernière jouée » : `lastPlayedProvider`, session seulement.
- Limite : au-delà de 1,3 fois le texte, la position est estimée (lignes de 64 dp).
- MPL-048, 2026-10-23 : l'exigence 2 (poignée exclue du geste Retour seulement quand la vue est au premier plan) ne tenait pas pour un changement d'onglet : `IndexedStack` ne coupe plus les `Ticker`. La vue lit maintenant `Visibility.of` en plus de `TickerMode`, et passe par `GestureRegions` (ADR-016).
- MPL-047, 2026-10-23 : quand la piste en cours n'est pas dans la liste affichée (`LibraryListModel.currentOutsideList`), le bouton « En cours » est montré sans flèche et ouvre le lecteur plein écran (`_fab` de `LibraryTrackList`). Non testé sur appareil (cas difficile à provoquer : dossier retiré pendant la lecture).
