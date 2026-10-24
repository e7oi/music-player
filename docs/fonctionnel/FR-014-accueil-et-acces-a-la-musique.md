# FR-014 — Accueil et accès à la musique

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-044 · **Lié :** UC-006, FR-004, FR-003, FR-011, BR-007 · **Source :** `docs/design/HANDOFF.md` §5 (écran 1, états 1a à 1e), `Onboarding.dc.html` · **Révise (si validée) :** FR-004, exigences 1, 3 et 4 (voir « À valider »)

## Besoin

Au premier lancement, l'application s'explique, demande l'accès à la musique au bon moment et reste claire quand il est refusé.

## Exigences

1. **Accueil (1a).** Tant que l'accès n'a jamais été demandé (état `notRequested`), l'application ne montre ni la bibliothèque ni le dialogue d'Android : elle montre l'accueil. Logo, « Bienvenue dans TuneShell », « Ta musique, chez toi. », trois promesses (« Lit les fichiers déjà présents sur ton téléphone et tes disques. », « Aucun compte, aucune publicité. », « Aucune donnée envoyée : tout reste sur l'appareil. »), indicateur d'étape 1 sur 2, bouton « Commencer ». Aucun autre bouton.
2. **Explication (1b).** « Étape 2 sur 2 », « Autoriser l'accès à ta musique », « TuneShell a besoin de lire les fichiers audio de ce téléphone pour construire ta bibliothèque. », deux garanties (« Lecture seule : rien n'est modifié ni supprimé », « Rien ne quitte ton téléphone »), boutons « Autoriser l'accès » et « Pas maintenant ». Le dialogue d'Android n'apparaît qu'au toucher de « Autoriser l'accès » (jamais au démarrage à froid).
3. **Refus simple (1d).** Le dialogue est refusé : l'écran 1b reste, un bandeau dans le flux dit « Accès refusé. Sans lui, TuneShell ne peut pas trouver ta musique. » et le bouton principal devient « Réessayer ».
4. **Retour des réglages.** Accès accordé dans les réglages d'Android, ou à tout retour au premier plan : l'application passe à l'écran des dossiers sans autre geste (FR-004.5).
5. **Refus définitif (1e).** Quand Android n'affiche plus le dialogue : « L'accès est bloqué », « Android ne permet plus de redemander l'autorisation. Tu peux l'activer dans les réglages de l'app : », trois étapes (Ouvrir les réglages de TuneShell, Autorisations, Musique et audio, Autoriser), boutons « Ouvrir les réglages » et « Choisir un dossier à la place », note « Le choix manuel d'un dossier fonctionne sans cette autorisation. ». « Ouvrir les réglages » ouvre l'écran d'informations de l'application ; « Choisir un dossier à la place » ouvre le sélecteur d'Android pour un dossier d'un disque amovible (voir « À valider »).
6. **Pas maintenant.** La bibliothèque s'affiche avec un état « accès non accordé » qui propose « Autoriser l'accès » (retour à 1b). Le texte de cet état n'existe pas dans les maquettes (voir « À valider »).
7. **Accessibilité et mise en page.** Tous les boutons font au moins 48 dp et ont un libellé pour TalkBack ; l'indicateur d'étape est lu (« Étape 1 sur 2 ») ; thèmes clair et sombre, portrait et paysage (contenu défilant, boutons toujours atteignables) ; textes en français et en anglais dans les fichiers ARB, mot pour mot des maquettes pour le français.

## Hors périmètre

Dialogue système (1c, référence seulement), logo animé et écran de démarrage (MPL-049), changement de langue (MPL-048).

## À valider (PO)

- **Révision de FR-004.1** : l'accès n'est plus demandé au premier démarrage mais au toucher de « Autoriser l'accès » (1b). Les exigences FR-004.3 et .4 (message et bouton) sont remplacées par 1b, 1d et 1e. FR-004 reste `Active` ; si tu valides, une révision y est notée.
- **Accueil seulement tant que l'accès n'a jamais été demandé** : aucun indicateur de plus n'est gardé. Conséquence : après « Pas maintenant », l'accueil revient au lancement suivant tant que l'accès n'a pas été demandé.
- **« Choisir un dossier à la place »** : la décision D25 réserve le sélecteur d'Android (SAF) aux disques amovibles et MediaStore au stockage interne. Le bouton ne peut donc accepter qu'un dossier d'un disque amovible ; choisir un dossier du téléphone redonne le message existant (« Ce dossier est dans le stockage du téléphone… »). Le texte de la maquette (« fonctionne sans cette autorisation ») vaut alors pour les disques seulement ; la note est ajustée en conséquence (« …d'un disque amovible… »). Alternative écartée : indexer un dossier du téléphone par SAF, qui contredit D23, D25 et BR-004.
- **État « accès non accordé »** (exigence 6) : la maquette envoie vers l'état 6b « Aucun dossier choisi », qui n'a pas de sens sans accès ; texte proposé : « Accès à ta musique non accordé » / « TuneShell ne peut pas lire tes fichiers audio sans ton autorisation. », bouton « Autoriser l'accès ».
- Le logo est dessiné dans le code à partir du SVG de marque (pas de nouvelle dépendance) ; à défaut, un simple monogramme.

## As-built

Livré par MPL-044 (2026-10-23), test appareil en attente (D14).
- États : `LibraryWelcome(explaining)`, `LibraryPermissionNeeded(permanent)` (explication avec bandeau, ou écran bloqué), `LibraryAccessDeclined`. `start()` ne demande plus l'accès (révision de FR-004.1) ; `requestPermission()` part des boutons.
- Écrans : `WelcomePage`, `AccessExplanationPage`, `AccessBlockedPage`, `AccessDeclinedView` ; logo dessiné par `TuneShellLogo` (`lib/ui/widgets/`), simplifié par rapport aux SVG de marque.
- « Choisir un dossier à la place » : `chooseFolderInstead()` (écran bloqué seulement) ajoute un dossier de disque ; si un dossier est ajouté, la bibliothèque s'affiche sans accès (`_withoutAccess`). Les pastilles « Dossiers » ramènent alors à l'explication, « Actualiser » ne relit que les disques, et le retour des réglages avec accès accordé propose les dossiers.
- Correctif du test appareil (2026-10-23) : « Pas maintenant » et Retour depuis l'explication ouverte par « Dossiers » ramènent à la bibliothèque de dossiers de disques (on ne la perd plus) ; accorder l'accès met fin à cet état.
- Limite : sans accès, au lancement suivant l'écran bloqué revient, même si un disque est connu.
- Plein écran (exigence 7, demande du propriétaire du 2026-10-23) : `HomeShell(immersive:)` retire la navigation et la barre de lecture pendant l'accueil, l'explication et l'écran bloqué (`isFirstLaunchScreen`) ; la vue garde son état ; « Pas maintenant » et le reste de la bibliothèque les remettent.
- Retour (geste) depuis l'explication : accueil. Une erreur de la demande (par exemple sans activité) est ignorée en silence, comme avant.
- Mise en page : corps défilant, boutons toujours visibles ; à 200 % en paysage le corps peut devenir étroit (vérifié par tests de widgets, pas sur appareil).
