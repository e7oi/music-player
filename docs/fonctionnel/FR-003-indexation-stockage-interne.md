# FR-003 — Indexation du stockage interne

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-018 · **Décisions :** D3, D23, D25 · **Lié :** BR-004, UC-001 · **Révisée le 2026-10-15 :** choix des dossiers (demande du propriétaire)

## Besoin

La bibliothèque contient les pistes du stockage interne, avec leurs informations, et reste à jour quand des fichiers sont ajoutés, modifiés ou supprimés.

## Exigences

1. Source : MediaStore, volume du stockage interne, fichiers marqués comme musique (D25), **limités aux dossiers choisis par l'utilisateur** (D23) : les sonneries, notes vocales et sons reçus par les messageries hors de ces dossiers ne sont pas indexés.
2. Choix des dossiers : l'application liste les dossiers du stockage interne qui contiennent de l'audio d'après MediaStore, avec le nombre de fichiers de chacun ; l'utilisateur coche ceux à indexer. Un dossier coché inclut ses sous-dossiers. Aucune autorisation supplémentaire, pas de sélecteur Android (SAF) pour le stockage interne.
3. Premier lancement : après l'autorisation (FR-004), la liste des dossiers s'affiche avec le dossier standard `Music/` coché s'il existe ; l'utilisateur confirme ou change le choix avant la première indexation.
4. Le choix se modifie à tout moment (entrée « Dossiers »). Décocher un dossier retire ses pistes de la bibliothèque ; cocher un dossier lance l'indexation.
5. Informations conservées par piste : chemin relatif (identité, BR-004), titre, artiste, album, artiste de l'album, numéro de piste, numéro de disque, année, genre, durée, taille, date de modification. Une information absente reste vide ; le titre absent est remplacé à l'affichage par le nom du fichier.
6. Les informations viennent de MediaStore, sans lecture des tags dans les fichiers.
7. L'indexation a lieu à chaque démarrage et sur demande de l'utilisateur (« Actualiser »). Elle compare le résultat à la base : pistes ajoutées, modifiées (date de modification ou taille changée), supprimées.
8. Une piste dont le fichier a disparu du stockage interne est retirée de la bibliothèque. Ce n'est pas un disque absent : le stockage interne est toujours présent (BR-004).
9. L'indexation se fait hors du fil de l'interface : l'écran reste utilisable et la liste se met à jour quand elle se termine.
10. Le stockage interne est enregistré comme un disque (D23), nommé « Local » dans l'interface.

## Hors périmètre

SSD, lecture des tags dans les fichiers et pochettes (MPL-037), recherche, test à 10 000 pistes (MPL-037), réindexation automatique pendant que l'application tourne.

## À valider

- Garde-fou contre un résultat vide de MediaStore (voir as-built) : il empêche aussi de vider la bibliothèque quand tous les fichiers audio du téléphone ont vraiment été supprimés. À confirmer.

## As-built

MPL-018, 2026-10-15. `LibraryIndexer` (`lib/domain/library/services/library_indexer.dart`), canal MediaStore (`android/.../MediaStoreChannel.kt`, `lib/platform/media_store_channel.dart`), base Drift (ADR-004). Tests : `test/domain/library/`, `test/data/db/`, `test/platform/`, `test/features/library/`.

- Les dossiers proposés sont ceux du premier niveau du stockage interne (`Music`, `Download`, `Android`…), chacun avec ses sous-dossiers ; les fichiers posés à la racine forment une entrée « Racine du stockage ». Ce choix garde la liste courte, au prix de ne pas pouvoir séparer deux sous-dossiers d'un même dossier.
- Une piste est mise à jour quand l'une de ses informations change, pas seulement sa taille ou sa date.
- Un échec de l'indexation affiche un bandeau avec « Actualiser » ; la bibliothèque enregistrée reste affichée.
- Garde-fou : si MediaStore ne renvoie aucun fichier audio alors que la bibliothèque contient des pistes du stockage interne, l'indexation échoue au lieu de tout supprimer (exigence 8 non appliquée dans ce cas). Une réanalyse des médias après une mise à jour d'Android peut donner ce résultat un court moment, et supprimer les pistes ferait perdre leur identité (BR-004). Voir « À valider ».
- Le bouton « Dossiers » est désactivé pendant une indexation ; la barre de lecture reste visible pendant le choix des dossiers.
- Une lecture impossible de la liste des dossiers affiche un message avec « Réessayer ».
- Non testé sur appareil.
