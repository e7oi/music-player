# BR-005 — Interruptions de la lecture par le système

**Statut :** Active (validée le 2026-10-21) · **Créée le :** 2026-10-21 · **Ticket :** MPL-036 · **Lié :** UC-002, FR-001, FR-005

## Contexte

Android partage la sortie audio entre les applications par le « focus audio » et signale le débranchement d'un casque. `media_kit` ne gère ni l'un ni l'autre : sans règle, la musique continue par-dessus un appel ou sort du haut-parleur quand le casque se débranche.

## Règle

1. Démarrer la lecture demande le focus audio. Refusé (par exemple pendant un appel) : la lecture ne démarre pas et l'état reste « pause ».
2. Perte durable du focus (une autre application lance sa lecture) : pause, sans reprise automatique.
3. Perte passagère (appel, assistant vocal, alarme) : pause. Au retour du focus, la lecture reprend seulement si elle était en cours au début de l'interruption et que l'utilisateur n'a donné aucune commande entre-temps (validé par le propriétaire le 2026-10-21).
4. Perte passagère avec atténuation permise (guidage GPS, son de notification) : la lecture continue ; Android baisse le volume lui-même. À vérifier sur le Pixel avec la sortie OpenSL ES de `media_kit` (D13) : si Android ne baisse pas le volume, l'écart devient une ligne « À valider ».
5. Débranchement du casque ou déconnexion d'un appareil audio Bluetooth : pause, sans reprise automatique, même au rebranchement.
6. Ces pauses sont des pauses ordinaires (FR-001) : la file, la piste et la position sont conservées, et la notification reste affichée (FR-005).

## As-built

MPL-036, 2026-10-21. `InterruptionPolicy` (`lib/domain/playback/services/interruption_policy.dart`) sur le port `AudioInterruptions` (`lib/domain/playback/ports/audio_interruptions.dart`), adaptateur `AudioSessionInterruptions` (`lib/platform/audio_session_interruptions.dart`, préréglage « musique » d'`audio_session`). Tests : `test/domain/playback/interruption_policy_test.dart`.

- Règle 1 : le focus est demandé quand l'intention de lecture passe à vrai ; s'il est refusé, le contrôleur est mis en pause aussitôt. Le chargement de la piste a pu commencer ; un son très bref est possible.
- `audio_session` 0.2.4 garde sa dernière demande de focus, même refusée, et répond ensuite « accordé » sans interroger Android. Après un refus ou pendant une perte passagère, la politique rend donc le focus avant de le redemander : un second « lecture » pendant un appel est refusé lui aussi.
- Le focus est rendu quand le lecteur reste « arrêté » ou « inactif » plus de 0,5 s, pas à la pause : choisir une autre piste passe un instant par « arrêté » sans rendre le focus.
- Événements du système et changements d'état sont traités un par un, dans l'ordre : une perte passagère très brève reprend quand même, et une reprise ne reste pas en attente pour une interruption suivante. Une erreur n'arrête pas le traitement des événements suivants ; une demande de focus qui échoue compte comme un refus.
- Règle 3 : une commande de l'utilisateur pendant l'interruption est détectée par l'état du contrôleur (lecture relancée, autre piste, arrêt) ; elle annule la reprise.
- Règle 3 vérifiée sur l'émulateur (Android 16, release) : le préviseur audio de YouTube Music prend un focus passager, la lecture se met en pause puis reprend à sa fermeture. Règles 2, 4 et 5 et l'appel : Pixel, non testé.

## À valider

- Règle 3 : la politique ne voit que l'état du contrôleur. Un déplacement dans la piste, ou « précédent » qui reprend la piste au début, pendant l'interruption n'annule pas la reprise, alors que la règle dit « aucune commande ». Proposition : l'accepter (la piste reprend à la position choisie), ou faire passer les commandes du système par la politique.
