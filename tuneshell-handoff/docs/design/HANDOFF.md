# TuneShell — spécification de conception (handoff)

Version de la conception : **v0.4 « Carapace sonore »** · Cible : Android, Pixel 10 Pro (maquettes à 412 × 915 dp, taille de référence à confirmer) · Material 3 · Flutter 3.27+.

---

## 0. Comment utiliser ce document

- **Ce document décrit le comportement.** Les captures (`screens/png/`) montrent le rendu visé. Les sources (`screens/source/*.dc.html`) donnent les valeurs exactes en cas de doute.
- **Ordre de priorité si deux sources se contredisent** : ce document > `tuneshell_tokens.dart` > sources `.dc.html` > captures PNG.
- Chaque écran porte un **identifiant** (ex. `3a`) repris dans le titre des captures et des sources.

---

## 1. Produit et principes

TuneShell lit les fichiers audio déjà présents sur le téléphone et sur des disques amovibles (USB, carte SD). Pas de compte, pas de pub, pas de réseau.

Nom : *tune* (musique) + *shell* (la carapace de la tortue qui abrite la collection).

**Principes de conception (à respecter dans toute décision non prévue) :**

1. **La liste d'abord.** Lignes de 64 dp, défilement rapide avec index alphabétique : pensé pour 5 000 pistes et plus.
2. **Le menthe (`primary`) signale ce qui joue** et l'action principale. **L'écaille (`tertiary`, ambre) signale ce qui demande une action.** Jamais en décor.
3. **Un état ne dépend jamais de la couleur seule** : icône + texte (« SSD non connecté »).
4. **Rien ne recouvre la liste.** États persistants dans le flux, au-dessus des pistes, repliables. Portrait comme paysage. *(Corrige un défaut du prototype.)*
5. **Le dégradé et la lueur restent dans la marque** (logo, écran de démarrage). L'interface est plate.

---

## 2. Fondations

### 2.1 Thème

Tout est dans `lib/theme/tuneshell_tokens.dart` :

- `TsSchemes.light` / `TsSchemes.dark` : `ColorScheme` complets.
- `TsColors` (ThemeExtension) : `unavailable`, `nowPlayingRow`, `coverPlaceholder`, `brandMint`, `brandCyan`, `brandNight`.
- `TsSpace`, `TsRadius`, `TsSize`, `TsMotion`, `TsText`, `TsTheme.light()` / `TsTheme.dark()`.

**Thème par défaut** : suit le système (`ThemeMode.system`). Réglage possible : Système / Clair / Sombre (écran 8e).

**Couleurs dynamiques (Material You)** : désactivées par défaut. Réglage « Couleurs du fond d'écran » → `TsTheme.light(dynamicScheme: …)` via le paquet `dynamic_color`. `TsColors` reste fixe.

### 2.2 Typographie

- **Manrope** (titres, logotype) et **Inter** (texte), licence OFL, **embarquées** dans `assets/fonts/` (voir `assets/fonts/README.md`).
- Chiffres tabulaires (`FontFeature.tabularFigures()`) pour durées et compteurs : déjà dans `labelMedium`.

| Rôle | Police | Poids | Taille / ligne | Usage |
|---|---|---|---|---|
| displaySmall | Manrope | 800 | 36/44 | Accueil |
| headlineSmall | Manrope | 800 | 28/36 | Titre d'écran (« Pistes ») |
| titleLarge | Manrope | 700 | 22/28 | Barres d'app, états vides |
| titleMedium | Inter | 500 | 16/24 | Titre de piste |
| bodyMedium | Inter | 400 | 14/20 | Artiste, sous-titres, bandeaux |
| labelLarge | Inter | 600 | 14/20 | Boutons, pastilles |
| labelMedium | Inter | 500 | 12/16 tnum | Durées, compteurs |
| labelSmall | Inter | 600 | 11/16 | Surtitres en capitales |
| `TsText.playerTitle` | Manrope | 800 | 24/32 | Titre du lecteur plein écran |

### 2.3 Icônes

