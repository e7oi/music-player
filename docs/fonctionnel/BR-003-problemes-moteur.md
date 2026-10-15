# BR-003 — Problèmes signalés par le moteur

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-017 · **Décisions :** D2 · **Lié :** MPL-010

## Règle

Le moteur classe chaque problème en échec ou en avertissement (ADR-002) ; le contrôleur traite les deux cas sans exception.

1. **Échec** (fatal pour la piste en cours) : le contrôleur signale l'échec (piste, nature) et passe à la piste disponible suivante, comme en fin de piste.
2. **Échecs consécutifs** : après 3 échecs consécutifs, la lecture s'arrête avec un signalement, sans attendre la fin de la file (par exemple un disque corrompu). Une piste lue jusqu'au bout remet le compteur à zéro (validé par le propriétaire le 2026-10-15).
3. **Avertissement** : aucun changement d'état ; il est journalisé et compté. Les avertissements de MPL-010 (sans effet audible constaté) entrent dans ce cas.

## Cas limites

- Moins de 3 pistes restantes, toutes en échec : la lecture s'arrête en fin de file, sans boucle. Chaque échec est signalé.
- Un échec pendant le chargement (avant que la durée soit connue) suit la même règle.

## À valider

- Remise à zéro du compteur d'échecs consécutifs quand l'utilisateur donne une nouvelle file ou relance la lecture après un arrêt : implémentée, à confirmer. Sans elle, deux échecs en fin de file suivis d'un nouvel échec après « lecture » arrêteraient tout de suite la lecture.

## As-built

MPL-017, 2026-10-15. `PlayerController._onIssue`, `_fail` ; signalements `TrackFailed` et `PlaybackStoppedAfterFailures` ; compteur d'avertissements dans `PlayerState.warningCount`. Tests : groupe « BR-003 ».

- Une piste qu'on ne peut pas ouvrir (`TrackSourceException`) compte comme un échec de type `openFailed`.
- Le compteur d'échecs consécutifs repart aussi de zéro quand une nouvelle file est donnée (`setQueue`) et quand l'utilisateur relance la lecture après un arrêt (`play`). Cas non décrits par la fiche, voir « À valider ».
- Les avertissements sont journalisés par l'adaptateur `media_kit` (journal local de l'appareil) et comptés par le contrôleur.
