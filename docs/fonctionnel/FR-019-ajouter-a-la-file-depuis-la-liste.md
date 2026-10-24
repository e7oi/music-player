# FR-019 — Ajouter une piste à la file depuis la liste

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** UC-007, FR-010, FR-011, FR-018, BR-001, BR-009, ADR-015 · **Source :** demande du propriétaire du 2026-10-23 ; `docs/design/HANDOFF.md` §6 (`TrackTile` : « appui long = menu (futur) »)

## Besoin

Choisir à la main ce qui vient ensuite, sans relancer toute la liste : mettre une piste juste après celle qui joue, ou tout au bout de la file. Le retrait d'une piste se fait dans la file (FR-018).

## Exigences

1. **Menu.** Un appui long sur une ligne de la liste de pistes ouvre un petit menu avec deux actions : « Lire ensuite » et « Ajouter à la file ». Pour TalkBack, les deux actions sont aussi proposées comme actions personnalisées de la ligne.
2. **Lire ensuite** place la piste juste après la piste en cours (BR-009, règle 11). **Ajouter à la file** la place à la fin.
3. **Retour.** Une `SnackBar` brève confirme (« Lecture ensuite : {titre} », « Ajouté à la file : {titre} »).
4. **File vide.** Si rien n'est chargé, la piste devient la file et la lecture démarre dessus, comme si on l'avait touchée.
5. **Pistes indisponibles.** Une piste d'un disque absent peut être ajoutée ; elle est grisée dans la file et sautée (BR-001, FR-018.7).
6. **Doublons.** Une même piste peut se trouver plusieurs fois dans la file ; chaque ligne de la file reste indépendante.
7. **Portée.** Le menu est dans l'onglet Pistes. Albums et Artistes l'utiliseront avec MPL-048.
8. **Règles d'interface.** Jetons seulement, clair et sombre, zones tactiles de 48 dp, texte à 200 % (BR-007).
9. **Textes.** Dans les fichiers ARB, en français et en anglais : « Lire ensuite », « Ajouter à la file », et les deux messages de confirmation.

## Hors périmètre

Sélection de plusieurs pistes, ajout d'un album ou d'un artiste entier (MPL-048), ajout depuis le lecteur ou la file, menu d'autres actions (favoris, playlists, détails).

## À valider (PO)

- Exigence 2 : plusieurs « Lire ensuite » de suite se placent chacun juste après la piste en cours, donc dans l'ordre inverse de la demande.
- Exigence 4 : sur une file vide, la lecture démarre.
- Exigence 6 : les doublons sont permis.
- Exigence 1 : la conception n'a pas dessiné ce menu ; il est construit avec les jetons et les composants du projet.

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). `showTrackMenu` (`lib/features/player/track_menu.dart`), appelé par l'appui long d'une ligne de `LibraryTrackList` (`TrackTile.onLongPress`). Contrôleur : `playNext` et `enqueue`. Tests : `test/features/library/library_page_test.dart` (menu, file vide, ordre), `test/domain/playback/player_controller_queue_test.dart`.

- Menu : feuille modale à deux lignes (`showTrackMenu`). Pour TalkBack, la ligne offre aussi « Lire ensuite » et « Ajouter à la file » comme actions personnalisées (`applyTrackAction`, testé).
- Sur une file vide, la provenance de la file (FR-017.2) est effacée : la piste ajoutée ne vient d'aucune liste.
- Aucune confirmation avant l'ajout hors le message bref.
- MPL-048, 2026-10-23 : le menu sert aussi aux albums et aux artistes entiers (`showTracksMenu`, FR-022) ; `applyTrackAction` n'est plus qu'un cas d'une piste de `applyTracksAction`.
