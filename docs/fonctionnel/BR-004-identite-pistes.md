# BR-004 — Identité et persistance des pistes

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-018 · **Décisions :** D23 · **Lié :** FR-003

## Règle

1. Une piste est identifiée par (disque, chemin relatif au disque). Deux pistes de la bibliothèque n'ont jamais la même identité.
2. Une réindexation garde l'identité interne d'une piste dont le fichier est toujours là, même si ses informations changent : ce qui s'y rattachera plus tard (playlists, favoris, statistiques) n'est pas perdu.
3. Un fichier déplacé ou renommé est une nouvelle piste ; l'ancienne est retirée.
4. Le disque du stockage interne a un identifiant fixe, qui ne dépend d'aucun numéro de série ni d'aucun UUID de volume.
5. Pistes d'un disque absent : elles restent dans la bibliothèque, grisées (D23). Sans objet pour le stockage interne, toujours présent ; s'applique aux disques amovibles (MPL-037).

## As-built

MPL-018, 2026-10-15. Identifiant fixe du stockage interne : `internal` (`internalDisk`, `lib/domain/library/model/library_track.dart`). Règles 1 à 3 dans `DriftLibraryRepository.applyIndex` (`lib/data/db/drift_library_repository.dart`), unicité (`disk_id`, `relative_path`) en base. Tests : `test/data/db/drift_library_repository_test.dart`.
