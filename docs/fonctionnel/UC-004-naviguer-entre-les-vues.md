# UC-004 — Naviguer entre les vues de l'application

**Statut :** Brouillon (2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-016 · **Lié :** FR-008, FR-009, FR-010, BR-007, UC-001

## Acteur et but

L'utilisateur passe d'une vue à l'autre (Pistes, Albums, Artistes, Réglages) sans perdre sa place, sur téléphone en portrait comme en paysage.

## Préconditions

- L'application est lancée ; l'accès aux fichiers audio est accordé (FR-004).

## Scénario nominal

1. L'application s'ouvre sur l'onglet **Pistes**, qui montre la bibliothèque (UC-001).
2. L'utilisateur touche **Albums** : l'écran des albums s'affiche. Tant que la vue n'est pas construite (lots suivants du design), il annonce qu'elle arrive bientôt.
3. Il touche **Réglages**, puis revient sur **Pistes** : la liste est là où il l'avait laissée.
4. Il passe le téléphone en paysage : la barre de navigation du bas devient un rail à gauche ; la vue et l'onglet choisis restent les mêmes.

## Variantes

- 2a. L'utilisateur est sur Albums, Artistes ou Réglages et fait le geste Retour : il revient sur Pistes ; un second Retour quitte l'application.
- 3a. Une lecture est en cours : la barre de lecture reste visible au-dessus de la navigation dans toutes les vues.
- 4a. Écran large (tablette, dépliable) : même rail ; le panneau lecteur permanent arrive avec le lot Lecture (MPL-047).

## Hors périmètre

Recherche, playlists, favoris (emplacements discrets seulement), contenu réel des vues Albums, Artistes et Réglages (MPL-048), lecteur plein écran (MPL-047).

## As-built

À écrire à la livraison de MPL-016.
