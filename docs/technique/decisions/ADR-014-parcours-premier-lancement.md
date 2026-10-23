# ADR-014 — Parcours du premier lancement : états, demande d'accès et écran des dossiers

**Statut :** Active (validée le 2026-10-23) · **Date :** 2026-10-23 · **Ticket :** MPL-044 · **Décisions :** D23, D25 · **Fiches :** UC-006, FR-014, FR-015, FR-004, FR-003 · **Complète :** ADR-005, ADR-010

## Contexte

`LibraryController` demande l'accès dans `start()` dès le premier démarrage, puis affiche un message simple (`LibraryPermissionNeeded`), le choix des dossiers (`LibraryFolderChoice`) ou la bibliothèque. La conception demande un accueil en deux étapes, un dialogue d'Android seulement après l'explication, trois cas de refus et un écran des dossiers plus riche.

## Décision

- **Un état de plus, pas de nouveau contrôleur** : `LibraryViewState` reçoit `LibraryWelcome` (accueil et explication, avec un champ d'étape et un indicateur de refus simple) ; `LibraryPermissionNeeded(permanent:)` devient l'écran « bloqué » ; le reste ne change pas. La machine d'états vit dans `LibraryController` (tests d'abord, `fakes` des ports existants).
- **`start()` ne demande plus l'accès** : il lit l'état ; `notRequested` donne l'accueil, `granted` continue comme aujourd'hui, `denied` et `permanentlyDenied` donnent l'explication avec refus ou l'écran bloqué. La demande d'Android part du bouton « Autoriser l'accès ».
- **Aucun indicateur d'accueil gardé** : « accueil déjà vu » se déduit de `notRequested` (le canal natif garde déjà « demandé »). Pas de dépendance, pas de préférence Dart.
- **Pas maintenant** : état de session `LibraryAccessDeclined` (la bibliothèque, avec l'état « accès non accordé ») ; rien n'est écrit sur l'appareil.
- **Écran des dossiers** : `FolderChoiceView` refait avec la barre du bas (résumé calculé dans un modèle pur testé : nombre de dossiers, total de fichiers, message d'absence de choix). Même widget pour le premier lancement et la modification, un paramètre donne le libellé du bouton et le retour.
- **« Choisir un dossier à la place »** appelle `RemovableController.addFolder()` existant ; aucune nouvelle voie d'accès au stockage interne (D25).
- **Logo** : dessiné par un `CustomPainter` dans `ui/widgets/` (pas de `flutter_svg`) à partir de `docs/design/brand/`.
- **Aucune dépendance, aucun code Kotlin neuf** : `shouldShowRequestPermissionRationale`, l'ouverture des réglages et la demande existent dans `MediaStoreChannel`.

## Conséquences

- FR-004.1 est révisée (la demande sort du démarrage) ; les tests de `LibraryController` qui supposent la demande au démarrage sont réécrits.
- Le premier lancement a un écran de plus avant le dialogue : le passage par « Commencer » est obligatoire.

## Alternatives examinées

- Un contrôleur d'accueil séparé : deux sources d'état pour le même flux ; écartée.
- Garder un indicateur « accueil vu » dans les préférences : plus de code natif ou une dépendance pour un cas rare ; écartée.
- Indexer un dossier du téléphone par SAF pour « Choisir un dossier à la place » : contredit D23, D25 et BR-004 ; écartée.

## À valider (PO)

- Accueil déduit de « jamais demandé », donc visible à chaque lancement tant que l'accès n'a pas été demandé.
- Aucune voie SAF pour le stockage interne.
- Logo dessiné en code.

## As-built

Livré par MPL-044 (2026-10-23). Conforme à la décision, avec ces précisions : `LibraryPermissionNeeded(permanent: false)` reste l'état de l'explication après un refus ; l'accueil seul est `LibraryWelcome` ; `LibraryFolderChoice` reçoit `loading` ; `_withoutAccess` (champ du contrôleur, session) retient « bibliothèque faite de dossiers de disques sans accès » ; le logo est un `CustomPainter` simplifié de 100 lignes dans `lib/ui/widgets/tuneshell_logo.dart`. Sept jetons de taille ajoutés (`buttonLarge`, `heroTile`, `heroIcon`, `logo`, `stepDot`, `stepDotActive`).
