# BR-007 — Règles d'interface

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-016 (puis tous les tickets d'écran) · **Décisions :** D15, D26 · **Lié :** FR-008, FR-009, FR-010, ADR-010 · **Source :** `CLAUDE.md` du dossier de conception, `docs/design/HANDOFF.md` §1 et §7

## Règles

1. **Jetons uniquement.** Aucune couleur, taille de police, rayon ni espacement écrit en dur dans un écran ou un composant : tout passe par `Theme.of(context)`, `TsColors`, `TsSpace`, `TsRadius`, `TsSize`. Un test automatisé échoue si `lib/features/` ou `lib/ui/widgets/` contient un littéral de couleur, de rayon, d'espacement ou de taille de police.
2. **Rien ne recouvre la liste de pistes.** Un état qui dure (source indisponible, erreur de dossier, progression) est un composant **dans le flux**, au-dessus de la liste (`StatusBanner`, `ProgressBanner`), en portrait comme en paysage. Interdit pour ces états : `showMaterialBanner`, `Overlay`, `Stack` par-dessus la liste. Une `SnackBar` reste permise pour un message court.
3. **Un état ne dépend jamais de la couleur seule** : icône ou forme, plus texte.
4. **Zones tactiles d'au moins 48 dp**, libellé `Semantics` ou `tooltip` sur tout bouton-icône.
5. **Aucun réseau** (D15, D26) : pas de `google_fonts` en téléchargement, pas de permission `INTERNET` dans la variante hors ligne, polices embarquées.
6. **Clair et sombre** : chaque écran et chaque composant fonctionne dans les deux thèmes.
7. **Animations réduites** : respecter `MediaQuery.disableAnimations`.
8. **Textes** : dans les fichiers ARB, en français mot pour mot des maquettes ; la version anglaise est traduite.
9. **Listes** : hauteur de ligne fixe tant que l'échelle de texte ne dépasse pas 1,3 ; pochettes en miniatures mises en cache ; aucune lecture d'étiquettes sur le fil de l'interface.

## À valider (PO)

- Règle 1 : l'espacement écrit en dur (`EdgeInsets.all(16)`) dans les écrans actuels sera remplacé par `TsSpace` dans MPL-016 ; la règle vaut ensuite pour tout nouvel écran.
- La règle 2 suppose que `showSnackBar` est acceptable pour les messages du lecteur (pistes ignorées), comme la maquette 6d.

## As-built

MPL-016, 2026-10-23. Règle 1 : `test/architecture/style_literals.dart` et `style_literals_test.dart` ; le contrôle couvre `lib/features/`, `lib/ui/widgets/` et `lib/ui/demo/`, pas `lib/ui/theme/`. Les littéraux repérés : `Color(0x…)`, `Colors.*` (sauf `Colors.transparent`), `fontSize:`, `Radius.circular(n)`, `BorderRadius.circular(n)`, `EdgeInsets.*(…n…)`, `SizedBox(width|height: n)`. Règle 2 : test de position du bandeau dans `test/ui/widgets/banners_test.dart` (portrait et paysage). Règles 3, 4 : tests par composant. Règle 5 : pas de `google_fonts`, pas d'`INTERNET` en release (APK vérifié).

- Le test de la règle 1 ne voit pas tout : `elevation`, `withValues(alpha:)`, `opacity`, `FontWeight`, `Duration`, `Icon(size:)`, `crossAxisCount` ne sont pas contrôlés, et ses expressions régulières s'arrêtent à la première parenthèse fermante. `TsSpace.l` sert de taille d'icône dans `TrackTile` faute de jeton `TsSize.iconSmall`. La poignée de l'index (32 × 64 dp) est plus étroite que la règle 4 : exception de Design, avec la grille et TalkBack pour alternatives.
- Les écrans de la bibliothèque, des disques et la barre de lecture ont été portés sur les jetons ; les listes de la bibliothèque n'utilisent pas encore une hauteur de ligne fixe (règle 9) : MPL-045.
- Règle 7 (animations réduites) : `JumpToCurrentFab` et la poignée de `AlphabetScroller` ont des durées nulles quand `MediaQuery.disableAnimations` est vrai (test dans `jump_to_current_fab_test.dart`) ; les animations de Material la respectent d'elles-mêmes.
