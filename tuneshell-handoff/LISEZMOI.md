# Dossier de transmission TuneShell → Claude Code

## Installation (5 minutes)

1. **Décompresser** ce dossier à la racine du dépôt Flutter de TuneShell (les chemins correspondent : `CLAUDE.md`, `docs/`, `lib/`, `assets/`).
   - Si un `CLAUDE.md` existe déjà, fusionner les deux.
2. **Copier les PNG** exportés depuis le canevas dans `docs/design/screens/png/`.
3. **Polices** : suivre `assets/fonts/README.md`, puis fusionner `pubspec_fonts_snippet.yaml` dans `pubspec.yaml` (ou laisser Claude Code le faire au lot 0).
4. **Commiter** le tout avant la première session (« docs: dossier de conception v0.4 »), pour pouvoir comparer ensuite.
5. Ouvrir Claude Code dans le dépôt et coller le message du **lot 0** depuis `docs/design/PROMPTS.md`.

## Contenu

```
CLAUDE.md                          ← règles lues à chaque session
pubspec_fonts_snippet.yaml         ← déclaration des polices
lib/theme/tuneshell_tokens.dart    ← jetons et thèmes (source unique)
assets/brand/                      ← logo de référence + icônes vectorielles (maquettes)
assets/fonts/README.md             ← polices à télécharger (OFL)
docs/design/HANDOFF.md             ← spécification complète + plan par lots
docs/design/PROMPTS.md             ← messages de départ, un par lot
docs/design/screens/README.md      ← comment lire les maquettes
docs/design/screens/source/        ← sources HTML des maquettes
docs/design/screens/png/           ← (à remplir) captures exportées
```

## Conseils

- **Un lot par session.** Valider le plan avant le code, relire le diff avant de commiter.
- **Comparer à la maquette** à la fin de chaque lot : demander à Claude Code une capture du rendu (golden) à côté du PNG correspondant.
- **Toute décision nouvelle** (licence, version Android minimale…) : la noter dans `HANDOFF.md` § 9 pour que les sessions suivantes la connaissent.
