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

## 4. MPL-003 : SSD par SAF (tests sur le Pixel, 08/10/2026)

Ajout du 09/10/2026 à ce snapshot (campagne distincte de celles des §1 à §3, qui restent inchangées). Le code du prototype est dans le dépôt privé `music-player-prototype` (branche `mpl-003-saf-prototype`, jamais fusionnée).

### 4.1 Matériel et accès

SSD Samsung T7 Shield 1 To, exFAT, USB-C. Android le monte mais MediaStore ne l'indexe pas : seul le sélecteur de dossiers Android (SAF) y donne accès (D25, provisoire).

### 4.2 Résultats sur le Pixel (établis)

- Sélection du dossier, droit d'accès persistant (conservé après fermeture, arrêt forcé, et arrêt forcé avec vidage du cache de l'app), restauration au démarrage.
- Lecture des pistes du SSD avec les deux moteurs.
- Détection du retrait et du rebranchement : sources grisées « indisponibles », puis de nouveau lisibles quelques secondes après le rebranchement, sans nouvelle sélection.
- Lecture manuelle et Auto-test.
- **Auto-test sur le SSD (2 MP3) :** `just_audio` 2/2 OK ; `media_kit` 2/2 WARN. Le WARN vient des fichiers, pas du SSD ni du SAF (voir 4.5).
- **Tags :** non lus pendant le parcours SAF. Lecture mesurée à environ 39 ms par fichier (11 à 77 ms), soit environ 100 s pour 2 600 fichiers : à faire en arrière-plan (MPL-018).

### 4.3 Retrait du SSD pendant la lecture

**Sans traitement (établi) :** l'app est tuée par Android. `vold` (gestionnaire de stockage) trouve un descripteur de l'app ouvert sur le montage brut du volume et envoie `SIGINT`, environ 0,86 à 1,02 s après l'annonce d'éjection (EJECTING) sur le Pixel (environ 100 ms sur l'émulateur). Ce n'est pas un plantage : aucune exception ni trace de crash, et aucun code Dart ou Java ne peut l'intercepter. Les deux moteurs sont concernés (`media_kit` et `just_audio`).

**Spike (dépôt privé du prototype, commit `a70b2b5`) :** un écouteur natif d'éjection (`StorageManager.StorageVolumeCallback`, API 30+) prévient Dart, qui appelle `stop()` du moteur courant ; `stop()` arrête le moteur avant de fermer le descripteur.

| # | Moteur | Contexte | Arrêt préalable | Résultat |
|---|---|---|---|---|
| 1 | `media_kit` | premier plan | oui | l'app survit |
| 2 | `media_kit` | écran verrouillé | oui | l'app survit |
| 3 | `just_audio` | premier plan | oui | l'app survit |
| 4 | `just_audio` | écran verrouillé | oui | l'app survit |
| 5 | `just_audio` | essai refait (contexte non précisé) | oui | l'app survit |
| Témoin | non précisé | non précisé | non | l'app est morte, comme prévu |

Sur les essais valides : événement reçu 101 à 227 ms après le retrait USB, moteur arrêté 124 à 282 ms après le retrait, soit bien avant l'interruption (valeurs globales, pas détaillées par essai ici). Débranchements à 30–43 s sur des pistes de 176 à 255 s.

**Non établi :** que ça fonctionne toujours. Un seul Pixel, un seul SSD, 5 essais.

**Non vérifié :** marge sous charge (fil Dart occupé, parcours ou lecture de tags en cours), autres descripteurs ouverts sur le volume, autres appareils et versions d'Android, fichiers courts entièrement tamponnés.

À retirer : le récepteur de diffusions `ACTION_MEDIA_*` n'a rien reçu dans les captures. Au rebranchement, la lecture arrêtée ne reprend pas (décision produit à prendre).

Alternative **non testée** : fournir au moteur un descripteur qui passe par l'app (`StorageManager.openProxyFileDescriptor`), de sorte qu'aucun descripteur ne reste sur le montage brut. Compatibilité mpv/ExoPlayer et effet sur la fluidité inconnus.

Deux sorties `SIGNALED` plus anciennes dans l'historique d'Android restent sans cause connue (non établi qu'elles soient liées au plantage observé).

### 4.4 Défauts du prototype (non corrigés dans le prototype)

- Quand des sources sont « indisponibles », le long message d'état écrase la liste de pistes en portrait et la liste disparaît en paysage : à éviter dans la vraie interface (MPL-016/017).
- L'état du lecteur reste « idle · lecture » après le plantage.

### 4.5 MPL-010 : erreurs de décodage `media_kit` sans effet audible constaté

Deux cas :

1. FLAC avec ID3 (déjà documenté dans `docs/sprints/sprint-1/DIAGNOSTICS.md`).
2. MP3 avec des données non-MPEG après la dernière trame audio. MP3 A (53 s) a 60 200 octets après l'audio (dont ID3v1 de 128 octets), MP3 B (238 s) en a 37 304. Les deux ont pourtant un en-tête `Info` correct. `media_kit` tente de décoder ces octets : `mp3float: Header missing`, puis « Error decoding audio » (14 et 9 fois), et annonce une durée supérieure de 0,2 à 0,3 s à celle de `just_audio`. Copies tronquées juste après la dernière trame : 0 erreur et durée identique à `just_audio`. Reproduit à l'identique sur l'émulateur avec des copies internes : ni le SSD ni le SAF ne sont en cause.

Un test d'écoute sur le Pixel n'a révélé aucune différence audible entre les deux moteurs en fin de piste (coupure éventuelle d'environ 0,3 s non mesurée). Origine de ces octets : **inconnue**. Fréquence dans la bibliothèque (92 % de MP3) : **non mesurée**. Décision : documenter seulement, pas de changement de code ; le verdict WARN de l'Auto-test reste tel quel.

Messages `mpv` « No cache data directory supplied » et `property not found` (`subs-fallback`, `osc`) : origine et effet **non établis**.
