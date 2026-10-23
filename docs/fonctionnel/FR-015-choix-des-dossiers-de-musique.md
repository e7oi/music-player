# FR-015 — Choix des dossiers de musique

**Statut :** Brouillon · **Créée le :** 2026-10-23 · **Ticket :** MPL-044 · **Lié :** UC-006, FR-003, FR-006, FR-011, FR-014, BR-007, BR-008 · **Source :** `docs/design/HANDOFF.md` §5 (écran 2, états 2a à 2e), `Dossiers.dc.html` · **Reprend :** FR-003, exigences 2 à 4 (présentation seulement)

## Besoin

L'écran de choix des dossiers est celui de la conception : clair, avec un résumé et un bouton « Continuer », au premier lancement comme à tout moment depuis la bibliothèque.

## Exigences

1. **Contenu (2a).** Titre « Dossiers de musique », « TuneShell cherche ta musique dans les dossiers cochés. Tu pourras changer ce choix plus tard. », intertitre « Stockage interne », une ligne par dossier du premier niveau (ou « Racine du stockage ») avec le nombre de fichiers audio (« 1 842 fichiers audio », nombres écrits selon la langue), « Music » coché au premier lancement s'il existe, bouton « Ajouter un dossier » (exigence 7), barre du bas « 1 dossier · 1 842 fichiers » avec « Continuer ».
2. **Ligne.** Toute la ligne est la zone de la case à cocher (48 dp au moins, rôle annoncé « case à cocher », état coché lu) ; le total de la barre suit les cases en direct, sans attente.
3. **Chargement (2b).** Pendant la lecture de la liste : bandeau « Recherche des fichiers audio… » dans le flux, comptages remplacés par des squelettes, barre « 1 dossier · comptage… ». Les comptages arrivent en une fois, pas un à un (voir « À valider »).
4. **Aucun dossier coché (2c).** Tout décoché : « Continuer » désactivé et le message « Coche au moins un dossier pour continuer. » à la place du résumé.
5. **Aucun fichier audio (2d).** « Aucun fichier audio trouvé », « Aucun dossier de ce téléphone ne contient de musique. Ajoute un dossier ou branche un disque. », boutons « Ajouter un dossier » et « Actualiser » ; résumé « Aucun dossier à ajouter. ».
6. **Erreur (2e).** La liste n'a pas pu être lue : bandeau d'erreur dans le flux, jamais sur la liste, avec « Réessayer ». Il dit « Les dossiers n'ont pas pu être lus. » (voir « À valider »).
7. **« Ajouter un dossier ».** Ouvre le sélecteur d'Android pour un dossier d'un disque amovible (UC-003, FR-006) ; un dossier du téléphone est refusé avec le message existant. Le disque ajouté apparaît ensuite dans l'écran des disques, pas dans cette liste.
8. **Depuis la bibliothèque** (pastille « Dossiers », FR-011.2) : même écran, le retour (flèche et geste) revient à la bibliothèque sans rien changer (FR-003.4) ; le bouton s'appelle « Valider » au lieu de « Continuer ».
9. **Mise en page.** Portrait et paysage (liste défilante, barre du bas fixe), thèmes clair et sombre, texte jusqu'à 200 %, barre de lecture de la coque conservée ; textes dans les fichiers ARB.

## Hors périmètre

Disques amovibles et leur écran (MPL-046), recherche de dossier, sous-dossiers séparés d'un même dossier (FR-003, as-built), tri des dossiers.

## À valider (PO)

- **Révision de FR-003.3 et du comportement actuel** : on ne peut plus valider un choix vide au premier lancement (« Continuer » désactivé). Ce qui reste de l'état « Aucun dossier choisi » de FR-011.9 : décocher tout n'est possible que depuis la bibliothèque, où « Valider » reste actif si le propriétaire veut vider la bibliothèque. À trancher : vider reste-t-il permis ?
- **Comptages en une fois** (exigence 3) : MediaStore rend les comptages avec la liste ; l'arrivée « progressive » de la maquette n'a pas d'objet. Le squelette n'est montré que le temps de la lecture.
- **Erreur par dossier** (exigence 6) : la lecture est une seule requête, un dossier « Download » en erreur seul n'existe pas ; l'erreur est donc globale, sans ligne « Lecture impossible ».
- **« Ajouter un dossier »** : limité aux disques amovibles (D25, voir FR-014), donc proche du bouton de l'écran des disques ; MPL-046 pourra le déplacer.
- Libellé du bouton : « Continuer » au premier lancement, « Valider » ensuite (le texte « Continuer » de la maquette ne convient pas à une modification).

## As-built

À écrire à la livraison de MPL-044.
