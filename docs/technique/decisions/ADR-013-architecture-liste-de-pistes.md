# ADR-013 — Architecture de la liste de pistes : modèle de vue, défilement, index et saut

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-045 · **Décisions :** D23 · **Fiches :** FR-011, FR-012, FR-013, BR-008 · **Complète :** ADR-010

## Contexte

La liste actuelle est un `ListView` de `ListTile` qui reconstruit tout à chaque émission de la base, trie en Dart par `toLowerCase` (les titres accentués finissent après le Z) et affiche les états dans une colonne qui mêle écran et logique. La conception demande une liste fixe de 64 dp, un index alphabétique, un bouton « En cours », des repères de source, des bandeaux dans le flux et 60 images par seconde pour plus de 5 000 pistes. Le jeu d'essai réel compte 7 562 pistes.

## Décision

- **Modèle de vue pur** dans `features/library/` : une fonction qui reçoit les pistes, les disques (nom, indice de repère), les disques disponibles, la piste en cours, les pistes illisibles de la session et rend la liste d'entrées prêtes à afficher (état de ligne, texte, repère), les compteurs, les lettres de l'index avec le premier indice de chacune, le bandeau d'état et son empreinte (pour « masquer jusqu'au prochain changement »). Tests d'abord (`CLAUDE.md`, logique d'état).
- **Tri par clé repliée** : la clé est celle de l'index (`alphabetKey`, accents et casse repliés) puis le titre replié, puis le chemin et l'identifiant. Les titres qui commencent par un chiffre ou un symbole viennent en tête, d'où un groupe « # » contigu. Le tri se fait une fois par émission, dans le modèle de vue, pas dans le dépôt Drift.
- **Mises à jour limitées** : la liste se reconstruit au plus deux fois par seconde, en réutilisant la fonction `throttle` de `app/providers/` (MPL-016). La fin d'une série d'émissions passe toujours.
- **En-tête dans une colonne, liste défilante dessous** : pastilles, bandeaux et ligne de compte sont des widgets au-dessus d'un `CustomScrollView` ; ils ne défilent pas avec la liste, comme dans la maquette. Le décalage d'une ligne dans la liste est donc `indice × TsSize.trackRow`, sans mesurer de sliver. Pas de `Stack` par-dessus la liste (BR-007, règle 2), sauf l'index et le bouton « En cours », qui sont des superpositions de la conception.
- **Liste** : `SliverFixedExtentList` (`itemExtent` de `TsSize.trackRow`) jusqu'à 1,3 fois l'échelle du texte, `SliverList` au-delà, avec `TsSize.listBottomInset` en bas.
- **Index** : `AlphabetScroller` autour du `CustomScrollView` ; `onLetterSelected` fait `jumpTo(premierIndice × 64)`. Le rectangle de la poignée est envoyé au canal de geste (`gestureExclusionProvider`, ADR-010) par la page, converti en pixels, et retiré à la sortie de la vue.
- **Bouton « En cours »** : la visibilité se déduit du décalage de défilement, de la hauteur visible et de l'indice de la piste, sans mesure de widget ; la logique est une fonction pure testée. Le saut est un `animateTo` qui centre la ligne ; la mise en évidence est un état du modèle de vue qui tombe après environ une seconde.
- **Dernière piste jouée** : un fournisseur de session met à jour la dernière piste en cours ; rien n'est écrit en base (ADR-012 n'y touche pas).
- **Pistes illisibles de la session** : un ensemble tenu par le contrôleur de la liste, alimenté par `TrackFailed` (BR-003), vidé à la fermeture de l'application.
- **Aucune dépendance.**

## Conséquences

- `LibraryPage` est découpée : une page mince qui lit le modèle de vue, des widgets d'en-tête et d'états vides.
- Le tri accentué change l'ordre affiché de la bibliothèque : à signaler dans la PR.
- À 7 562 pistes, un tri complet par émission est acceptable (quelques millisecondes) ; à mesurer en profile, avec la limite de deux reconstructions par seconde.

## Alternatives examinées

- Trier en SQL (`COLLATE`, colonne repliée) : demande une colonne de plus et une migration pour un gain que la mesure n'a pas montré. Écartée.
- Bandeaux comme premiers slivers du `CustomScrollView` : ils défilent avec la liste et obligent à mesurer le décalage de la liste. Écartée.
- `scrollable_positioned_list` : une dépendance pour un besoin couvert par une hauteur de ligne fixe. Écartée.

## À valider (PO)

- Tri accentué, et donc ordre d'affichage modifié.
- En-tête fixe au-dessus de la liste (comme la maquette), non défilant.
- Dernière piste jouée et pistes illisibles gardées en mémoire de session seulement.

## As-built

À écrire à la livraison de MPL-045.
