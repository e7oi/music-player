# ADR-009 — Lecture des tags et des pochettes dans les fichiers

**Statut :** Active (validée le 2026-10-22) · **Date :** 2026-10-22 · **Ticket :** MPL-037 · **Décisions :** D27, D30 · **Fiches :** FR-007, BR-006 · **Complète :** ADR-004, ADR-008

## Contexte

MediaStore donne les tags du stockage interne, mais ni ceux du SSD ni les pochettes. Il faut les lire dans les fichiers, en arrière-plan, sur 10 000 pistes, sans bloquer la lecture ni garder de descripteur ouvert (BR-006).

## Décision

- **Lecteur** : `MediaMetadataRetriever` d'Android, côté natif, pour les tags et la pochette intégrée (`embeddedPicture`). Il ne demande aucune dépendance et lit les formats courants (MP3, FLAC, M4A, OGG, Opus, WAV). Le prototype a mesuré environ 39 ms par fichier avec une méthode équivalente. Il lit WMA de façon inégale : une piste en échec reste lisible par le moteur (FR-007.5).
- Alternative notée, non retenue : un paquet Dart qui lit les tags. Elle ajouterait une dépendance à vérifier (D30) pour un gain non démontré. À réétudier si la mesure sur le Pixel montre des formats mal lus.
- **Mesure à faire au début du ticket** : débit sur le SSD (fichiers par seconde) avec 1, 2 et 4 lectures parallèles, et effet sur une lecture en cours. La plus petite valeur qui tient le débit visé devient la limite de BR-006.4.
- **Port** `TagReader` dans `domain/library/ports/` : à partir d'une piste (disque, chemin relatif), rend ses tags et sa pochette ; annulable. Adaptateur natif sous `platform/`. Fake dans `test/`.
- **Service du domaine** `TagIndexer` : file des pistes en attente, groupes d'écriture, reprise, état par piste, annulation (BR-006.5). Test d'abord.
- **Pochettes** : le côté natif réduit l'image (côté le plus long 512 pixels), l'encode en JPEG et la rend à Dart ; Dart calcule l'empreinte du contenu, enregistre le fichier sous ce nom dans le dossier privé `files/artwork/` de l'application s'il n'existe pas, et note son identifiant dans la table `artworks` (`id`, `hash`, `file`), schéma v2 (ADR-008) avec `tracks.artwork_id`. Le dossier est reconstructible : le perdre relance la lecture, sans perte de bibliothèque.
- La suppression d'une piste libère la pochette qui n'est plus utilisée (FR-007.10), dans la même transaction de base ; le fichier est effacé ensuite.
- **Affichage** : `Image.file` avec décodage à la taille voulue (`cacheWidth`) ; image de remplacement pour une piste sans pochette. Rien d'autre (maquettes MPL-016).

## Conséquences

- Pochettes et tags sont des données de l'appareil : jamais dans le dépôt ni dans les journaux (D27). Les tests utilisent des fichiers audio synthétiques.
- Taille estimée : environ 50 à 100 Ko par pochette distincte ; l'encombrement réel est mesuré avec le test à 10 000 pistes.
- L'APK ne change pas de taille : pas de nouvelle dépendance.

## Alternatives examinées

- Pochettes de MediaStore (`loadThumbnail`) pour le stockage interne seulement : deux mécanismes, et rien pour le SSD. Écarté.
- Pochettes dans la base (BLOB) : gonfle la base et `watchTracks()`. Écarté.

## Écarts constatés à la livraison (À valider, PO)

- Voir les écarts ci-dessus.

## As-built

MPL-037, 2026-10-22. `FileTagsChannel.kt` / `lib/platform/file_tags_channel.dart`, `TagIndexer`, `TrackArtwork`.

Écarts avec la section Décision ci-dessus :
- Pas de table `artworks` ni de colonne `artwork_id` : `tracks.artwork` contient l'empreinte SHA-1 de l'image intégrée ; l'empreinte, la réduction et l'écriture du fichier sont faites par le Kotlin (pas de dépendance Dart de hachage).
- Pas d'annulation d'une lecture en cours : l'annulation joue entre deux fichiers.
- Le nettoyage des images est fait à la fin d'une passe complète, pas dans la transaction de suppression.
- Chaque appel natif répond même en cas d'`Error` (décodage d'une image trop grande).
- Mesures du 2026-10-23 (Pixel 10 Pro) : à 2 lectures en parallèle, environ 38 fichiers par seconde sur le SSD (4 952 fichiers en environ 2 min) et 50 sur le stockage interne ; 202 images pour 7,4 Mo (environ 37 Ko chacune) pour 7 562 pistes. **Non faites** : 1 et 4 lectures en parallèle, effet sur une lecture en cours ; `parallelism` reste à 2.