Les maquettes utilisent des icônes au trait (24 dp, trait 2). En Flutter, utiliser les **Material Symbols arrondis** équivalents (police d'icônes embarquée, aucun réseau). Correspondance indicative (noms à vérifier dans le paquet choisi) :

| Usage | Symbole |
|---|---|
| Pistes (navigation) | `music_note` |
| Albums | `album` ou `library_music` |
| Artistes | `person` |
| Réglages | `tune` |
| Rechercher (emplacement futur) | `search` |
| Actualiser | `refresh` |
| Dossiers | `folder` |
| Disques | `hard_drive` / `storage` |
| Source débranchée | `usb_off` |
| Erreur | `error` |
| Accès bloqué / à renouveler | `lock` |
| Lecture, pause, précédent, suivant | `play_arrow`, `pause`, `skip_previous`, `skip_next` |
| Aléatoire, répéter | `shuffle`, `repeat` / `repeat_one` |
| File d'attente | `queue_music` |
| Favoris (emplacement futur) | `favorite` |
| Réordonner | `drag_handle` |
| Retirer un dossier | `remove_circle_outline` |
| Ouvrir les réglages système | `open_in_new` |

### 2.4 Mesures clés

Marge écran 16 · ligne de piste 64 · pochette liste 48 (rayon 8) · mini-lecteur 64 (rayon 16, marges 8) · barre de navigation 80 · bouton lecture plein écran 80 (rayon 28) · pochette plein écran 348 (rayon 16) · zone tactile minimale 48.

---

## 3. Navigation et structure

### 3.1 Onglets principaux (barre basse)

`Pistes` · `Albums` · `Artistes` · `Réglages`. Le mini-lecteur est posé au-dessus de la barre dès qu'une piste est chargée.

Recherche, playlists et favoris **n'existent pas encore** : seuls des emplacements discrets sont prévus (icône Rechercher dans l'en-tête, cœur « bientôt » dans le lecteur). Ne pas créer d'onglet vide.

### 3.2 Routes

