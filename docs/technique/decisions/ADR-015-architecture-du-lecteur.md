# ADR-015 — Architecture du lecteur : modes dans le contrôleur, position séparée, lecteur en page, file en feuille

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-047 · **Décisions :** D2, D15, D30 · **Fiches :** UC-007, FR-016, FR-017, FR-018, FR-019, BR-009 · **Complète :** ADR-002, ADR-006, ADR-010, ADR-013

## Contexte

La barre de lecture actuelle (`features/library/player_bar.dart`) lit la liste complète des pistes à chaque émission pour retrouver la piste courante et se reconstruit à chaque changement d'état du contrôleur, position comprise. Le lot Lecture demande un mini-lecteur dans la coquille, un lecteur plein écran, une file qui se réordonne et deux modes (aléatoire, répétition) que le contrôleur n'a pas. Les files viennent de la liste : elles comptent jusqu'à 7 562 pistes.

## Décision

- **Modes et file dans le contrôleur** (`domain/playback/`). `PlayerController` reçoit `setShuffle`, `setRepeat`, `move(from, to)`, `clearUpcoming()`, `skipTo(index)`, `playNext(tracks)` et `enqueue(tracks)` (le retrait existe : `removeAt`, FR-002), avec les règles de BR-009, testées d'abord. `PlayerState` gagne `shuffle` et `repeat` (`RepeatMode { off, all, one }`). L'ordre d'origine de l'aléatoire reste dans le contrôleur, pas dans l'état. Le **mélange déplace physiquement** les pistes de la suite : la file affichée est la file jouée.
- **Port du moteur inchangé.** « Une piste » recharge la piste par le chemin de chargement habituel ; pas de mode boucle du moteur (ADR-002 : le contrôleur reste indépendant du moteur).
- **Position séparée.** Un fournisseur dérivé du flux d'états donne la position seule, limité à 4 mises à jour par seconde avec `throttle` (`app/providers/`) ; le mini-lecteur et le curseur le regardent, pas l'état entier. Titre, pochette et boutons ne se redessinent pas à chaque tic.
- **Informations de la piste par index.** Le mini-lecteur et le lecteur retrouvent la piste courante par `libraryTrackIndexProvider` (déjà utilisé par la notification), pas par la liste complète : cela règle aussi le reste de MPL-045 (« la barre de lecture n'est pas limitée à deux émissions par seconde »).
- **Fournisseurs de session** dans `features/player/` (comme les pistes illisibles de ADR-013) : provenance de la file (« Pistes · Titre A→Z »), écrite là où la file est créée ; cause de l'arrêt (éjection, échecs), alimentée par les `PlaybackNotice` et effacée à la prochaine lecture.
- **Organisation.** `ui/widgets/` : `MiniPlayer` et les petits composants du lecteur (bouton à bascule avec point d'état), sans domaine ni Riverpod (ADR-010) ; `features/player/` : page du lecteur, feuille de la file (retrait par glissé latéral), menu d'appui long de la liste (FR-019), modèles de vue purs (informations de la piste, ligne de métadonnées, lignes de la file avec durée totale en cache), tests d'abord. `player_bar.dart` disparaît ; la coquille monte `MiniPlayer`.
- **Navigation sans routeur.** Le lecteur est une page poussée avec `Navigator.push` (transition personnalisée, `Hero` sur la pochette, balise unique), fermée par `pop` : le geste Retour fonctionne sans code. Le glissé vers le bas est un geste vertical maison, sans dépendance, abandonné s'il est fragile. La file est `showModalBottomSheet` avec `DraggableScrollableSheet` et une liste réordonnable construite à la demande (`ReorderableListView.builder` du SDK), qui ne montre que la suite.
- **Notification inchangée.** `PlayerAudioHandler` n'est pas modifié : pas d'actions aléatoire/répétition ni de nom de source (voir À valider).
- **Aucune dépendance nouvelle.**

## Conséquences

- Le contrôleur change de manière visible (état et API), sur la partie la plus testée du projet : les tests existants doivent rester verts sans modification ; les nouveaux groupes sont « BR-009 ».
- La coquille perd la barre provisoire (FR-009.5, as-built à mettre à jour) ; le bouton « En cours » reste à 16 dp au-dessus du mini-lecteur sans changement (FR-013.6).
- Le Kotlin n'est pas touché : pas de nouvelle procédure native, mais `HOWTO.md` gagne une procédure d'essai (§17).
- Le mélange et le déplacement sur une file de 7 500 pistes coûtent O(n) : négligeable ; la mesure se fait sur l'appareil.

## Alternatives examinées

- Aléatoire par permutation d'indices, file d'origine intacte : plus pur, mais la feuille de la file et les déplacements manuels demandent alors une traduction entre deux ordres. Écartée au profit du mélange physique.
- Mode boucle du moteur (`media_kit` en `loop`) : lie le contrôleur au moteur et contourne BR-001 et BR-003. Écartée.
- Passer la file à `audio_service` (file de la session média) : la file reste celle du contrôleur (ADR-006). Écartée.
- `go_router` pour `/player` : écarté par ADR-010.
- Paquet de glissé pour fermer ou de feuille : dépendance pour un seul geste (D30). Écartée.

## À valider (PO)

- Le mélange physique plutôt qu'une permutation (ci-dessus).
- Pas d'actions aléatoire/répétition dans la notification (conception, écran 7) ni de nom de source dans le sous-titre de la session : `HANDOFF.md` §9 laisse « à décider (MPL-047) ». Ma recommandation : non dans ce ticket, la notification est validée sur le Pixel (MPL-036) et la source se voit dans l'application ; à reprendre si le propriétaire le veut.
- Le nouveau dossier `lib/features/player/` et les composants de `ui/widgets/` (règles d'import déjà couvertes par ADR-010).

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). Réalisé comme décidé, avec ces précisions : `PlayerState.entryIds` (identifiant stable par entrée de la file) a été ajouté pour les clés des lignes de la file ; `RepeatMode` est caché de `package:flutter/material.dart` (`hide RepeatMode`) là où les deux sont importés ; `trackIndexProvider` (`features/player/player_session.dart`) lit la liste limitée à deux émissions par seconde, et non `libraryTrackIndexProvider` de la notification. Le glissé vers le bas pour fermer le lecteur est un simple détecteur de geste. La notification n'est pas modifiée.
