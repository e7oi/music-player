**Snapshot du 08/10/2026.** Résultats du prototype Android, Pixel 10 Pro (Android 17), build release (`flutter run --release`, build par défaut sans variable d'expérience). Ne pas mettre à jour : une nouvelle campagne aura son propre document. Procédure : `HOWTO.md` §8.

## 1. Auto-test, 13 pistes par moteur (bibliothèque non filtrée, 07/10/2026)

| # | Format | Taille | Particularité | `just_audio` | `media_kit` |
|---|---|---|---|---|---|
| 1 | MP3 | 128 Kio | durée inconnue du système ; fichier probablement tronqué (cas témoin) | KO | KO |
| 2 | FLAC | 336 Kio | fichier de test généré, 20 s | OK | OK |
| 3 | M4A (ALAC) | 403 Kio | fichier de test généré, 20 s | OK | OK |
| 4 | WMA | 2,4 Mio | | KO | OK |
| 5 | WAV | 3,4 Mio | fichier de test généré, 20 s | OK | OK |
| 6 | OPUS | 6 Kio | 2,6 s | OK | OK |
| 7 | OGG | 59 Kio | fichier de test généré, 20 s | OK | OK |
| 8 | MP3 | 61 Mio | 44 min | OK | OK |
| 9 | FLAC | 32 Mio | 5,9 min, tag ID3 | OK | WARN (`Error decoding audio`, sans effet audible, MPL-010) |
| 10 | M4A | 17 Mio | 12,7 min | OK | OK |
| 11 | WMA | 14 Mio | | KO | OK |
| 12 | WAV | 180 Mio | 17,9 min | OK | OK |
| 13 | OPUS | 292 Kio | fichier de test généré, 20 s | OK | OK |

**Bilans :** `just_audio` 10 OK, 3 KO (MP3 témoin, 2 WMA) ; `media_kit` 11 OK, 1 WARN, 1 KO (MP3 témoin). Durée du test : 75 s (`just_audio`), 66 s (`media_kit`).

Sur les pistes chargées, toutes les étapes (lecture, pause, reprise, seek début/milieu/fin, fin de piste) passent avec les deux moteurs ; temps moyens comparables (lecture ≈ 1,0 s, reprise ≈ 0,8 s). Un rejeu des 3 échecs de `just_audio` donne les mêmes 3 échecs.

Les WMA échouent avec `just_audio` (attendu, WMA non prioritaire, D16) et passent avec `media_kit`. Messages d'erreur du MP3 témoin : `just_audio` « Source error », `media_kit` « Failed to recognize file format ». `mpv` journalise aussi, à chaque piste, « No cache data directory supplied / Failed to create file cache » : sans effet audible constaté, rattaché à MPL-010.

**Couverture :** 1 seul MP3 sain par moteur alors que le MP3 représente 92 % de la bibliothèque ; MPL-034 prévoit d'élargir l'échantillon.

## 2. Interface

Build release, Pixel 10 Pro : défilement, recherche et tri fluides sur 2 625 pistes ; la liste reste affichée sans nouveau scan après fermeture et redémarrage ; exports `.csv` et `.txt` fonctionnels. Non fait : passage de « Tout » sur 2 625 pistes (≈ 4 h par moteur).

## 3. Stockage amovible (diagnostic, 07/10/2026)

Un SSD USB-C (exFAT) est monté par Android mais **non visible des applications** (absent de `/storage`, volume inconnu de MediaStore, indicateurs de montage sans visibilité).

Conclusion : sélecteur Android (SAF) pour le stockage amovible (D25, provisoire). Impact : `media_kit` ne lit pas les URI `content://` ; contournement à prototyper (MPL-003, en cours).
