# FR-007 — Tags et pochettes lus dans les fichiers

**Statut :** Active (validée le 2026-10-22) · **Créée le :** 2026-10-22 · **Ticket :** MPL-037 · **Décisions :** D23 · **Lié :** UC-003, FR-003, FR-006, BR-004, BR-006

## Besoin

Les pistes des disques amovibles ont des titres, artistes, albums et durées, comme celles du téléphone, sans bloquer l'écran ni la lecture. Les pistes des deux sources ont leur pochette.

## Exigences

1. Pistes d'un disque amovible : les tags (FR-003.5) sont lus dans les fichiers, en arrière-plan, après l'enregistrement des pistes (FR-006.7). Une information absente reste vide. Le titre absent est remplacé à l'affichage par le nom du fichier.
2. Pistes du stockage interne : les tags restent ceux de MediaStore (FR-003.6), sans lecture des fichiers ; seules les pochettes sont lues dans les fichiers.
3. Chaque piste d'un disque amovible a un état de lecture des tags : en attente, lus, échec. Une piste en attente ou modifiée (FR-006.8) est lue ; une piste en échec n'est pas relue à chaque démarrage, seulement si le fichier change ou sur « Actualiser ».
4. La lecture reprend à son état après une fermeture de l'application ou un débranchement : seules les pistes en attente sont lues.
5. Une piste illisible (fichier corrompu, format sans tags) passe en échec et reste lisible par le moteur ; elle garde le nom du fichier comme titre. Elle ne bloque pas la suite.
6. Pochette : l'image intégrée au fichier, quand il y en a une. Elle est réduite (côté le plus long 512 pixels au plus), enregistrée en JPEG dans le dossier privé de l'application, une seule fois par image identique (même contenu). Les pistes d'un même album n'enregistrent donc pas l'image plusieurs fois. Pas de fichier `cover.jpg` ou équivalent dans le dossier (voir À valider).
7. Une piste sans pochette en a une marque « sans pochette », l'interface affiche une image de remplacement.
8. Pochettes du stockage interne : lues dans les fichiers avec le même mécanisme, en arrière-plan, après l'indexation de MediaStore (FR-003). Une piste du stockage interne dont le fichier change est relue.
9. L'écran reste utilisable. Les mises à jour de la base sont groupées (par lots), pour que la liste ne se redessine pas à chaque piste.
10. Retirer une piste de la bibliothèque (BR-004) libère sa pochette si plus aucune piste ne l'utilise. Retirer le dossier ou la piste ne laisse pas de fichier orphelin.
11. La liste et la barre de lecture affichent la pochette de la piste (affichage temporaire, en attendant les maquettes MPL-016).
12. Les règles de descripteurs de BR-006 s'appliquent à chaque fichier ouvert pour lire un tag ou une pochette.

## Hors périmètre

Écrans définitifs et grille d'albums (MPL-016), pochettes en ligne (MPL-029), tags modifiables, pochettes de dossier.

## À valider (PO)

- Exigence 6 : pas de `cover.jpg` ou `folder.jpg` du dossier. À confirmer, à ajouter plus tard sinon.
- Pochette dans la notification et l'écran verrouillé (MPL-036 l'excluait) : à inclure dans ce ticket, ou plus tard ?
- Taille de 512 pixels : à confirmer avec les maquettes (MPL-016).

## Écarts constatés à la livraison (À valider, PO)

- L'exigence 10 dit que retirer une piste libère sa pochette ; le code la libère à la fin de la passe suivante.
- Pochette de la notification et de l'écran verrouillé : non faite dans ce ticket.

## As-built

MPL-037, 2026-10-22. `TagIndexer` (`lib/domain/library/services/`), port `TagReader`, adaptateur `lib/platform/file_tags_channel.dart`, Kotlin `FileTagsChannel.kt`, base `applyFileTags`, `pendingTracks`, `resetFailedTags`. Affichage : `track_artwork.dart` (liste et barre de lecture). Tests : `test/domain/library/tag_indexer_test.dart`, `test/data/db/drift_library_repository_test.dart`.

- Lecteur : `MediaMetadataRetriever`. L'image intégrée est identifiée par le SHA-1 de ses octets, réduite à 512 pixels (côté le plus long), enregistrée en JPEG qualité 85 sous `files/artwork/<empreinte>.jpg`, une fois par image distincte. Aucune image n'est enregistrée si le fichier de destination n'existe pas à la fin.
- Une lecture qui échoue parce que le disque ou son accès a disparu laisse la piste « en attente » et termine la passe ; une piste n'est « en échec » que si son disque est encore là.
- Les pistes en échec sont relues sur « Actualiser » (`run(retryFailed: true)`), pas au démarrage.
- Les pistes du stockage interne existantes passent « en attente » à la migration : leur pochette est lue au premier lancement qui suit.
- Le nettoyage des images inutilisées a lieu à la fin d'une passe complète (pas dans la transaction de suppression) ; il n'a pas lieu si la passe est annulée ou interrompue.
- **Non testé sur appareil** : lecture réelle, pochettes, WMA, 10 000 pistes, place des pochettes.
