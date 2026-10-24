# UC-007 — Écouter avec le mini-lecteur et le lecteur plein écran

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** UC-001, UC-002, UC-004, UC-005, FR-016, FR-017, FR-018, FR-019, BR-009 · **Source :** `docs/design/HANDOFF.md` §5 (écran 5, états 5a à 5d, 6d)

## Acteur et but

L'utilisateur écoute sa musique dans l'application. Il veut voir et commander ce qui joue depuis n'importe quelle vue, puis ouvrir un grand lecteur pour se déplacer dans la piste, mélanger, répéter et regarder ou changer ce qui vient ensuite.

## Préconditions

- Une piste a été lancée depuis la bibliothèque (UC-001, UC-005) : la file n'est pas vide.

## Scénario nominal

1. Dès qu'une piste est chargée, le **mini-lecteur** apparaît au-dessus de la navigation, dans les quatre vues : pochette, titre, repère de source et artiste, précédent, lecture/pause, suivant, fine barre de progression (FR-016).
2. L'utilisateur met en pause ou passe à la piste suivante depuis le mini-lecteur.
3. Il touche la partie gauche du mini-lecteur (ou glisse vers le haut) : le **lecteur plein écran** s'ouvre, la pochette passe du petit au grand format (FR-017).
4. Il déplace le curseur de position, active l'aléatoire ou la répétition (BR-009).
5. Il touche « À suivre · 11 pistes » : la **file d'attente** s'ouvre en feuille. Il déplace une piste vers le haut, en touche une autre pour la lire, retire une piste de la suite, ou vide la suite (FR-018). Depuis la liste, un appui long sur une piste propose « Lire ensuite » et « Ajouter à la file » (FR-019).
6. Il réduit le lecteur (bouton, glissé vers le bas ou geste Retour) et retrouve la vue où il était, au même endroit.

## Variantes

- 1a. Le fichier n'a ni titre ni pochette : le nom du fichier tient lieu de titre, une tuile neutre tient lieu de pochette (FR-016, FR-017).
- 4a. Le fichier ne se lit pas : la lecture passe à la suivante (BR-003) et le lecteur le dit dans un bandeau (FR-017).
- 5a. Une piste de la file est sur un disque absent : elle est grisée, « sera ignorée », et la lecture la saute (BR-001, FR-018).
- 5b. Le disque de la piste en cours est retiré : la lecture s'arrête (BR-002) et le mini-lecteur et le lecteur le disent ; elle ne reprend pas au rebranchement.
- 6a. Téléphone en paysage : le mini-lecteur reste en bas de la colonne de contenu ; le lecteur plein écran passe sur deux colonnes (le panneau permanent est hors de ce ticket).
- 6b. Rien n'est chargé (file vide, application relancée) : pas de mini-lecteur.

## Hors périmètre

Panneau lecteur permanent des écrans larges (MPL-048), favoris, paroles, égaliseur, ajout d'albums ou d'artistes entiers à la file (MPL-048), sélection de plusieurs pistes, mémorisation de la file et des modes entre deux lancements (MPL-048, « Reprendre là où j'en étais »), actions aléatoire et répétition dans la notification (FR-005).

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). Parcours livré par FR-016 à FR-019 et BR-009. `lib/features/player/` (mini-lecteur, page du lecteur, feuille de la file, menu d'appui long, fournisseurs de session) ; tests : `test/features/player/`, `test/ui/widgets/mini_player_test.dart`, `test/features/library/library_page_test.dart`.

- Le lecteur en paysage est sur deux colonnes ; le panneau permanent reste à décider (MPL-048, voir le backlog).
