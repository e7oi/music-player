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

## As-built

Néant (non implémenté).
