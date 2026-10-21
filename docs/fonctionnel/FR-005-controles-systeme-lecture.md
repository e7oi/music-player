# FR-005 — Lecture en arrière-plan et contrôles du système

**Statut :** Active (validée le 2026-10-21) · **Créée le :** 2026-10-21 · **Ticket :** MPL-036 · **Décisions :** D2, D12, D14 · **Lié :** UC-002, FR-001, BR-005

## Besoin

La lecture continue quand l'application n'est plus à l'écran, et Android la commande comme celle de tout lecteur de musique : notification, écran verrouillé, lecteur des réglages rapides, touches média.

## Exigences

1. Pendant la lecture, l'application tourne comme service au premier plan de type « lecture de média » : la lecture continue, piste après piste, écran verrouillé, application en arrière-plan ou fermée par le geste de retour, téléphone débranché.
2. Une notification de lecture (canal « Lecture ») montre le titre de la piste (ou le nom du fichier, FR-003), l'artiste et l'album quand ils sont connus, et les commandes : piste précédente, lecture/pause, piste suivante, arrêt, ainsi qu'une barre de progression qui permet de se déplacer dans la piste. La commande « arrêt » est présente (validé par le propriétaire le 2026-10-21) ; Android peut ne pas l'afficher dans le lecteur compact.
3. L'écran verrouillé et le lecteur des réglages rapides montrent la même piste et les mêmes commandes.
4. Les touches média (casque filaire, casque Bluetooth, montre) commandent lecture/pause, piste suivante et piste précédente.
5. Toutes ces commandes passent par le `PlayerController` et suivent ses règles (FR-001), par exemple « précédent » après 3 s qui reprend la piste au début. L'état affiché par le système suit celui du contrôleur : piste, lecture ou pause, position, durée.
6. En pause, la notification reste affichée mais l'utilisateur peut la balayer ; Android peut alors arrêter l'application au bout d'un moment.
7. Arrêt (commande « arrêt », fin de la file, éjection du disque de la piste, BR-002) : la notification disparaît et le service s'arrête.
8. Retrait de l'application des applications récentes : pendant la lecture, la lecture continue ; en pause ou à l'arrêt, l'application s'arrête.
9. Toucher la notification ouvre l'application sur l'état en cours, sans relancer la lecture ni l'indexation.
10. Les textes de la notification (nom et description du canal) viennent des fichiers ARB.
11. L'autorisation de notification (`POST_NOTIFICATIONS`) est déclarée mais jamais demandée : Android affiche la notification d'une session média sans elle, comme le prototype l'a constaté sur le Pixel (MPL-012) (validé par le propriétaire le 2026-10-21).

## Hors périmètre

Pochettes dans la notification (MPL-037), Android Auto et navigation dans la bibliothèque depuis le système (MPL-005, D12), lecture aléatoire et répétition, reprise de la file après un redémarrage de l'application.

## As-built

MPL-036, 2026-10-21. `PlayerAudioHandler` (`lib/platform/media_session/player_audio_handler.dart`), initialisé par `startSystemPlayback` (`lib/app/system_playback.dart`) ; Android : `AudioServiceActivity`, service et récepteur dans le manifeste, `keep.xml`. Tests : `test/platform/player_audio_handler_test.dart`.

- L'arrêt (exigence 7) passe par l'état « inactif » de la session : `audio_service` arrête alors le service et retire la notification. L'état « arrêté » du contrôleur (fin de file, éjection, échecs) y mène aussi.
- La position n'est envoyée au système que si elle s'écarte de plus de 1,5 s de celle qu'il extrapole (déplacement, changement de piste) : la progression régulière ne réveille pas la session à chaque tic.
- Le lecteur compact (notification repliée, écran verrouillé) montre précédent, lecture/pause et suivant ; « arrêt » est dans la notification dépliée.
- Les informations de la piste viennent de la bibliothèque (`libraryTrackIndexProvider`) ; une piste inconnue montre son nom de fichier.
- Exigence 8 : en pause, retirer l'application des récentes arrête le contrôleur et le service. Quand le service s'arrête sans activité ouverte, `audio_service` détruit le moteur Flutter ; `MainActivity` termine alors le processus, car mpv ne peut pas être libéré sans l'isolat Dart (plantage de MPL-018). L'application suivante repart de zéro.
- Exigence 6 : balayer la notification en pause arrête le contrôleur (comportement par défaut d'`audio_service`).
- Choisir une autre piste passe un instant par l'état « arrêté » du contrôleur : la session n'est libérée que s'il dure plus de 0,5 s, pour que la notification ne disparaisse pas.
- Risques à vérifier sur le Pixel (`HOWTO.md` §12) : reprise après un long appel en arrière-plan (redémarrage du service au premier plan refusé par Android 12+ ?) ; touche média après la mort du processus (service démarré sans file).
- Vérifié sur l'émulateur (Android 16, release) : service au premier plan de type `mediaPlayback`, notification sur le canal « Lecture », session `PLAYING` avec titre et commande d'arrêt, touches média, retour arrière, retrait des récentes, arrêt. Pixel : non testé.
