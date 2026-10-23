# ADR-010 — Architecture de l'interface : `lib/ui/`, navigation sans routeur, icônes intégrées, pas de goldens

**Statut :** Brouillon (2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-016 · **Décisions :** D2, D15, D30 · **Fiches :** FR-008, FR-009, FR-010, BR-007 · **Complète :** ADR-001

## Contexte

Le dossier de conception (`docs/design/HANDOFF.md`) suppose un projet vide et propose un fichier de jetons `lib/theme/`, des composants, des routes nommées, des icônes Material Symbols, un thème dynamique et des tests « golden ». Le dépôt a déjà une architecture (`CLAUDE.md`, ADR-001) : `features/` n'importe que `domain/`, `l10n/` et `app/providers/` ; `package:flutter/services.dart` n'est permis que sous `platform/` et `app/` ; les tests de widgets vérifient le comportement, sans fichiers golden ; toute dépendance nouvelle se justifie (D30).

## Décision

- **Nouveau dossier `lib/ui/`**, sans logique métier :
  - `ui/theme/` : fichier de jetons (`tuneshell_tokens.dart`) et thèmes (FR-008) ;
  - `ui/widgets/` : les composants (FR-010), qui reçoivent des valeurs simples et des fonctions de rappel ;
  - `ui/demo/` : page de démonstration, montrée seulement en debug et profile (`kDebugMode || kProfileMode`), ouverte depuis l'onglet Réglages.
- **Règles de dépendance** (à ajouter à `CLAUDE.md` et à `test/architecture/` après validation) :
  - `ui/` n'importe que Flutter, `l10n/` et lui-même. Jamais `domain/`, `data/`, `platform/`, `app/`, `features/`, Riverpod ;
  - `features/` peut importer `ui/` en plus de `domain/`, `l10n/` et `app/providers/` ;
  - `package:flutter/services.dart` est permis sous `ui/` pour `HapticFeedback` seulement (retour haptique de l'index).
- **Coquille de navigation** : `lib/features/shell/`. Largeur de `LayoutBuilder` : moins de 600 dp, `NavigationBar` ; 600 dp et plus, `NavigationRail`. Les vues sont dans un `IndexedStack` ; les sous-écrans passent par `Navigator.push`. **Aucun routeur** (`go_router` écarté : le besoin tient à quatre onglets et deux sous-écrans).
- **Icônes** : `Icons.*_rounded` fournies par le SDK Flutter, plus des tracés propres si un symbole manque. **Aucun paquet d'icônes** (`material_symbols_icons` écarté : dépendance lourde pour une trentaine de glyphes).
- **Polices** : Manrope (600, 700, 800) et Inter (400, 500, 600), six fichiers TTF statiques dans `assets/fonts/` avec les `OFL.txt`, déclarés dans `pubspec.yaml` ; jamais `google_fonts`.
- **Tests** : pas de golden (règle de `CLAUDE.md` conservée). Un test de widget par état de composant, des assertions de comportement (taille tactile, `Semantics`, contraste calculé depuis les jetons, saut de l'index sur 5 000 éléments), un test d'architecture contre les littéraux de couleur, rayon, espacement et taille de police (BR-007, règle 1). La comparaison visuelle aux captures se fait par le propriétaire sur la page de démonstration, en profile sur le Pixel.
- **Exclusion du geste Retour pour la poignée de l'index** : canal natif `net.trtl3.tuneshell/gesture_exclusion` (Kotlin `View.setSystemGestureExclusionRects`, API 29 et plus, `minSdk` 30), côté Dart sous `platform/` ; la zone est envoyée par la page qui porte l'index.
- **Fichier de jetons** : repris de Design, avec commentaires en anglais (D28), syntaxe et lints du projet ; les noms (`TsColors`, `TsSpace`…) sont gardés.
- **Dépendances** : aucune dans ce ticket. `dynamic_color` (Material You) arrive avec les réglages (MPL-048), sur validation.

## Conséquences

- `CLAUDE.md` et `test/architecture/import_rules.dart` changent (après validation du propriétaire) : règle 3 élargie à `ui/`, nouvelle règle pour `ui/`, exception `HapticFeedback`.
- La page de démonstration n'existe pas dans la build release : la validation visuelle des composants se fait en profile, pas en release (D14 reste pour les écrans de l'application).
- Le Kotlin du canal de geste n'a pas de test unitaire (exception de `CLAUDE.md`) : procédure dans `HOWTO.md`.

## Alternatives examinées

- Jetons et composants sous `app/` : `features/` ne peut importer que `app/providers/`, il faudrait élargir cette règle à tout `app/` et mêler câblage et dessin. Écartée.
- `go_router`, `NavigationSuiteScaffold` ou paquets adaptatifs : dépendances pour un besoin simple. Écartées.
- Goldens : fragiles entre machines et versions de Flutter, interdits par `CLAUDE.md`. Écartés.
- Composants dans chaque feature : doublons entre bibliothèque, disques, albums et artistes. Écartée.

## À valider (PO)

- Création de `lib/ui/` et modification de `CLAUDE.md` (règle 3 élargie, règle `ui/`, exception `HapticFeedback`).
- Pas de routeur, pas de paquet d'icônes, pas de golden.
- Page de démonstration absente de la release.
- Canal natif pour l'exclusion du geste Retour.

## As-built

À écrire à la livraison de MPL-016.