| Route | Écran | Réf. |
|---|---|---|
| `/onboarding` | Premier lancement (accueil → demande d'accès) | 1a–1e |
| `/folders` | Dossiers de musique (aussi depuis Réglages et la pastille « Dossiers ») | 2a–2e |
| `/tracks` | Pistes (onglet) | 3a, 3b, 6a–6d |
| `/albums`, `/albums/:id` | Albums, détail d'un album | 8a, 8b |
| `/artists`, `/artists/:id` | Artistes, détail d'un artiste | 8c, 8d |
| `/settings` | Réglages | 8e |
| `/disks` | Disques amovibles | 4a–4e |
| `/player` | Lecteur plein écran (+ feuille File d'attente) | 5a–5d |

### 3.3 Adaptation à la largeur (Material 3 window size classes)

| Largeur | Navigation | Lecteur |
|---|---|---|
| < 600 dp (compact) | `NavigationBar` en bas | Mini-lecteur + écran plein |
| 600–839 dp (moyen) | `NavigationRail` | Panneau droit repliable |
| ≥ 840 dp (étendu) | `NavigationRail` (ou panneau latéral) | Panneau droit permanent 280 dp (pochette, contrôles, file) |

Le téléphone en **paysage** (~915 dp de large) est en classe **étendue** : rail à gauche, liste au centre, panneau lecteur à droite (maquette 6e). Les bandeaux d'état restent **en tête de la colonne de liste**.

---

## 4. Modèle de données (rappel)

Par piste : `title` (sinon **nom de fichier**), `artist`, `album`, `albumArtist`, `trackNumber`, `discNumber`, `year`, `genre`, `duration`, `artwork` (carrée ou absente), `sourceId` (disque d'origine ou stockage interne).

Dérivés :

- **Disponibilité** d'une piste = disponibilité de sa source (`connected`, `absent`, `needsAccess`). Une piste indisponible reste **affichée, grisée**, jamais supprimée de la bibliothèque.
- **Albums** groupés par (`albumArtist` ou `artist`, `album`). Pistes triées par `discNumber`, puis `trackNumber`.
- **Artistes** groupés par **artiste de l'album** (`albumArtist`, sinon `artist`) pour éviter la multiplication des « feat. ».
- Fichiers sans étiquettes : artiste « Artiste inconnu », album « Album inconnu ».

---

## 5. Écrans

Pour chaque écran : sources, états, comportements, critères d'acceptation (CA). Les textes exacts sont dans les captures et les sources.

### Écran 1 — Premier lancement (`Onboarding.dc.html`)

| Réf. | État | Contenu |
|---|---|---|
| 1a | Accueil | Logo, « Bienvenue dans TuneShell », « Ta musique, chez toi. », 3 promesses, indicateur d'étape 1/2, bouton « Commencer » |
| 1b | Explication | « Étape 2 sur 2 », illustration dossier + note, « Autoriser l'accès à ta musique », 2 garanties, « Autoriser l'accès », « Pas maintenant » |
| 1c | Dialogue système | Référence seulement : dialogue Android standard, non modifiable |
| 1d | Refus simple | Bandeau écaille « Accès refusé… » en haut, bouton principal devient « Réessayer » |
| 1e | Refus définitif | « L'accès est bloqué », étapes Réglages › Autorisations › Musique et audio › Autoriser, « Ouvrir les réglages », « Choisir un dossier à la place » |

Comportements :

- Permission : `READ_MEDIA_AUDIO` (Android 13+) ; `READ_EXTERNAL_STORAGE` (Android 12 et moins). *À vérifier selon la version minimale visée.*
- **Refus définitif** = la demande n'affiche plus le dialogue (permission refusée et `shouldShowRequestPermissionRationale` faux après un refus). Alors afficher 1e.
- « Ouvrir les réglages » → écran d'informations de l'app (`ACTION_APPLICATION_DETAILS_SETTINGS`). Au retour dans l'app, revérifier la permission.
- « Choisir un dossier à la place » → sélecteur de dossier système (SAF, `ACTION_OPEN_DOCUMENT_TREE`), qui ne nécessite pas la permission. Le dossier choisi est ajouté comme source.
- « Pas maintenant » → bibliothèque en état 6b (aucun dossier choisi).

CA :

- [ ] Le dialogue système n'apparaît qu'après l'écran 1b, jamais au démarrage à froid.
- [ ] 1d et 1e s'affichent selon le type de refus ; retour depuis les réglages avec permission accordée → passage à l'écran 2.
- [ ] Tous les boutons ≥ 48 dp, libellés lisibles par TalkBack.

### Écran 2 — Dossiers de musique (`Dossiers.dc.html`)

| Réf. | État | Contenu |
|---|---|---|
| 2a | Normal | Liste cochable des dossiers du stockage interne contenant de l'audio, avec le nombre de fichiers ; **« Music » coché par défaut** ; « Ajouter un dossier » ; barre basse « 1 dossier · 1 842 fichiers » + « Continuer » |
| 2b | Chargement | Bandeau « Recherche des fichiers audio… », comptages remplacés par des squelettes |
| 2c | Aucun dossier | Tout décoché : « Continuer » désactivé, message « Coche au moins un dossier pour continuer. » |
| 2d | Aucun fichier audio | État vide : « Ajouter un dossier », « Actualiser » |
| 2e | Erreur | Bandeau d'erreur **dans le flux** « Le dossier « Download » n'a pas pu être lu. » + « Réessayer » ; ligne concernée « Lecture impossible » en `error` |

CA :

- [ ] Une ligne entière est la zone de la case à cocher (`CheckboxListTile` ou équivalent, rôle case à cocher annoncé).
- [ ] Les comptages arrivent progressivement sans bloquer l'interface.
- [ ] Le bandeau d'erreur ne masque jamais la liste.

### Écran 3 — Pistes (`Bibliotheque.dc.html`, états 3a, 3b)

- En-tête : titre « Pistes », bouton Rechercher (emplacement futur, tooltip « Rechercher (bientôt) »), menu.
- Pastilles d'action : **Actualiser**, **Dossiers**, **Disques** (badge écaille « 1 absent » si une source demande attention).
- **ProgressBanner** « Lecture des étiquettes : 340 / 2 600 » pendant la lecture des métadonnées (3a), « Recherche des fichiers audio… N trouvés » pendant le premier parcours (3b, lignes en squelette).
- Ligne de compte « 2 600 pistes · 12 indisponibles » + tri « Titre A→Z ».
- Liste de **TrackTile** ; ligne en cours de lecture surlignée (`nowPlayingRow`, titre `primary`, petit égaliseur).
- Pistes d'un disque absent : **grisées** (`TsColors.unavailable`), icône débranchée, sous-titre « Artiste · SSD non connecté », pochette à 35 % d'opacité.
- Barre de défilement rapide à droite (poignée + bulle de lettre au glissement).

CA :

- [ ] Défilement fluide (60 i/s) sur 5 000 pistes en profil release.
- [ ] Les pistes grisées restent touchables : toucher → explication (« Branche le SSD pour lire cette piste »), pas d'erreur de lecture.
- [ ] Le ProgressBanner disparaît à la fin ; il peut être replié.

### Écran 4 — Disques amovibles (`Disques.dc.html`)

| Réf. | État | Contenu |
|---|---|---|
| 4a | Connecté | DiskCard « SSD », « 1 To · 2 dossiers · 812 pistes », pastille « Connecté » ; dossiers du disque avec bouton « Retirer » ; « Ajouter un dossier » |
| 4b | Parcours | Dans la carte : « Parcours du disque : 1 240 / 3 100 fichiers » + barre + **« Arrêter »** |
| 4c | Non connecté | Pastille neutre « Non connecté », « Vu pour la dernière fois le 21 octobre », dossiers grisés « · indisponibles », « Ajouter un dossier » désactivé avec la raison |
| 4d | Accès à renouveler | Pastille écaille « Accès à renouveler », explication, bouton écaille **« Renouveler l'accès »** |
| 4e | Aucun disque | État vide « Aucun disque amovible » + « Ajouter un dossier » |

Comportements :

- Les dossiers des disques sont des **arborescences SAF** dont l'accès est conservé (`takePersistableUriPermission`).
- **Accès à renouveler** = l'autorisation persistée n'est plus valable (disque reformaté, changement d'identifiant…) → « Renouveler l'accès » relance le sélecteur de dossier sur ce disque.
- **Non connecté** = volume absent ; aucune action requise (état neutre, pas écaille).
- « Arrêter » interrompt le parcours proprement ; ce qui a été lu est conservé.
- Le parcours long tourne dans un **service au premier plan** avec notification (voir 7c, 7d).

CA :

- [ ] Débrancher le disque pendant l'utilisation → 4c et pistes grisées sans redémarrage.
- [ ] Rebrancher → retour à 4a automatiquement, pistes de nouveau disponibles.
- [ ] Retirer un dossier demande une confirmation et retire ses pistes de la bibliothèque (pas les fichiers !).

### Écran 5 — Lecteurs (`Lecteur.dc.html`, `MiniLecteurs.dc.html`)

**Mini-lecteur** : pochette 48, titre, artiste ; précédent / lecture-pause / suivant (48 dp chacun) ; fine barre de progression en bas. Toucher la zone gauche ou glisser vers le haut → lecteur plein écran (transition `Hero` sur la pochette). États : lecture, pause, sans pochette (nom de fichier tronqué), source perdue (« Arrêt : SSD débranché » en écaille).

**Lecteur plein écran** :

| Réf. | État | Contenu |
|---|---|---|
| 5a | En lecture | Réduire, « Lecture depuis Pistes · Titre A→Z », grande pochette, titre / artiste · album / « Disque 1 · Piste 3 · 2019 · Ambient », favori (bientôt), curseur de position + temps, aléatoire, précédent, lecture-pause (80), suivant, répéter, bouton « À suivre · 11 pistes » |
| 5b | Pause, sans pochette | Tuile neutre avec note, nom de fichier comme titre, « FLAC · Stockage interne / Download » |
| 5c | File d'attente | Feuille modale (`DraggableScrollableSheet`) : « File d'attente », « 12 pistes · 46 min · aléatoire », « Vider la suite », piste en cours, à suivre avec poignées de réordonnancement ; pistes indisponibles grisées « sera ignorée » |
| 5d | Piste illisible | Bandeau `errorContainer` sous la pochette « Fichier illisible (endommagé). Piste suivante dans 3 s. » + « Passer » |

CA :

- [ ] Aléatoire et répéter ont un état actif visible autrement que par la couleur (point sous l'icône, `aria-pressed`).
- [ ] Le curseur de position est utilisable au clavier/TalkBack (pas de 5 s).
- [ ] Une piste indisponible est sautée automatiquement, avec un message.

### Écran 6 — États vides et erreurs (`Bibliotheque.dc.html`, `BibliothequePaysage.dc.html`)

| Réf. | État | Contenu |
|---|---|---|
| 6a | Bibliothèque vide | « Ta bibliothèque est vide » + « Choisir des dossiers », « Actualiser » |
| 6b | Aucun dossier choisi | « Aucun dossier choisi » + « Choisir des dossiers » |
| 6c | Source indisponible | **StatusBanner warning** « 12 pistes ignorées : SSD absent » + « Voir » (→ Disques) + fermer ; liste visible dessous |
| 6d | Piste illisible | Ligne « Fichier illisible » en `error` ; snackbar flottante temporaire « Impossible de lire « Bastion » : fichier endommagé. Piste suivante lancée. » + « Détails » |
| 6e | Paysage | Rail + liste + panneau lecteur ; bandeau en tête de colonne, **ne recouvre rien** |

CA :

- [ ] **Test automatisé** : avec une source absente, en portrait et en paysage, la première piste reste visible et touchable sous le bandeau (vérifier la position du bandeau par rapport à la liste).
- [ ] Fermer le bandeau le masque jusqu'au prochain changement d'état de la source.

### Écran 7 — Notification et écran verrouillé (`Systeme.dc.html`, référence)

- Rendus **par Android** via la `MediaSession` : l'app fournit pochette, titre, artiste, album, durée, position, actions (précédent, lecture-pause, suivant, + aléatoire et répéter en actions personnalisées). Couleurs et mise en page imposées par le système.
- Petite icône de notification : silhouette blanche `assets/brand/ic_notification.svg` (à convertir en vecteur Android).
- **Notification de parcours** (7a/7b) : « Parcours du SSD · 1 240 / 3 100 fichiers », barre, action « Arrêter ». Obligatoire pour un travail long en arrière-plan (service au premier plan ; type à choisir selon les règles Android en vigueur, ex. `dataSync` ; *à vérifier pour Android 14/15*).

### Écran 8 — Albums, artistes, réglages (`Albums.dc.html`, `Artistes.dc.html`, `Reglages.dc.html`)

- **8a Albums** : grille 2 colonnes, pochette carrée rayon 16, titre + « Artiste · année » ; tri « Artiste de l'album » ; album sans pochette = tuile neutre ; album d'un disque absent grisé + icône.
- **8b Détail d'un album** : pochette 152, titre, artiste de l'album (`primary`), « année · genre / N disques · N pistes · durée », « Lire », « Aléatoire » ; pistes groupées par « Disque 1 », « Disque 2 », numérotées (numéro remplacé par ▶ pour la piste en cours).
- **8c Artistes** : lignes 64 avec avatar rond à **initiale** (pas d'image d'artiste dans les données), « N albums · N pistes », intercalaires de lettres, **index A–Z** à droite (glisser pour sauter). « Artiste inconnu » sous `#`.
- **8d Détail d'un artiste** : avatar 96, nom, « N albums · N pistes · durée », « Tout lire », « Aléatoire », albums en carrousel horizontal, puis pistes.
- **8e Réglages** :
  - Bibliothèque : Dossiers de musique ›, Disques amovibles ›, Actualiser au démarrage (oui), Ignorer les fichiers courts < 30 s (oui).
  - Apparence : Thème (Système / Clair / Sombre, bouton segmenté), Couleurs du fond d'écran (non).
  - Lecture : Pause si le casque est débranché (oui), Reprendre là où j'en étais (oui).
  - À propos : TuneShell 0.1.0 · licence · code source ; Confidentialité « Aucune donnée collectée, aucun compte, aucun réseau ».

---

## 6. Composants (`Composants.dc.html`)

| Widget | Rôle | Points clés |
|---|---|---|
| `TrackTile` | Ligne de piste | Hauteur fixe 64 ; états `normal`, `playing`, `noArtwork`, `unavailable`, `unreadable`, `loading` ; `InkWell` pleine ligne ; appui long = menu (futur) ; Semantics « Titre, artiste, durée, état » |
| `DiskCard` | Carte de disque | `Card.filled` ; `DiskStatus { connected, scanning, absent, needsAccess }` ; callbacks `onRenew`, `onStop`, `onRemoveFolder` |
| `ProgressBanner` | Progression dans le flux | Déterminé ou indéterminé ; `LinearProgressIndicator(minHeight: 4)` ; mises à jour ≤ 4/s ; annoncer début et fin seulement |
| `StatusBanner` | Bandeau d'état dans le flux | `BannerKind { error, warning, info }` → `errorContainer`, `tertiaryContainer`, `surfaceContainerHigh` ; action + fermer ; `Semantics(liveRegion: true)` |
| `MiniPlayer` | Mini-lecteur | `surfaceContainerHigh`, rayon 16 ; `Hero` pochette |
| `ActionChip` + `Badge` | Pastilles d'en-tête | 36 visibles, cible 48 |
| `ArtworkTile` | Pochette ou tuile neutre | Tailles 48 / 96 / 152 / 348 ; placeholder note de musique ; opacité 35 % si indisponible |
| `AlphabetScroller` | Index A–Z / défilement rapide | Utilisé dans Pistes et Artistes |

---

## 7. Accessibilité (liste de contrôle)

- [ ] Zones tactiles ≥ 48 × 48 dp partout.
- [ ] Contrastes : texte ≥ 4,5:1 (déjà garanti par les jetons ; ne pas utiliser d'opacité sur du texte sauf états désactivés).
- [ ] Aucun état signalé par la couleur seule.
- [ ] TalkBack : chaque bouton-icône a un libellé ; cases à cocher, interrupteurs, boutons segmentés exposent leur rôle et leur état.
- [ ] Texte agrandi à 200 % : pas de texte coupé ; listes en hauteur variable au-delà de 1,3×.
- [ ] Animations réduites si l'utilisateur l'a demandé (`MediaQuery.disableAnimations`).

---

## 8. Hors périmètre (emplacements discrets seulement)

Recherche, playlists, favoris, égaliseur, paroles, synchronisation, comptes, réseau.

---

## 9. Décisions ouvertes

| Sujet | Statut |
|---|---|
| Licence du logiciel | **À choisir** (ex. GPL-3.0, MIT). Afficher dans À propos. |
| Icône d'application | Maquette vectorielle dans `assets/brand/` ; **à finaliser** (vecteur propre, test des masques Android) |
| Taille d'écran de référence Pixel 10 Pro | 412 × 915 dp supposé, **à confirmer** sur l'appareil |
| Texte exact du dialogue de permission | Imposé par Android ; la maquette 1c est approximative |
| Version Android minimale | À fixer (impacte permissions et service au premier plan) |
| Moteur audio et base de données | À proposer par Claude Code en mode plan (ex. `just_audio` + `audio_service`, base locale `drift`) ; aucune dépendance réseau |

---

## 10. Plan d'implémentation par lots

Chaque lot se termine par : `flutter analyze` propre, tests verts, captures comparées aux maquettes, liste des écarts.

| Lot | Contenu | Définition de « terminé » |
|---|---|---|
| **0 · Fondations** | Projet, polices, `tuneshell_tokens.dart`, l10n FR, navigation à 4 onglets (écrans vides), adaptatif compact/étendu, page de démonstration des composants | Thème clair/sombre OK ; composants `TrackTile`, `StatusBanner`, `ProgressBanner`, `DiskCard`, `ArtworkTile` dans tous leurs états ; goldens |
| **1 · Accès et dossiers** | Écrans 1 et 2, permissions, SAF, persistance des sources | Parcours complet premier lancement → dossiers → bibliothèque vide/pleine |
| **2 · Bibliothèque** | Parcours des fichiers en isolate, lecture des étiquettes, base locale, écran 3, états 6a–6c, défilement rapide | 5 000 pistes fluides ; progression visible ; pistes grisées si source absente |
| **3 · Disques** | Écran 4, détection branchement/débranchement, renouvellement d'accès, service au premier plan + notification de parcours | Débrancher/rebrancher sans redémarrer ; « Arrêter » fonctionne |
| **4 · Lecture** | Moteur audio, MediaSession, notification, écran verrouillé, mini-lecteur, lecteur plein écran, file d'attente, 5d et 6d | Lecture en arrière-plan, commandes système, saut des pistes illisibles/indisponibles |
| **5 · Vues secondaires** | Albums, artistes, réglages (écran 8), paysage 6e | Navigation complète ; réglages persistés |
| **6 · Finitions** | Icône finale, écran de démarrage, accessibilité (liste § 7), performance | Liste de contrôle cochée |
