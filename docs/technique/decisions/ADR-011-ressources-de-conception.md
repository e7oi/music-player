# ADR-011 — Ressources de conception dans le dépôt

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-016 · **Décisions :** D1, D21, D27 · **Fiches :** FR-008 · **Complète :** ADR-010

## Contexte

Claude Design a fourni un dossier de transmission : `CLAUDE.md` et `LISEZMOI.md` propres à ce dossier, `docs/design/` (spécification, messages de lots, sources HTML des maquettes), un fichier de jetons, des polices (64 fichiers TTF, 20 Mo), des SVG de marque et 29 captures PNG (17 Mo). Le dépôt est public : l'historique Git ne se réécrit pas, et ce qui y entre y reste.

## Décision

- **Versionnés** (`docs/design/`, en français, D28) :
  - `HANDOFF.md`, mis à jour avec les décisions du projet : licence GPL-3.0-or-later (D1), moteur `media_kit` (D2), base Drift (D3), nom TuneShell (D4), `minSdk` 30 (ADR-005) ; le plan par lots est remplacé par un renvoi aux tickets MPL-016 et MPL-044 à MPL-049 ;
  - `screens/README.md` et `screens/source/*.dc.html` (environ 340 Ko) ;
  - `brand/` : SVG et références de marque (petits fichiers), pour le lot Finitions (MPL-049) ;
  - quatre captures clés, recompressées à 400 Ko au plus chacune : direction visuelle, composants clair et sombre, jetons.
- **Dans le code** : `assets/fonts/` avec six fichiers TTF statiques (Manrope 600, 700, 800 ; Inter 400, 500, 600, soit environ 1,3 Mo) et les deux `OFL.txt` ; le fichier de jetons sous `lib/ui/theme/` (ADR-010).
- **Pas versionnés** : le `CLAUDE.md` du dossier de conception (ses règles sont reprises dans BR-007 et dans `CLAUDE.md` du projet), son `LISEZMOI.md` et `PROMPTS.md` (remplacés par `/cadrer` et le backlog), les polices variables et les 58 TTF non utilisés, les 25 autres captures. Elles restent chez le propriétaire.
- **Dossier `ClaudeDesign/`** : il est à la racine de l'arbre de travail, non suivi. Il doit rester hors du dépôt (déplacé hors de l'arbre de travail, ou exclu localement par `.git/info/exclude`) ; les ajouts se font par chemins explicites, jamais `git add -A`.
- **Données d'exemple** : celles des maquettes sont fictives (`screens/README.md`). Avant d'ajouter un fichier, vérifier qu'il ne contient aucun titre, artiste, chemin ou identifiant de volume réels (D27).

## Conséquences

- L'historique gagne environ 2 à 3 Mo (polices, sources, captures réduites, marque), pas 38 Mo.
- Le propriétaire garde les 29 captures complètes pour comparer avec la page de démonstration.

## Alternatives examinées

- Tout versionner : 38 Mo irréversibles dans l'historique public. Écartée.
- Polices variables : un fichier par famille, mais les poids passent par `FontVariation` et la page de démonstration devient plus délicate à vérifier ; les 6 fichiers statiques sont plus simples. Écartée.
- Ne rien versionner des captures : les sources HTML sont lisibles mais difficiles à comparer ; quatre captures donnent la direction visuelle. Écartée.

## À valider (PO)

- Choix des quatre captures versionnées, du dossier `brand/` et du devenir de `ClaudeDesign/`.
- Licence des maquettes, du logo et des icônes de marque : la même que le code (GPL-3.0-or-later, D1), ou une autre pour la marque ? À trancher avant la publication (D5, D6).

## As-built

À écrire à la livraison de MPL-016.
