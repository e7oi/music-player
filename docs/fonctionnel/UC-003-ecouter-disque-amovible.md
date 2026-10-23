# UC-003 — Ajouter un disque amovible et écouter ses pistes

**Statut :** Active (validée le 2026-10-22) · **Créée le :** 2026-10-22 · **Ticket :** MPL-037 · **Décisions :** D23, D25 · **Lié :** FR-006, FR-007, BR-001, BR-004, BR-006, UC-001

## Acteur et but

L'utilisateur veut retrouver dans la bibliothèque la musique de son SSD branché en USB-C, avec les titres, artistes, albums et pochettes de ses fichiers, et l'écouter comme celle du téléphone.

## Préconditions

- L'application a déjà son accès aux fichiers audio (UC-001, FR-004).
- Un disque amovible est branché et monté par Android ; Android ne le montre pas aux applications autrement que par son sélecteur de dossiers (D25).

## Scénario nominal

1. L'utilisateur ouvre l'entrée « Dossiers » et choisit d'ajouter un dossier d'un disque amovible.
2. L'application ouvre le sélecteur de dossiers d'Android ; l'utilisateur choisit un dossier du SSD et accorde l'accès (FR-006).
3. L'application enregistre le disque et le dossier. Le droit d'accès est conservé : l'utilisateur ne le redonne ni au prochain lancement ni après un redémarrage du téléphone.
4. L'application parcourt le dossier. Les pistes apparaissent dans la liste, avec le nom de fichier comme titre, sans attendre la lecture des tags (FR-006).
5. En arrière-plan, l'application lit les tags et les pochettes dans les fichiers ; les titres, artistes et pochettes remplacent peu à peu les noms de fichiers (FR-007).
6. L'utilisateur touche une piste du SSD : la lecture démarre comme pour une piste du téléphone (FR-001, FR-006).

## Variantes

- 2a. L'utilisateur annule le sélecteur : rien ne change.
- 2b. Le dossier choisi ne contient aucun audio : un message l'indique, le disque n'est pas enregistré.
- 4a. Le SSD est débranché pendant le parcours : le parcours échoue avec un message, la bibliothèque est gardée (FR-006).
- 5a. L'application est fermée pendant la lecture des tags : elle reprend où elle s'était arrêtée au lancement suivant (FR-007).
- 6a. Le SSD est absent : ses pistes sont grisées et sautées pendant la lecture (BR-001, BR-004 règle 5).
- 6b. Le SSD est monté mais l'accès accordé n'est plus valable : l'application demande de rechoisir le dossier (FR-006).

## Hors périmètre

Réassociation d'un nouveau disque et retrait d'un disque de la bibliothèque (MPL-038), écouteur natif d'éjection (MPL-035), recherche, tri, écrans définitifs (MPL-016).

## As-built

À écrire à la livraison de MPL-037.
