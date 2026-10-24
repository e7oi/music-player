# BR-009 — Aléatoire, répétition et ordre de la file

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** FR-001, FR-002, FR-017, FR-018, FR-019, BR-001, BR-003 · **Source :** `docs/design/HANDOFF.md` §5 (écran 5)

## Règle

Le `PlayerController` porte deux modes (aléatoire, répétition) et six opérations sur la file (déplacer, vider la suite, aller à une piste, retirer, lire ensuite, ajouter à la fin). FR-001 et FR-002 les laissaient hors périmètre ; elles s'ajoutent sans changer leurs règles quand les modes sont éteints. Les modes valent pour la session : ils ne sont pas conservés entre deux lancements.

1. **Aléatoire : activation.** La piste courante reste courante. Les pistes qui la suivent sont mélangées une fois (tirage uniforme) ; les pistes qui la précèdent ne bougent pas. L'ordre d'origine est mémorisé par le contrôleur.
2. **Aléatoire : désactivation.** La file retrouve son ordre d'origine, la piste courante reste courante et la lecture continue avec ses suivantes dans cet ordre. Les déplacements faits à la main pendant le mode sont perdus. Les pistes retirées entre-temps (FR-002, règle 9 ci-dessous) restent retirées.
3. **Nouvelle file avec l'aléatoire actif.** La piste choisie est jouée la première, toutes les autres sont mélangées derrière elle. L'ordre d'origine est celui de la liste reçue.
4. **Répétition.** Trois valeurs : désactivée (par défaut), toutes, une piste.
   - *Désactivée* : FR-001, règle 5 (la lecture s'arrête à la fin de la file).
   - *Toutes* : à la fin de la dernière piste, ou quand « suivant » est demandé sur elle, la lecture reprend à la première piste disponible de la file, dans l'ordre courant. Aucune piste disponible : la lecture s'arrête avec le signalement de BR-001, sans boucle.
   - *Une piste* : à la fin naturelle de la piste, la même piste recommence, par le chemin de chargement habituel (BR-001 : si son disque n'est plus disponible, la lecture passe à la suivante). « Suivant » et « précédent » changent de piste normalement et le mode reste.
5. **Pas de boucle sans fin.** BR-003 s'applique sans changement : après 3 échecs de suite la lecture s'arrête, quelle que soit la répétition. Une piste en échec n'est jamais répétée : la lecture passe à la suivante.
6. **Déplacer.** Une piste de la suite (strictement après la courante) peut être placée à une autre position de la suite. La piste courante ne change pas. Une position hors de la suite est refusée sans changement d'état (comme FR-002, règle 6).
7. **Vider la suite.** Retire toutes les pistes après la courante. La courante continue ; à sa fin la lecture s'arrête, sauf répétition. Sans suite, l'opération ne change rien.
8. **Aller à une piste.** Une position de la file devient la piste courante et la lecture démarre dessus, comme « suivant » le ferait (BR-001 : sa position indisponible, on va à la suivante disponible, vers l'avant). Position hors de la file : refusée. Le compteur d'échecs de suite repart de zéro (BR-003, règle 3). Les pistes laissées derrière restent dans la file.
9. **Retrait (FR-002).** Retirer une piste la retire aussi de l'ordre d'origine mémorisé. L'interface ne retire que des pistes de la suite (FR-018.8).
10. **État exposé.** `PlayerState` porte l'état de l'aléatoire (vrai ou faux) et la répétition. Les modes se règlent aussi file vide : ils s'appliquent à la prochaine file.
11. **Lire ensuite et ajouter à la fin (FR-019).** « Lire ensuite » place la piste juste après la piste courante ; « ajouter » la place en fin de file. Dans l'ordre d'origine mémorisé, la piste va après la courante, ou en fin. La piste courante ne change pas ; rien n'est chargé. File vide : la piste devient la file et la lecture démarre (comme une nouvelle file d'une piste). Une même piste peut figurer plusieurs fois.

## Cas limites

- File d'une seule piste : l'aléatoire ne change rien ; la répétition « toutes » et « une piste » la rejouent.
- Lire ensuite pendant l'aléatoire : la piste est la prochaine jouée, pas mélangée.
- Aléatoire actif puis nouvelle file par la liste : règle 3.
- Aléatoire activé alors que la lecture est à l'arrêt (fin de file) : la piste courante reste, la suite est mélangée, rien n'est chargé.
- Répétition « toutes » et file entièrement sur un disque absent : arrêt avec le signalement, une seule fois.

## À valider (PO)

- Règle 2 : l'ordre d'origine est restauré à la désactivation et les déplacements manuels sont perdus. Autre choix possible : garder l'ordre mélangé tel quel.
- Règle 4, *toutes* : « suivant » sur la dernière piste reprend au début, ce qui complète FR-001, règle 5 (`Active`) quand la répétition est active.
- Règle 4 : l'ordre d'une nouvelle boucle reste celui du premier tour (pas de nouveau mélange).
- Règle 8 : toucher une ligne de la file lit cette piste ; les pistes sautées ne sont pas retirées.
- Les modes ne survivent pas à la fermeture de l'application.
- Règle 11 : « Lire ensuite » répété place chaque piste juste après la courante (ordre inverse de la demande) ; doublons permis.

## As-built

À écrire à la livraison.
