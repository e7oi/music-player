# Polices

TuneShell embarque ses polices : aucun téléchargement à l'exécution.

1. Télécharger depuis Google Fonts (licence SIL Open Font License) :
   - **Manrope** : graisses 600, 700, 800
   - **Inter** : graisses 400, 500, 600
2. Déposer les fichiers `.ttf` ici, par exemple :
   - `Manrope-SemiBold.ttf`, `Manrope-Bold.ttf`, `Manrope-ExtraBold.ttf`
   - `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`
   (ou les versions « variable » si vous préférez, en adaptant `pubspec.yaml`)
3. Copier les fichiers de licence `OFL.txt` de chaque famille dans ce dossier.
4. Déclarer les polices dans `pubspec.yaml` (voir `pubspec_fonts_snippet.yaml` à la racine du dossier de transmission).
