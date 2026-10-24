# ADR-016 — Architecture des vues Albums et Artistes : groupes purs, navigation dans l'onglet, index multiples

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-048 · **Décisions :** D23 · **Fiches :** UC-008, FR-020, FR-021, FR-022, BR-010 · **Complète :** ADR-010, ADR-013, ADR-015

## Contexte

Les onglets Albums et Artistes affichent « bientôt ». Ils ont besoin de groupes calculés à partir de toutes les pistes (plusieurs milliers), de détails qui gardent la navigation et le mini-lecteur, de l'index alphabétique et de plusieurs façons de lancer la lecture. La coquille garde ses vues dans un `IndexedStack` : trois vues peuvent porter un index.

## Décision

- **Groupes purs** dans `features/library/` (ou un dossier `features/browse/`), sans Flutter ni base : une fonction reçoit les pistes de la liste limitée à deux émissions par seconde (`listedTracksProvider`), les disques et les disques indisponibles, et rend les albums, les artistes, leurs compteurs, leurs lettres d'index et la disponibilité (BR-010). Tests d'abord. Le domaine de bibliothèque n'est pas touché : la clé de regroupement et le tri sont de la présentation (comme `alphabetKey` et `sortTracks`, ADR-013).
- **Calcul mis en cache** par fournisseur : recalculé à chaque émission de la liste, jamais au défilement ; un seul passage sur les pistes alimente albums et artistes.
- **Détail dans l'onglet** : chaque onglet Albums et Artistes porte un `Navigator` imbriqué (routes « grille/liste » puis « détail »), avec `NavigatorPopHandler` pour que le geste Retour du système revienne d'abord dans l'onglet avant que la coquille ne ramène sur Pistes (FR-009.7). Le mini-lecteur et la navigation restent donc visibles. Un détail d'artiste ouvre un détail d'album dans le même navigateur. Aucun routeur de paquet (ADR-010).
- **Exclusion du geste Retour pour plusieurs index** : le canal ne garde que le dernier rapport (FR-010, as-built). Le fournisseur de rectangles devient une table par propriétaire (clé = vue) dont l'union est envoyée au canal ; une vue qui n'est plus au premier plan retire son entrée. Test sur la fusion et le retrait.
- **Provenance de la file** : `QueueOrigin` (ADR-015) passe d'une énumération à une valeur qui porte le genre (pistes, album, artiste) et le nom ; le lecteur écrit « Album · {titre} » ou « Artiste · {nom} » (FR-022.6).
- **Lancer un groupe** : fonctions de `features/` qui appellent `setShuffle`, `setQueue` et `play` (ou `playNext`, `enqueue`) dans le bon ordre ; aucune nouvelle opération du contrôleur (BR-009 suffit).
- **Grille** : `SliverGrid` à `SliverGridDelegateWithMaxCrossAxisExtent` (carte de 160 dp au moins), hauteur de carte connue pour calculer le saut de l'index ; la grille d'albums, la liste d'artistes avec intercalaires et leurs sauts sont des fonctions pures testées.
- **Aucune dépendance nouvelle.**

## Conséquences

- La coquille cesse de monter `ComingSoonPage` pour Albums et Artistes ; `ComingSoonPage` ne sert plus qu'à Réglages jusqu'à MPL-051.
- `gestureExclusionProvider` change (une table au lieu d'un rapport) ; `LibraryTrackList` s'y adapte.
- La liste des pistes, la grille d'albums et la liste d'artistes partagent l'idée « index + saut » mais pas le code : un saut par défilement de grille n'est pas un décalage de ligne fixe.

## Alternatives examinées

- Détail en plein écran par `Navigator.push` sur la racine : plus simple, mais cache le mini-lecteur et la navigation (la conception les montre) ; écartée.
- Détail par un état de la vue (sans navigateur) : le geste Retour du système demande une pile de `PopScope` imbriqués fragile ; écartée.
- Tables `albums` et `artists` en base : redondantes avec les pistes, à tenir à jour à chaque indexation (BR-004) pour un calcul de quelques millisecondes ; écartées.

## À valider (PO)

- Le navigateur imbriqué par onglet et `NavigatorPopHandler`.
- La table de rectangles d'exclusion (modifie le canal de FR-010, ADR-010 `Active`, côté Dart seulement).

## As-built

MPL-048, 2026-10-23, test appareil partiel (D14). Réalisé comme décidé, avec ces précisions : `HomeShell` monte un `Navigator` par onglet Albums et Artistes (`_TabNavigator`) et envoie le Retour système au navigateur de l'onglet avant de ramener sur Pistes, sans `NavigatorPopHandler` (deux `PopScope` imbriqués auraient tous deux agi) ; `GestureRegions` (`app/providers/gesture_providers.dart`) tient une table de rectangles par vue et envoie l'union au canal ; `HandleExclusion` (`browse_widgets.dart`) la nourrit ; `QueueOrigin` est une classe scellée (`TracksByTitle`, `AlbumOrigin`, `ArtistOrigin`).

- Découverte : `IndexedStack` ne coupe plus les `Ticker` des onglets cachés dans la version de Flutter épinglée ; l'état « vue au premier plan » vient de `Visibility.of` en plus de `TickerMode`. La liste des pistes (MPL-045) gardait donc sa poignée protégée du geste Retour quand un autre onglet était affiché ; corrigé au passage dans `LibraryTrackList` (FR-013.2).
- La grille d'albums utilise un `SliverGridDelegateWithFixedCrossAxisCount` dont le nombre de colonnes est calculé de la largeur (160 dp au moins, de 2 à 6) et dont la hauteur de ligne est fixe, et non `MaxCrossAxisExtent` : le saut de l'index a besoin de la hauteur exacte d'une ligne.
- Les détails d'album et d'artiste construisent leurs lignes à la demande (`SliverList.builder`), car « Artiste inconnu » peut compter des milliers de pistes.
- Les menus d'appui long s'ouvrent sur le navigateur racine (`useRootNavigator`), comme sur Pistes : le voile couvre tout l'écran.
- `libraryGroupsProvider` recalcule à chaque émission de `listedTracksProvider` (deux par seconde au plus) ou quand l'ensemble des disques indisponibles change.
