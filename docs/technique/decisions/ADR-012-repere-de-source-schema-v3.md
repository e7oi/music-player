# ADR-012 — Repère de source : stockage et attribution (schéma v3)

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-045 · **Décisions :** D23 · **Fiches :** FR-012, FR-011 · **Complète :** ADR-004, ADR-008

## Contexte

La conception veut un repère (forme et couleur) par source, stable, jamais partagé entre deux disques, que l'utilisateur pourra changer (MPL-046). La base ne stocke aujourd'hui que l'identifiant, le nom et le type du disque (ADR-004, schéma v2). L'interface connaît les pistes par `LibraryTrack`, qui ne porte que l'identifiant du disque.

## Décision

- **Colonne `disks.mark_index`**, entier nullable, schéma v3. Nul pour le stockage interne (repère fixe, un cercle neutre), 0, 1, 2… pour les disques amovibles. Un index unique sur la colonne garantit que deux disques ne partagent jamais un indice ; SQLite accepte plusieurs valeurs nulles.
- **Attribution dans le dépôt de la bibliothèque**, à l'enregistrement d'un disque amovible (`ensureDisk`, `setChosenFolders`) : le plus petit indice libre parmi les disques déjà enregistrés. La règle est une fonction pure de `domain/library/` (`nextFreeMarkIndex`), testée d'abord ; l'adaptateur Drift l'appelle dans la transaction d'enregistrement.
- **Migration v2 vers v3** : ajout de la colonne, puis indices 0, 1, 2… aux disques amovibles par ordre d'identifiant ; le disque interne reste nul. Test de migration depuis le dump v2 (`drift_schemas/`), comme pour v2.
- **Modèle** : `Disk` gagne `markIndex` (entier nullable). Le port `LibraryRepository` gagne `Stream<List<Disk>> watchDisks()`, pour que l'interface associe chaque piste à son disque (nom, indice) sans interroger la base ligne par ligne.
- **Couleur et forme** viennent de l'indice dans `ui/` (`SourceMark.disk(index)`, `TsColors.sourceColor`) : la base ne stocke jamais une couleur.

## Conséquences

- L'indice ne change qu'à la demande de l'utilisateur (MPL-046) ; le retrait d'un disque (MPL-038) devra décider si son indice se libère.
- Le repère est une donnée de l'appareil : aucun identifiant de volume n'entre dans le dépôt (D27).

## Alternatives examinées

- Calculer l'indice au moment de l'affichage, par rang du disque : il changerait quand un disque est retiré ou ajouté. Écartée.
- Stocker forme et couleur : redondant avec l'indice et rigide si la palette change. Écartée.
- Un indice par dossier au lieu de par disque : D23 fait du disque la source. **Gardée comme option ouverte** (propriétaire, 2026-10-23), à trancher à l'usage : le schéma v3 ne ferme pas la porte (une colonne équivalente sur `disk_folders` resterait possible).

## À valider (PO)

- Nouveau schéma v3 et sa migration.
- L'indice appartient au disque et ne se libère pas tant que le retrait d'un disque n'existe pas.

## As-built

Livré par MPL-045 (2026-10-23). Conforme à la décision : colonne nullable `mark_index`, index unique, attribution dans la transaction d'`ensureDisk`, migration par étapes avec les indices 0, 1, 2… dans l'ordre d'enregistrement. Aucun écart.
