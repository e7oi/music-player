# UC-002 — Écouter et commander la lecture hors de l'application

**Statut :** Brouillon · **Créée le :** 2026-10-21 · **Ticket :** MPL-036 · **Décisions :** D2, D12 · **Lié :** FR-001, FR-005, BR-005, UC-001

## Acteur et but

L'utilisateur lance sa musique puis range le téléphone, le verrouille ou passe à une autre application. Il veut que la musique continue et pouvoir la commander sans rouvrir l'application : depuis la notification, l'écran verrouillé, son casque ou sa montre.

## Préconditions

- Une piste est en lecture depuis l'application (UC-001).

## Scénario nominal

1. L'utilisateur lance une piste dans l'application.
2. Une notification de lecture apparaît, avec la piste en cours et ses commandes (FR-005).
3. L'utilisateur verrouille le téléphone : la lecture continue, piste après piste ; l'écran verrouillé montre la piste et les mêmes commandes.
4. L'utilisateur met en pause, passe à la piste suivante ou revient à la précédente depuis l'écran verrouillé, la notification ou les touches de son casque.
5. L'utilisateur touche la notification : l'application s'ouvre sur l'état en cours.

## Variantes

- 1a. L'utilisateur quitte l'application (geste de retour, accueil, autre application) : la lecture continue (FR-005).
- 3a. Un appel arrive : la lecture se met en pause, puis reprend à la fin de l'appel (BR-005).
- 3b. Une autre application lance sa propre lecture : la lecture se met en pause et ne reprend pas d'elle-même (BR-005).
- 3c. Le casque est débranché ou se déconnecte : la lecture se met en pause (BR-005).
- 4a. L'utilisateur arrête la lecture, ou la file se termine : la notification disparaît (FR-005).
- 4b. L'utilisateur retire l'application des applications récentes pendant la lecture : la lecture continue ; en pause, l'application s'arrête (FR-005).

## Hors périmètre

Pochettes (MPL-037), Android Auto (MPL-005, D12), reprise de la file après un redémarrage de l'application, écrans définitifs (MPL-016).
