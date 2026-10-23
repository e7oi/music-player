# FR-006 — Indexation d'un disque amovible par le sélecteur Android (SAF)

**Statut :** Active (validée le 2026-10-22) · **Créée le :** 2026-10-22 · **Ticket :** MPL-037 · **Décisions :** D23, D25 · **Lié :** UC-003, FR-003, FR-007, BR-001, BR-004, BR-006 · **Complète :** FR-003 (stockage interne)

## Besoin

La bibliothèque contient aussi les pistes des dossiers choisis sur un disque amovible, que MediaStore n'indexe pas (D25). Elle reste à jour, et le disque absent est géré sans perte.

## Exigences

1. Ajout : l'utilisateur ajoute un dossier d'un disque amovible depuis « Dossiers » par le sélecteur de dossiers d'Android. Un disque peut avoir plusieurs dossiers choisis ; une même demande d'accès couvre un dossier et ses sous-dossiers.
2. Droit d'accès : l'application garde le droit en lecture seule d'une session à l'autre (droit persistant d'Android). Elle ne demande jamais d'écriture. Décocher un dossier libère son droit.
3. Identité du disque : l'UUID du système de fichiers du volume (BR-004, D23). Le chemin relatif d'une piste est relatif à la **racine du volume**, comme pour le stockage interne, et non au dossier choisi : choisir un dossier parent plus tard ne change pas l'identité des pistes déjà indexées.
4. Nom du disque : le nom donné par Android au volume, gardé dans la base de l'appareil. Aucun renommage dans ce ticket.
5. Parcours : l'application liste les fichiers du dossier choisi et de ses sous-dossiers, hors du fil de l'interface, avec le nom, la taille, la date de modification et le type de chaque fichier.
6. Fichiers retenus : fichiers audio reconnus par leur type ou, à défaut, par l'extension (`mp3`, `flac`, `m4a`, `aac`, `ogg`, `opus`, `wav`, `wma`). Ignorés : les fichiers dont le nom commence par `._` (fichiers de métadonnées écrits par macOS sur exFAT), les dossiers dont le nom commence par `.`, et les dossiers qui contiennent un fichier `.nomedia`, comme le fait MediaStore pour le stockage interne.
7. Les pistes sont enregistrées dès la fin du parcours, avec le nom du fichier comme titre et sans tags (FR-007 prend la suite) ; elles sont lisibles tout de suite.
8. Actualisation : à chaque démarrage où le disque est monté et sur demande (« Actualiser »), le parcours est refait et comparé à la base : pistes ajoutées, modifiées (date ou taille changée), supprimées (BR-004). Une piste modifiée est de nouveau mise en attente de lecture de tags (FR-007).
9. Garde-fou (comme FR-003, exigence 8) : un parcours incomplet (disque débranché, erreur d'entrée-sortie, accès perdu) ou qui ne trouve aucun fichier alors que le disque a des pistes échoue, et ne supprime rien.
10. Disque absent : un disque qui n'est pas monté est indisponible ; ses pistes restent, grisées, et sont sautées pendant la lecture avec un message (BR-001, BR-004 règle 5, D23). Au retour du disque, il redevient disponible sans nouveau choix de dossier. Dans ce ticket, la disponibilité est lue au démarrage et au retour au premier plan ; le suivi en direct de l'éjection est MPL-035.
11. Accès perdu : si le disque est monté mais que le droit accordé n'est plus valable (réinstallation, droit retiré, disque reformaté), le disque est signalé « accès à renouveler » et un bouton rouvre le sélecteur. Ce n'est pas un disque absent et les pistes ne sont pas retirées.
12. Lecture d'une piste : l'application ouvre le fichier avec Android, détache le descripteur et le donne au moteur sous la forme `fd://N` (D25, `CLAUDE.md`). Jamais de `content://` direct ni de `/proc/self/fd/N`. Règles de fermeture : BR-006.
13. Informations conservées par piste : celles de FR-003.5. Le volume du disque, son UUID et les chemins ne sont enregistrés que dans la base de l'appareil, jamais dans le dépôt (D27).
14. Le parcours n'a lieu que l'application ouverte au premier plan ; il reprend au lancement suivant s'il a été coupé.
15. L'avancement du parcours et de la lecture des tags (nombre de fichiers trouvés, nombre de pistes lues) est visible dans la liste.

## Hors périmètre

Réassociation et retrait d'un disque (MPL-038), suivi en direct de l'éjection (MPL-035), indexation en service au premier plan quand l'application est fermée, renommage du disque.

## À valider (PO)

- Exigence 6 : `.nomedia` et noms en `.` ignorés comme MediaStore, et `._*` ignorés (cas typique d'un SSD partagé avec un Mac). Liste d'extensions à confirmer, WMA compris (D16).
- Exigence 10 : sans écouteur natif (MPL-035), retirer le SSD pendant un parcours peut faire tuer l'application par Android (BR-002, contexte). Proposition : l'accepter jusqu'à MPL-035, le parcours étant repris au lancement suivant, et le noter dans `HOWTO.md`.
- Exigence 14 : parcours uniquement au premier plan (pas de service au premier plan dédié).
- Comment obtenir l'UUID du volume à partir du dossier choisi : à établir sur le Pixel au début du ticket (ADR-008).

## Écarts constatés à la livraison (À valider, PO)

- Exigence 6 : le code ignore tout nom qui commence par `.`, fichiers compris (`.x.mp3`), pas seulement `._*` ; plus strict que la fiche.
- Exigence 15 : seule la progression des tags est affichée ; le parcours montre une barre indéterminée sans nombre de fichiers trouvés.
- Exigence 12 et ADR-008 : voir les écarts de l'ADR.

## As-built

MPL-037, 2026-10-22. `RemovableIndexer` (domaine), port `RemovableAudioSource`, adaptateur `lib/platform/removable_storage_channel.dart`, Kotlin `RemovableStorageChannel.kt`, base : `applyScan`, `trackCount` (`lib/data/db/drift_library_repository.dart`). Tests : `test/domain/library/removable_indexer_test.dart`, `test/data/db/`, `test/platform/removable_storage_channel_test.dart`.

- Le chemin relatif d'une piste est celui du document Android (`UUID:chemin`, sans le préfixe) : relatif à la racine du volume (exigence 3). L'identifiant du disque garde la casse donnée par Android ; le Kotlin compare sans tenir compte de la casse et construit les identifiants de document avec l'écriture du droit accordé.
- Aucune URI n'est enregistrée : Android garde les droits (`persistedUriPermissions`), et l'état « accès à renouveler » vient de leur absence.
- Garde-fou (exigence 9) : un parcours qui échoue, qui est annulé, qui reçoit une erreur du fournisseur dans le curseur, ou qui ne trouve rien alors que le disque a des pistes, ne change rien.
- Le retrait d'un dossier scanne d'abord les dossiers restants ; si le parcours échoue, le dossier reste coché et son droit est gardé. Il est désactivé pour un disque absent.
- Choisir de nouveau un dossier déjà coché et devenu vide ne libère pas son droit.
- Le nom du disque est mis à jour à chaque ajout de dossier (exigence 4).
- « Actualiser » relit aussi les pistes dont la lecture avait échoué (FR-007.3) ; le démarrage non.
- Le parcours est un seul appel qui rend la liste entière.
- **Non testé sur appareil** : sélecteur, UUID, droit persistant, curseur à l'éjection (HOWTO §13).
