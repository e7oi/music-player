# ADR-008 — Disque amovible par SAF : canal natif, ports et schéma v2

**Statut :** Active (validée le 2026-10-22) · **Date :** 2026-10-22 · **Ticket :** MPL-037 · **Décisions :** D23, D25, D30 · **Fiches :** UC-003, FR-006, BR-004, BR-006 · **Complète :** ADR-002, ADR-004, ADR-005

## Contexte

Le SSD n'est visible que par le sélecteur Android (D25). Le prototype a établi : droit persistant, lecture par `fd://`, parcours + tags à environ 39 ms par fichier. MPL-037 en fait la source réelle de la bibliothèque, sans enfreindre les règles de dépendance de `CLAUDE.md` (canaux sous `platform/`, Kotlin sous `android/`, base sous `data/db/`).

## Décision

- **Canal natif** `net.trtl3.tuneshell/removable_storage`, sur le modèle de `MediaStoreChannel` (ADR-005), créé avec le moteur de `TuneShellApplication` (ADR-006). Méthodes : choix d'un dossier (sélecteur `ACTION_OPEN_DOCUMENT_TREE`, droit persistant en lecture seule), liste des droits gardés, libération d'un droit, volumes montés (UUID, nom), parcours d'un dossier, ouverture d'un fichier en `fd://N`.
- **Parcours** par `DocumentsContract.buildChildDocumentsUriUsingTree` et `ContentResolver.query` (un appel par dossier, colonnes nom, type, taille, date). Pas de `DocumentFile`, trop lent (une requête par fichier). Exécuté hors du fil principal Android, résultat renvoyé par lots à Dart.
- **UUID du volume** : déduit de l'identifiant du dossier choisi (partie avant le `:`), recoupé avec `StorageManager.getStorageVolumes()`. **À établir sur le Pixel** avec le SSD (exFAT) avant d'écrire le reste ; si l'UUID ne se déduit pas, retour à `/cadrer` plutôt que de choisir un autre identifiant.
- **Ports** (Dart pur, fakes dans `test/`) :
  - `RemovableAudioSource` dans `domain/library/ports/` : choisir un dossier, lister les droits, parcourir un dossier (flux de lots de `TrackInfo` sans tags, annulable), libérer un droit.
  - `VolumeEvents` (ADR-002) : `availableDisks()` rend aussi les disques amovibles montés ; le flux d'événements reste vide jusqu'à MPL-035.
  - `TrackSourceOpener` : adaptateur du disque amovible, qui ouvre en `fd://N` (D25).
- **Service du domaine** `RemovableIndexer` dans `domain/library/services/`, à côté de `LibraryIndexer`, et même garde-fou (FR-006.9) ; il écrit par `LibraryRepository.applyIndex`.
- **Schéma v2** (migration testée à partir du dump v1, `drift_schemas/`) :
  - `disk_folders` : colonne `tree_uri` (nullable ; le dossier du stockage interne n'en a pas). L'URI contient l'UUID du volume : elle ne vit que dans la base de l'appareil (D27).
  - `tracks` : colonnes `tags_state` (en attente / lus / échec, FR-007.3) et `artwork_id` (nullable, ADR-009). Les pistes du stockage interne existantes passent à `tags_state` « lus ».
  - `disks.label` renseigné par le nom du volume.
- `PlayerController` ne change pas : il connaît les disques disponibles (BR-001).
- Les écritures en base du parcours et des tags se font par lots (FR-007.9), car `watchTracks()` rend toute la liste à chaque changement.

## Conséquences

- Code Kotlin de liaison sans test unitaire (exception de `CLAUDE.md`) : procédure dans `HOWTO.md`, résultat « testé » ou « non testé ».
- Le nombre de droits persistants par application est limité par Android (128 environ depuis Android 11) : suffisant, à noter dans `HOWTO.md`.
- Sans MPL-035, le retrait du SSD pendant un parcours peut tuer l'application (FR-006, À valider) ; le parcours est repris au lancement suivant.

## Alternatives examinées

- `DocumentFile.listFiles()` : une requête par fichier, bien plus lent sur un grand dossier. Écarté.
- Paquet Flutter de sélection de dossier SAF : maintenance non vérifiée, besoin couvert par quelques méthodes natives (même raisonnement qu'ADR-005). Écarté.
- Une seule racine par disque : plus simple, mais impose de choisir toute la racine du SSD. Plusieurs dossiers par disque gardés, comme pour le stockage interne (FR-003).

## Écarts constatés à la livraison (À valider, PO)

- Voir les écarts ci-dessus (`tree_uri`, état des pistes internes, lots).

## As-built

MPL-037, 2026-10-22. Canal `net.trtl3.tuneshell/removable_storage` (`RemovableStorageChannel.kt`, `lib/platform/removable_storage_channel.dart`), enregistré par `TuneShellApplication`, activité attachée par `MainActivity` (résultat du sélecteur). Schéma v2 (`drift_schemas/library/drift_schema_v2.json`), migration par `stepByStep` testée depuis v1.

Écarts avec la section Décision ci-dessus :
- Pas de colonne `disk_folders.tree_uri` : les droits restent chez Android et se retrouvent par `persistedUriPermissions` (aucune URI dans la base, D27).
- Les pistes du stockage interne existantes passent « en attente » (et non « lues »), pour lire leurs pochettes (ADR-009).
- Le parcours rend la liste en un seul appel, pas des lots.
- L'UUID vient de l'identifiant de document du dossier choisi ; `StorageManager` sert au nom du volume et à la liste des volumes montés, avec un repli par requête sur les dossiers accordés. L'UUID a été établi sur le SSD réel le 2026-10-23 (Samsung T7, exFAT) : `sm list-volumes` le montre et il se déduit de l'identifiant du dossier choisi, comme prévu.
- `VolumeEvents` gagne `refresh()`, appelé au démarrage et au retour au premier plan ; il annonce `VolumeMounted` et `VolumeRemoved`.
- Le parcours et les clients de l'identifiant (`grantedFolders`, `mountedVolumes`) ont des threads différents : l'état des disques se met à jour pendant un long parcours.
- Une erreur du fournisseur de documents dans le curseur est un échec du parcours.
