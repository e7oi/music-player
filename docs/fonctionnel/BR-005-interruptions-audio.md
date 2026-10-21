# BR-005 — Interruptions de la lecture par le système

**Statut :** Brouillon · **Créée le :** 2026-10-21 · **Ticket :** MPL-036 · **Lié :** UC-002, FR-001, FR-005

## Contexte

Android partage la sortie audio entre les applications par le « focus audio » et signale le débranchement d'un casque. `media_kit` ne gère ni l'un ni l'autre : sans règle, la musique continue par-dessus un appel ou sort du haut-parleur quand le casque se débranche.

## Règle

1. Démarrer la lecture demande le focus audio. Refusé (par exemple pendant un appel) : la lecture ne démarre pas et l'état reste « pause ».
2. Perte durable du focus (une autre application lance sa lecture) : pause, sans reprise automatique.
3. Perte passagère (appel, assistant vocal, alarme) : pause. Au retour du focus, la lecture reprend seulement si elle était en cours au début de l'interruption et que l'utilisateur n'a donné aucune commande entre-temps.
4. Perte passagère avec atténuation permise (guidage GPS, son de notification) : la lecture continue ; Android baisse le volume lui-même.
5. Débranchement du casque ou déconnexion d'un appareil audio Bluetooth : pause, sans reprise automatique, même au rebranchement.
6. Ces pauses sont des pauses ordinaires (FR-001) : la file, la piste et la position sont conservées, et la notification reste affichée (FR-005).

## À valider

- Règle 3 : reprise automatique après un appel. Certains préfèrent qu'elle reste en pause. Proposition : reprendre, comme la plupart des lecteurs.
- Règle 4 : l'atténuation automatique par Android doit être vérifiée sur le Pixel avec la sortie OpenSL ES de `media_kit` (D13). Si Android ne baisse pas le volume, la règle devient « baisser le volume de l'application pendant l'interruption ».
