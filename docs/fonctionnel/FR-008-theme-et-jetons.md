# FR-008 — Thème et jetons de conception

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-016 · **Décisions :** D4, D15, D26 · **Lié :** BR-007, FR-009, FR-010, ADR-010, ADR-011 · **Source :** `docs/design/HANDOFF.md` §2 (conception v0.4 « Carapace sonore »)

## Besoin

L'application a une identité visuelle unique, claire et sombre, définie en un seul endroit, que tous les écrans utilisent.

## Exigences

1. **Source unique** : un fichier de jetons (`lib/ui/theme/tuneshell_tokens.dart`, ADR-010) définit les `ColorScheme` clair et sombre, l'extension `TsColors` (indisponible, ligne en cours, tuile de pochette, couleurs de marque, couleurs de repère de source), les espacements (`TsSpace`), rayons (`TsRadius`), tailles (`TsSize`), durées (`TsMotion`), styles de texte (`TsText`) et les thèmes `TsTheme.light()` et `TsTheme.dark()`.
2. **Thème par défaut** : suit le système (`ThemeMode.system`). Le réglage Système / Clair / Sombre est livré avec les réglages (MPL-048).
3. **Couleurs dynamiques** (Material You) : désactivées. `TsTheme` peut recevoir un schéma dynamique, mais ni le réglage ni la dépendance `dynamic_color` ne sont livrés ici (MPL-048).
4. **Polices** : Manrope (titres, 600 à 800) et Inter (texte, 400 à 600), embarquées dans l'application (licence OFL, fichiers de licence joints). Aucune résolution réseau de polices.
5. **Rôles typographiques** : ceux du tableau de `HANDOFF.md` §2.2 ; chiffres tabulaires pour les durées et compteurs.
6. **Valeurs** : les couleurs, rayons, tailles et espacements du fichier de jetons font foi sur les maquettes (`HANDOFF.md` §0). Un jeton qui manque s'ajoute au fichier et se signale dans la PR.
7. **Contrastes** : les paires de couleurs validées dans les jetons (texte ≥ 4,5:1) ne sont pas modifiées sans signalement.
8. **Écrans existants** : la bibliothèque, le choix des dossiers et les disques adoptent le thème et les jetons sans changer de comportement.

## Hors périmètre

Réglage de thème et Material You (MPL-048), icône d'application, icône de notification et écran de démarrage (MPL-049), refonte des écrans eux-mêmes (MPL-044 à MPL-049).

## À valider (PO)

- Les commentaires du fichier de jetons, en français chez Design, passent en anglais (D28).
- Une propriété de `TsColors` ou de `TsSize` dont aucun écran n'a besoin à ce stade est gardée telle quelle, pas supprimée (jeton de conception).

## As-built

À écrire à la livraison de MPL-016.
