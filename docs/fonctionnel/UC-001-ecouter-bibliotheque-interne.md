# UC-001 — Écouter une piste de la bibliothèque interne

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-018 · **Décisions :** D23, D25 · **Lié :** FR-001, FR-003, FR-004, BR-004

## Acteur et but

L'utilisateur veut voir les pistes de musique de son téléphone, sans les sonneries ni les sons reçus par les messageries, et en écouter une.

## Préconditions

- Des fichiers audio sont présents dans le stockage interne du téléphone.

## Scénario nominal

1. L'utilisateur ouvre l'application.
2. Au premier lancement, l'application demande l'accès aux fichiers audio (FR-004) ; l'utilisateur accepte.
3. L'application affiche les dossiers du téléphone qui contiennent de l'audio, `Music/` coché s'il existe ; l'utilisateur confirme ou change le choix (FR-003).
4. L'application indexe les dossiers choisis en arrière-plan. La liste des pistes s'affiche et se remplit sans bloquer l'écran.
5. L'utilisateur touche une piste : la lecture démarre sur cette piste, la file contient toute la liste dans l'ordre affiché (FR-001).
6. Une barre de lecture montre la piste en cours, avec lecture/pause, piste suivante et piste précédente.

## Variantes

- 2a. L'utilisateur refuse l'accès : la liste est remplacée par un message et un bouton pour redemander l'accès (FR-004).
- 3a. Aucun dossier ne contient d'audio : un message l'indique.
- 3b. L'utilisateur ne coche aucun dossier : la liste reste vide, avec un bouton vers le choix des dossiers.
- 4a. Aucune piste trouvée dans les dossiers choisis : un message l'indique, avec un bouton vers le choix des dossiers.
- 5a. Le fichier ne se lit pas : traitement de BR-003.

## Hors périmètre

Écrans définitifs (maquettes MPL-016), recherche, tri, filtres, playlists, SSD et pochettes (MPL-037), notification et arrière-plan (MPL-036).

## As-built

MPL-018, 2026-10-15. Écran temporaire `lib/features/library/library_page.dart` et barre de lecture `player_bar.dart`, en attendant les maquettes de MPL-016 ; état dans `library_controller.dart`. Tests : `test/features/library/`.

- Les signalements du lecteur (pistes sautées, échec, arrêt) s'affichent dans une barre de message en bas de l'écran.
- Non testé sur appareil.
