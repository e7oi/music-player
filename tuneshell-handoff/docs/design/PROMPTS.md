# Messages de départ pour Claude Code

À coller un par un, **un lot par session** (ou après `/clear`). Toujours valider le plan avant le code.

---

## Lot 0 · Fondations

> Lis `CLAUDE.md` puis `docs/design/HANDOFF.md` en entier, et regarde les captures de `docs/design/screens/png/` (direction visuelle et composants). Passe en mode plan.
>
> Objectif du lot 0 : poser les fondations de TuneShell.
> 1. Projet Flutter (ou vérification de l'existant), polices Manrope et Inter embarquées (voir `assets/fonts/README.md`), intégration de `lib/theme/tuneshell_tokens.dart` sans le modifier sauf nécessité signalée.
> 2. Localisation française par fichiers ARB.
> 3. Navigation à 4 onglets (Pistes, Albums, Artistes, Réglages) avec écrans vides, et bascule NavigationBar / NavigationRail selon la largeur (§ 3.3).
> 4. Widgets `ArtworkTile`, `TrackTile`, `StatusBanner`, `ProgressBanner`, `DiskCard` dans tous leurs états (§ 6), et une page de démonstration qui les montre en clair et en sombre.
> 5. Tests : un widget test par état + goldens clair/sombre.
>
> Propose l'architecture (dossiers, gestion d'état, navigation) et les dépendances avec leur justification. Ne code rien avant ma validation.

---

## Lot 1 · Accès et dossiers

> Lot 1 : écrans 1 (premier lancement, 1a–1e) et 2 (dossiers de musique, 2a–2e) de `docs/design/HANDOFF.md`, avec les captures correspondantes et les sources `Onboarding.dc.html` et `Dossiers.dc.html`.
> Inclure : permissions audio selon la version d'Android, détection du refus définitif, ouverture des réglages de l'app et revérification au retour, sélection de dossier par SAF avec accès persistant, persistance des sources choisies.
> Mode plan d'abord. Liste les critères d'acceptation du lot et comment tu les testes.

---

## Lot 2 · Bibliothèque

> Lot 2 : bibliothèque (écran 3 : 3a, 3b) et états 6a, 6b, 6c.
> Parcours des fichiers et lecture des étiquettes dans un isolate, base locale, progression affichée par `ProgressBanner`, liste `SliverFixedExtentList` de `TrackTile`, défilement rapide alphabétique, pistes grisées si la source est absente, bandeau « N pistes ignorées : SSD absent » **dans le flux**.
> Ajoute le test automatisé du § 6c : en portrait et en paysage, le bandeau ne recouvre jamais la première piste.
> Mode plan d'abord, avec une stratégie de performance pour 5 000+ pistes.

---

## Lot 3 · Disques amovibles

> Lot 3 : écran 4 (4a–4e) et notification de parcours (§ 7).
> Détection du branchement/débranchement des volumes, état « Accès à renouveler » quand l'autorisation SAF persistée n'est plus valable, retrait d'un dossier (avec confirmation, sans toucher aux fichiers), parcours dans un service au premier plan avec action « Arrêter ».
> Vérifie les règles actuelles d'Android sur les services au premier plan pour la version minimale retenue, et signale-les. Mode plan d'abord.

---

## Lot 4 · Lecture

> Lot 4 : lecture audio, MediaSession (notification et écran verrouillé, § 7), mini-lecteur, lecteur plein écran 5a–5d, file d'attente (feuille), saut des pistes illisibles ou indisponibles (5d, 6d), pause au débranchement du casque.
> Propose le moteur audio et la gestion de la session média. Mode plan d'abord.

---

## Lot 5 · Vues secondaires

> Lot 5 : écran 8 (albums 8a/8b, artistes 8c/8d avec index A–Z, réglages 8e avec persistance) et paysage 6e (rail + panneau lecteur).
> Regroupement des artistes par artiste de l'album (§ 4). Mode plan d'abord.

---

## Lot 6 · Finitions

> Lot 6 : passe la liste de contrôle d'accessibilité du § 7 (TalkBack, texte à 200 %, contrastes, zones tactiles), intègre l'icône d'application et l'icône de notification depuis `assets/brand/`, écran de démarrage, profilage de performance. Rends un rapport des points corrigés et restants.
