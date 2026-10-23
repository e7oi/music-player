# TuneShell — consignes pour Claude Code

TuneShell est un lecteur audio **local, libre, gratuit, sans publicité, sans compte et sans télémétrie** pour Android, écrit en **Flutter**. L'expérience visée est celle d'un service de streaming moderne, appliquée à une bibliothèque locale de plusieurs milliers de pistes.

## Où se trouve quoi

| Chemin | Contenu |
|---|---|
| `docs/design/HANDOFF.md` | **Spécification complète** : écrans, états, comportements, règles, critères d'acceptation, plan par lots. À lire en entier avant de coder. |
| `docs/design/screens/png/` | Captures des maquettes (rendu visé). |
| `docs/design/screens/source/*.dc.html` | Sources des maquettes : valeurs exactes (tailles, couleurs, textes). Voir `docs/design/screens/README.md` pour les lire. |
| `docs/design/PROMPTS.md` | Messages de départ, un par lot. |
| `lib/theme/tuneshell_tokens.dart` | **Source unique** des couleurs, espacements, rayons, tailles, typographie et thèmes. |
| `assets/brand/` | Logo de référence et icônes vectorielles (maquettes à finaliser). |

## Règles non négociables

1. **Jetons uniquement.** Aucune couleur, taille de police, rayon ou espacement codé en dur dans un widget. Tout passe par `Theme.of(context).colorScheme`, `TsColors.of(context)`, `TsSpace`, `TsRadius`, `TsSize`, `Theme.of(context).textTheme`. Si un jeton manque, l'ajouter dans `tuneshell_tokens.dart` et le signaler.
2. **Rien ne recouvre la liste de pistes.** Les états persistants (source indisponible, erreur de dossier, progression) sont des widgets **dans le flux** (`SliverToBoxAdapter` au-dessus de la liste). Interdits pour ces états : `ScaffoldMessenger.showMaterialBanner`, `Overlay`, `Stack` par-dessus la liste. Vérifier en portrait **et** en paysage.
3. **Aucun appel réseau.** Pas d'analytics, pas de crash reporting distant, pas de `google_fonts` en téléchargement à l'exécution. Les polices Manrope et Inter sont embarquées dans `assets/fonts/`. Ne pas ajouter la permission `INTERNET` sans accord explicite.
4. **Accessibilité.** Zones tactiles ≥ 48 dp. Contrastes déjà validés dans les jetons : ne pas les contourner. Un état ne dépend jamais de la couleur seule (icône + texte). Libellés `Semantics` / `tooltip` en français sur tous les boutons-icônes.
5. **Interface en français.** Textes repris des maquettes, mot pour mot. Les chaînes passent par les fichiers ARB (`flutter_localizations`, `lib/l10n/app_fr.arb`) pour permettre d'autres langues plus tard.
6. **Performance.** Listes de pistes en `SliverFixedExtentList` (`itemExtent: TsSize.trackRow`) tant que l'échelle de texte ≤ 1,3 ; pochettes en miniatures mises en cache ; aucun travail de lecture d'étiquettes sur le thread UI (isolate).
7. **Clair et sombre** : chaque écran et chaque composant fonctionne dans les deux thèmes. Le thème sombre est la vitrine.

## Façon de travailler

- **Un lot à la fois** (voir « Plan d'implémentation » dans `HANDOFF.md`). Commencer chaque lot en **mode plan** : proposer architecture, fichiers et dépendances, puis attendre la validation avant de coder.
- **Demander avant d'ajouter une dépendance** (`pubspec.yaml`) en donnant la raison et l'alternative.
- **Ne pas inventer de comportement.** Si la spec et les maquettes ne disent rien, poser la question. Les points ouverts sont listés dans `HANDOFF.md` § « Décisions ouvertes ».
- Pour chaque composant : un widget test par état + un test de rendu de référence (golden) en clair et en sombre.
- Fin de lot : `flutter analyze` sans avertissement, `flutter test` vert, puis résumé de ce qui a été fait, des écarts avec la maquette et des questions.

## Commandes

```bash
flutter pub get
flutter analyze
flutter test
flutter test --update-goldens   # seulement après validation visuelle
flutter run
```
