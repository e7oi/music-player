# FR-005 — Lecture en arrière-plan et contrôles du système

**Statut :** Brouillon · **Créée le :** 2026-10-21 · **Ticket :** MPL-036 · **Décisions :** D2, D12, D14 · **Lié :** UC-002, FR-001, BR-005

## Besoin

La lecture continue quand l'application n'est plus à l'écran, et Android la commande comme celle de tout lecteur de musique : notification, écran verrouillé, lecteur des réglages rapides, touches média.

## Exigences

1. Pendant la lecture, l'application tourne comme service au premier plan de type « lecture de média » : la lecture continue, piste après piste, écran verrouillé, application en arrière-plan ou fermée par le geste de retour, téléphone débranché.
2. Une notification de lecture (canal « Lecture ») montre le titre de la piste (ou le nom du fichier, FR-003), l'artiste et l'album quand ils sont connus, et les commandes : piste précédente, lecture/pause, piste suivante, arrêt, ainsi qu'une barre de progression qui permet de se déplacer dans la piste.
3. L'écran verrouillé et le lecteur des réglages rapides montrent la même piste et les mêmes commandes.
4. Les touches média (casque filaire, casque Bluetooth, montre) commandent lecture/pause, piste suivante et piste précédente.
5. Toutes ces commandes passent par le `PlayerController` et suivent ses règles (FR-001), par exemple « précédent » après 3 s qui reprend la piste au début. L'état affiché par le système suit celui du contrôleur : piste, lecture ou pause, position, durée.
6. En pause, la notification reste affichée mais l'utilisateur peut la balayer ; Android peut alors arrêter l'application au bout d'un moment.
7. Arrêt (commande « arrêt », fin de la file, éjection du disque de la piste, BR-002) : la notification disparaît et le service s'arrête.
8. Retrait de l'application des applications récentes : pendant la lecture, la lecture continue ; en pause ou à l'arrêt, l'application s'arrête.
9. Toucher la notification ouvre l'application sur l'état en cours, sans relancer la lecture ni l'indexation.
10. Les textes de la notification (nom et description du canal) viennent des fichiers ARB.

## Hors périmètre

Pochettes dans la notification (MPL-037), Android Auto et navigation dans la bibliothèque depuis le système (MPL-005, D12), lecture aléatoire et répétition, reprise de la file après un redémarrage de l'application.

## À valider

- Autorisation de notification (`POST_NOTIFICATIONS`) : Android affiche la notification d'une session média même sans cette autorisation ; le prototype l'a constaté sur le Pixel (MPL-012). Proposition : la déclarer, sans la demander. `CLAUDE.md` impose de la demander en natif dans `MainActivity` si elle est demandée.
- Commande « arrêt » dans la notification : utile pour faire disparaître la notification pendant la lecture ; Android peut ne pas l'afficher dans le lecteur compact. À confirmer.
