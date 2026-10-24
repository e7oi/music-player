# FR-017 — Lecteur plein écran

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** UC-007, FR-001, FR-007, FR-012, FR-016, FR-018, BR-003, BR-007, BR-008, BR-009, ADR-010, ADR-015 · **Source :** `docs/design/HANDOFF.md` §5 (écran 5, états 5a, 5b, 5d), §4 (repère de source), `Lecteur.dc.html`

## Besoin

Un grand écran pour la piste en cours : pochette, informations, position, modes de lecture et accès à la suite.

## Exigences

1. **Ouverture et fermeture.** Le lecteur s'ouvre depuis le mini-lecteur (FR-016.4) et se ferme par le bouton « Réduire » en haut, un glissé vers le bas ou le geste Retour du système ; l'utilisateur retrouve la vue d'où il venait, au même endroit. Il reste ouvert à la rotation. Il n'existe que s'il y a une piste courante ; si la file se vide, il se ferme.
2. **En-tête.** « Réduire », puis « Lecture depuis » et la provenance de la file telle qu'elle a été lancée (« Pistes · Titre A→Z »). Le mélange et les déplacements ne la changent pas.
3. **Pochette.** 348 dp, rayon 16, tuile neutre avec une note sans pochette (FR-007.7), transition partagée avec le mini-lecteur. Opacité réduite si le disque est perdu.
4. **Informations.** Titre (`TsText.playerTitle`, nom du fichier sans titre), « artiste · album » (« Artiste inconnu » ; l'album est omis s'il manque). Ligne de métadonnées : repère de source suivi du nom de la source, puis les parties connues parmi « Disque N », « Piste N », année, genre. Sans aucune de ces quatre informations, la ligne donne le format du fichier (extension en capitales) et son dossier : « Local · FLAC · Download ».
5. **Favori.** Un cœur désactivé, infobulle « Favoris (bientôt) » : un emplacement, pas une fonction.
6. **Position.** Curseur, temps écoulé et durée. Le déplacement est envoyé au lâcher, pas à chaque mouvement. Utilisable au clavier et avec TalkBack par pas de 5 s ; valeur dite « 1:38 sur 4:18 ». Désactivé tant que la durée est inconnue.
7. **Contrôles.** Aléatoire, précédent, lecture/pause (80 dp, rayon 28), suivant, répéter. L'état actif d'aléatoire et de répéter se voit autrement que par la couleur (point sous l'icône) ; répéter montre l'icône « une piste » pour ce mode (BR-009) ; TalkBack annonce l'état. Précédent et suivant suivent FR-001.
8. **À suivre.** Un bouton « À suivre · N pistes » (N = pistes après la courante) avec le titre et l'artiste de la prochaine piste ouvre la file d'attente (FR-018). Sans suite : « À suivre · aucune piste » et pas de prochaine piste.
9. **Fichier illisible** (état 5d). Quand une piste ne se lit pas et que la lecture passe à la suivante (BR-003), un bandeau d'erreur dans le flux, sous la pochette, dit « Impossible de lire « {titre} » : fichier endommagé. Piste suivante lancée. » avec un bouton pour le fermer. Il reste jusqu'à sa fermeture ou la fermeture du lecteur. Pendant que le lecteur est ouvert, le message n'est pas répété en `SnackBar` (BR-008, règle 7). Pas de compte à rebours ni de bouton « Passer » : la lecture ne s'arrête pas (voir À valider).
10. **Lecture arrêtée.** Après trois échecs de suite (BR-003, règle 2) ou une éjection (BR-002), un bandeau dit pourquoi, avec les textes déjà en place pour ces cas ; pour l'éjection : « Lecture arrêtée : {disque} débranché ».
11. **Paysage et grand texte.** En paysage, deux colonnes : la pochette (à la hauteur disponible) d'un côté, informations et contrôles de l'autre ; le panneau permanent est hors de ce ticket. Le contenu défile si l'échelle du texte monte (200 % sans rien couper).
12. **Règles d'interface.** Jetons seulement, clair et sombre, animations réduites respectées, zones tactiles de 48 dp, libellé sur tout bouton-icône (BR-007).
13. **Textes.** Dans les fichiers ARB, en français mot pour mot des maquettes (« Réduire », « Lecture depuis », « À suivre · {n} pistes », « Favoris (bientôt) », « Aléatoire », « Répéter », « Lecture », « Pause »), avec la version anglaise.

## Hors périmètre

Favoris réels, paroles, égaliseur, minuterie de sommeil, vitesse de lecture, partage, menu « plus d'options », panneau permanent (MPL-048).

## À valider (PO)

- Exigence 9 (écart à la maquette 5d) : la conception montre « Piste suivante dans 3 s » et « Passer », donc une pause avant de sauter. BR-003 (`Active`) saute tout de suite ; je garde BR-003, d'où un bandeau sans compte à rebours ni « Passer ». Option : ajouter le délai, ce qui change BR-003 et le contrôleur.
- Exigence 4 : la règle de la ligne de métadonnées (parties présentes ; format et dossier sans étiquettes) est mon interprétation de 5a et 5b.
- Exigence 3 : les pochettes sont réduites à 512 pixels (FR-007.6) ; sur 348 dp elles seront agrandies à l'écran (environ 1 000 pixels sur le Pixel). À juger sur l'appareil ; passer à 1 024 pixels demanderait de relire les pochettes.
- Exigence 1 : le glissé vers le bas pour fermer est fait sans dépendance ; s'il est fragile, il est abandonné (bouton et Retour restent).
- Exigence 11 : mise en page du lecteur en paysage, non dessinée par la conception.
- Exigence 10 : texte « Lecture arrêtée : {disque} débranché », de moi.

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). `PlayerPage` et `openPlayer` (`lib/features/player/player_page.dart`), `NowPlaying` (`now_playing.dart`, informations et ligne de métadonnées), `ToggleIconButton` (`lib/ui/widgets/toggle_icon_button.dart`). Tests : `test/features/player/now_playing_test.dart`, `player_flow_test.dart`.

- Page poussée par `Navigator.push` (fondu, `Hero` sur la pochette) ; fermeture par « Réduire », glissé vers le bas (vitesse de plus de 700 dp/s) et geste Retour. Le glissé vers le bas est un détecteur simple : il est inopérant quand le contenu défile.
- `playerOpenProvider` dit que le lecteur est ouvert : la liste n'affiche alors pas le `SnackBar` de fichier illisible. `playerFailureProvider` est vidé à chaque ouverture.
- Le curseur n'envoie le déplacement qu'au lâcher ; ses actions TalkBack avancent et reculent de 5 s et annoncent la nouvelle valeur (une assertion de Flutter l'exige).
- Écart : le point d'état d'aléatoire et de répétition est dans `ToggleIconButton` ; le bouton « À suivre » montre « titre · artiste » de la prochaine piste.
- Texte du bandeau d'éjection (« Lecture arrêtée : {disque} débranché ») et libellés ajoutés par moi, en français et en anglais.
