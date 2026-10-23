# Marque TuneShell

| Fichier | Usage | Statut |
|---|---|---|
| `logo-reference.jpg` | Logo de référence fourni par l'auteur (demi-carapace + demi-haut-parleur) | Référence, pas pour l'app |
| `note-centre-reference.png` | Note à intégrer au centre du logo | Référence |
| `app_icon_foreground.svg` | Avant-plan de l'icône adaptative (108 dp, motif dans la zone sûre de 66 dp, fond transparent) | **Maquette à finaliser** |
| `app_icon_preview.svg` | Aperçu de l'icône complète sur fond `#0D1528` | Maquette |
| `app_icon_small_48dp.svg` | Variante simplifiée pour petites tailles (sans ondes fines, note pleine) | Maquette |
| `app_icon_monochrome.svg` | Couche monochrome (icônes à thème Android 13+) | Maquette |
| `ic_notification.svg` | Petite icône de notification, silhouette blanche unie, 24 dp | Maquette |

## Couleurs

- Fond de l'icône : `#0D1528` (`TsColors.brandNight`)
- Menthe `#74FDD3` → cyan `#3DD6D9` (`brandMint`, `brandCyan`)

## Intégration Android (lot 6)

1. Finaliser les SVG (tracés propres, vérification dans les masques rond / carré arrondi / goutte).
2. Les convertir en Vector Drawable (Android Studio › New › Vector Asset, ou Image Asset pour l'icône adaptative), ou générer les icônes avec `flutter_launcher_icons` (configuration `adaptive_icon_background: "#0D1528"`, `adaptive_icon_foreground`, `adaptive_icon_monochrome`).
3. `ic_notification` : vecteur blanc uni, référencé par la session média et la notification de parcours.
