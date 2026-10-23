# Maquettes TuneShell

## `png/` — captures (rendu visé)

Quatre captures seulement sont versionnées (ADR-011), en JPEG réduit : `direction-visuelle-v0.4`, `composants-clair`, `composants-sombre`, `jetons-flutter`. Les autres planches exportées du canevas (« 3 · Bibliothèque et états — sombre », etc.) restent chez le propriétaire. Chaque planche aligne plusieurs écrans, chacun identifié par sa référence (`1a`, `3b`, `6c`…) reprise dans `../HANDOFF.md`.

## `source/` — sources HTML (valeurs exactes)

Fichiers `.dc.html` produits par l'outil de conception. Ils ne sont **pas exécutables tels quels** (ils dépendent d'un moteur absent ici) mais se lisent comme du HTML :

- **Mise en page et mesures** : attributs `style="…"` en pixels CSS = **dp** Android (1:1).
- **Couleurs** : les `{{t.xxx}}` renvoient à l'objet `t` défini dans le bloc `<script>` en bas du fichier (une palette `dark`, une `light`). Ces valeurs sont identiques à `lib/theme/tuneshell_tokens.dart` — **c'est le fichier Dart qui fait foi**.
- **États** : la propriété `state` / `view` / `step` (déclarée dans `data-props`) et les blocs `<sc-if value="{{…}}">` montrent ce qui s'affiche dans chaque état. `<sc-for>` = liste répétée.
- **Textes** : écrits en clair dans le HTML ou dans `renderVals()`. À reprendre mot pour mot (via les fichiers ARB).
- Données d'exemple (titres, artistes, couleurs de pochettes) : **fictives**, pour la maquette seulement.

### Index des fichiers

| Fichier | Écrans | Propriétés |
|---|---|---|
| `Main.dc.html` | Direction visuelle (logo, couleurs, typo, formes, principes) | — |
| `Onboarding.dc.html` | 1a–1e Premier lancement | `theme`, `step` = intro · demande · dialogue · refus · bloque |
| `Dossiers.dc.html` | 2a–2e Dossiers de musique | `theme`, `state` = normal · chargement · aucun · vide · erreur |
| `Bibliotheque.dc.html` | 3a–3d, 6a–6d Pistes | `theme`, `state` = normal · chargement · vide · aucun · indispo · illisible · horsecran · index |
| `BibliothequePaysage.dc.html` | 6e Paysage | `theme` |
| `Disques.dc.html` | 4a–4e Disques amovibles | `theme`, `state` = connecte · parcours · absent · renouveler · aucun |
| `Lecteur.dc.html` | 5a–5d Lecteur plein écran | `theme`, `state` = lecture · pause · file · erreur |
| `MiniLecteurs.dc.html` | Mini-lecteur, 4 états × 2 thèmes | — |
| `Systeme.dc.html` | 7 Notification, écran verrouillé | `theme`, `view` = volet · verrou |
| `Albums.dc.html` | 8a, 8b | `theme`, `view` = grille · detail |
| `Artistes.dc.html` | 8c, 8d | `theme`, `view` = liste · detail |
| `Reglages.dc.html` | 8e | `theme` |
| `Composants.dc.html` | Composants réutilisables et leurs états | `theme` |
| `Jetons.dc.html` | Tableau des jetons → Flutter | — |
| `Lot*.dc.html`, `*-clair.dc.html`, `*-sombre.dc.html` | Planches qui assemblent les écrans ci-dessus (aucune information supplémentaire) | — |
| `canvas.json` | Disposition des planches sur le canevas | — |
