# UC-006 — Premier lancement : accueil, accès à la musique et choix des dossiers

**Statut :** Brouillon · **Créé le :** 2026-10-23 · **Ticket :** MPL-044 · **Décisions :** D23, D25 · **Lié :** UC-001, FR-003, FR-004, FR-014, FR-015, FR-011, BR-007 · **Source :** `docs/design/HANDOFF.md` §5 (écrans 1 et 2), `Onboarding.dc.html`, `Dossiers.dc.html`

## Acteur et but

L'utilisateur qui ouvre TuneShell pour la première fois veut comprendre ce que fait l'application, accorder l'accès à sa musique sans surprise, choisir où elle se trouve, et arriver sur sa bibliothèque.

## Scénario nominal

1. Premier lancement : l'écran d'accueil se présente (étape 1 sur 2) ; l'utilisateur touche « Commencer ».
2. L'écran d'explication dit pourquoi l'accès est nécessaire (étape 2 sur 2) ; l'utilisateur touche « Autoriser l'accès ». Le dialogue d'Android s'affiche, jamais avant.
3. Accès accordé : l'écran des dossiers de musique s'affiche, « Music » coché s'il existe, avec le nombre de fichiers audio de chaque dossier.
4. L'utilisateur coche ou décoche, puis touche « Continuer » : la première indexation démarre et la bibliothèque s'affiche (UC-005).

## Variantes

- **Pas maintenant** (étape 2) : la bibliothèque s'affiche sans accès, avec un état qui propose de l'accorder (FR-014.6).
- **Refus simple** : l'écran d'explication reste, un bandeau dit que l'accès est refusé, le bouton devient « Réessayer ».
- **Refus définitif** : l'écran « L'accès est bloqué » explique le chemin dans les réglages d'Android et propose « Ouvrir les réglages » et « Choisir un dossier à la place » (FR-014.5).
- **Accès accordé dans les réglages** puis retour dans l'application : l'écran des dossiers s'affiche (FR-004.5, FR-014.4).
- **Aucun dossier coché** : « Continuer » est désactivé et un message le dit (FR-015.4).
- **Aucun fichier audio** : état vide avec « Ajouter un dossier » et « Actualiser » (FR-015.5).
- **Lecture des dossiers impossible** : bandeau d'erreur dans le flux avec « Réessayer » (FR-015.6).

## Hors périmètre

Dialogue système d'Android (non modifiable), écran de démarrage et icône de l'application (MPL-049), écran des disques amovibles (MPL-046), réglages (MPL-048).

## As-built

À écrire à la livraison de MPL-044.
