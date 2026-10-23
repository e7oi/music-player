# TuneShell — spécification de conception (handoff)

> Intégré au dépôt le 2026-10-23 (MPL-016, ADR-011). Les décisions du projet remplacent les « décisions ouvertes » du § 9 et le plan par lots du § 10 ; les règles d'interface sont reprises dans BR-007 et les fiches FR-008 à FR-010. Seules quatre captures sont versionnées (`screens/png/`, en JPEG réduit) ; les autres restent chez le propriétaire.

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

Tout est dans `lib/ui/theme/tuneshell_tokens.dart` :

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
- **Repère de source** : chaque source a un repère (forme + couleur). « Local » (stockage interne, tous dossiers confondus) = ● neutre. Chaque disque reçoit à l'ajout le prochain repère libre : ■ bleu, ◆ violet, ▲ rose, ⬢ olive ; au-delà de 4 disques, couleurs réutilisées en forme contour. Stocker `markIndex` sur la source ; l'utilisateur peut le changer (écran 4 « Repère › Modifier »). Deux disques ne partagent jamais le même repère.
- **Le repère est visible partout où une piste apparaît** :
  - listes de pistes (Pistes, détail d'artiste, file d'attente) : avant l'artiste, 2ᵉ ligne ;
  - détail d'album (pas de ligne artiste) : entre le titre et la durée ;
  - cartes d'album (grille) : avant « Artiste · année » ; si un album est réparti sur plusieurs sources, afficher jusqu'à 3 repères côte à côte ;
  - mini-lecteur : avant l'artiste (10 dp) ;
  - lecteur plein écran et panneau lecteur (paysage/tablette) : en tête de la ligne d'informations, **suivi du nom de la source** (« ● Local · Disque 1 · Piste 3 · 2019 ») ;
  - notification et écran verrouillé : impossible (rendu par Android). Voir § 9.
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
- **Repère de source** (`SourceMark`, 12 dp) au début de la 2ᵉ ligne, avant l'artiste, sur **chaque** ligne : ● Local, ■ / ◆ / ▲ / ⬢ pour les disques. Indépendant de la pochette. Il garde sa couleur même si la source est absente.
- Pistes d'un disque absent : **grisées** (`TsColors.unavailable`), repère de la source + icône débranchée, sous-titre « Artiste · non connecté », pochette à 35 % d'opacité.
- **Index alphabétique** (`AlphabetScroller`, état **3d**) : poignée fine au repos ; au glissé depuis la poignée, colonne « # A–Z » avec effet loupe façon dock macOS et bulle de la lettre courante. Détails § 6. Aussi dans Albums et Artistes.
- **Bouton « En cours »** (`JumpToCurrentFab`, état **3c**) : apparaît quand la piste en cours (ou, à l'arrêt, la dernière jouée) est hors de l'écran. Détails § 6.

CA :

- [ ] Chaque ligne affiche le repère de sa source ; formes distinctes entre sources (vérifiable en niveaux de gris) ; libellé TalkBack « …, source SSD ».
- [ ] Le bouton « En cours » apparaît/disparaît selon la visibilité de la ligne en cours, indique le sens (↑/↓), et le toucher amène la ligne au centre avec un bref surlignage.
- [ ] La dernière ligne de la liste reste atteignable sans être cachée par le bouton (espace bas `TsSize.listBottomInset`).
- [ ] Index : un défilement normal (doigt au milieu de la liste) n'active jamais l'index ; un glissé depuis le bord droit déclenche toujours le geste Retour d'Android, sauf sur la poignée.
- [ ] Index : la lettre sous le doigt grossit de façon continue avec ses 2 voisines de chaque côté ; la liste suit en temps réel ; vibration à chaque changement de lettre ; « # » regroupe chiffres et symboles ; lettres vides grisées et sautées.
- [ ] Index : utilisable au pouce d'une main (colonne sur toute la hauteur de la liste) ; côté gauche si le réglage est activé ; toucher la poignée sans glisser ouvre la grille de lettres.
- [ ] Index : TalkBack peut changer de lettre (gestes d'ajustement) et la grille de lettres est accessible.
- [ ] Défilement fluide (60 i/s) sur 5 000 pistes en profil release.
- [ ] Les pistes grisées restent touchables : toucher → explication (« Branche le SSD pour lire cette piste »), pas d'erreur de lecture.
- [ ] Le ProgressBanner disparaît à la fin ; il peut être replié.

### Écran 4 — Disques amovibles (`Disques.dc.html`)

| Réf. | État | Contenu |
|---|---|---|
| 4a | Connecté | DiskCard « SSD », « 1 To · 2 dossiers · 812 pistes », pastille « Connecté », **« ■ Repère » + « Modifier »** (choix parmi les repères libres, aperçu forme + couleur) ; dossiers du disque avec bouton « Retirer » ; « Ajouter un dossier » |
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
  - Apparence : Thème (Système / Clair / Sombre, bouton segmenté), Couleurs du fond d'écran (non), Index alphabétique à gauche (non).
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
| `SourceMark` | Repère de source | 12 dp (24 dp en légende) ; formes `circle`, `square`, `diamond`, `triangle`, `hexagon` (+ variante contour au-delà de 4 disques) ; couleurs `TsColors.sourceLocal` / `TsColors.sourceColor(i)` ; décoratif pour TalkBack (la source est dans le libellé de la ligne) ; dessiné en `CustomPaint` |
| `JumpToCurrentFab` | Bouton « En cours » | FAB étendu 56 dp, `primaryContainer`, icône égaliseur + flèche ↑/↓ selon le sens, libellé « En cours » ; se replie en icône seule pendant un défilement rapide ; variante « Dernière jouée » en `surfaceContainerHigh` quand rien ne joue ; position : 16 dp au-dessus du mini-lecteur (en paysage : coin bas droit de la colonne de liste) ; fondu + échelle `TsMotion.medium` ; si la piste n'est pas dans la liste affichée, ouvre le lecteur |
| `AlphabetScroller` | Index alphabétique | Voir détail ci-dessous. Pistes, Albums, Artistes. |

### 6.1 `AlphabetScroller` — index alphabétique (détail)

Mesures dans `TsSize.index*` et `TsMotion.index*`.

1. **Au repos** : poignée 6 × 48 dp (zone tactile 32 × 64) contre le bord, visible pendant le défilement, estompée après 1,5 s d'inactivité. Affichée seulement si la liste dépasse ~ 100 éléments.
2. **Activation** : uniquement par un appui sur la **poignée** suivi d'un glissé. Jamais par un glissé depuis le bord de l'écran ni par le défilement normal. La colonne apparaît en 150 ms et disparaît 600 ms après le lâcher.
3. **Colonne** : « # », puis A à Z, réparties sur toute la hauteur de la liste (entre l'en-tête et le mini-lecteur), à 4 dp du bord, largeur 32 dp, fond `surfaceContainerHigh` à 94 % d'opacité, rayon 16.
4. **Effet loupe (dock macOS)** : taille et décalage vers l'intérieur calculés de façon **continue** selon la distance verticale au doigt (pas par paliers). Valeurs repères : sous le doigt 26 dp / −34 dp ; à 1 lettre 18 dp / −18 dp ; à 2 lettres 14 dp / −7 dp ; au-delà 11 dp / 0. Courbe douce (par ex. cosinus) sur `TsSize.indexInfluence` = 2 lettres.
5. **Repère de la lettre courante** : lettre en `primary` 800 ; bulle 72 dp (`primaryContainer`, forme goutte pointant vers le doigt) à gauche du doigt, avec la lettre (34 dp) et le nombre d'éléments (« 148 pistes ») ; la bulle suit le doigt verticalement.
6. **Saut** : la liste se positionne en temps réel sur le premier élément de la lettre (`jumpTo`, pas d'animation pendant le glissé). Retour haptique léger (`HapticFeedback.selectionClick`) à chaque changement de lettre.
7. **Groupes et tri** : « # » = tout ce qui commence par un chiffre ou un symbole (ex. « 01 - piste sans titre.flac »). Accents et casse repliés (É → E). Les articles (« Les », « The ») ne sont pas ignorés en v1. Lettres sans élément en `TsColors.unavailable` et sautées pendant le glissé.
8. **Une main** : côté droit par défaut ; réglage « Index alphabétique à gauche » (écran 8e) qui place poignée et colonne à gauche. **Toucher la poignée sans glisser** ouvre une feuille « Aller à la lettre » (grille 6 colonnes de boutons 48 dp) atteignable au pouce.
9. **Gestes système** : seule la poignée est déclarée en exclusion du geste Retour (`systemGestureExclusionRects`, Android limite à 200 dp par bord). Une fois le glissé commencé sur la poignée, il peut se poursuivre sur toute la hauteur.
10. **Accessibilité** : `Semantics` réglable (`onIncrease` / `onDecrease` = lettre suivante / précédente, valeur « Lettre C, 148 pistes ») ; la feuille « Aller à la lettre » est l'alternative au glissé avec TalkBack.
11. **Thèmes** : uniquement des rôles du ColorScheme et de TsColors ; contraste des lettres ≥ 4,5:1 sur le fond de la colonne dans les deux thèmes.

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

## 9. Décisions

| Sujet | Statut |
|---|---|
| Licence du logiciel | **GPL-3.0-or-later** (D1) ; à afficher dans À propos (MPL-048). Licence des ressources de marque : à trancher avant la publication (ADR-011) |
| Icône d'application | Maquette vectorielle dans `docs/design/brand/` ; **à finaliser** (MPL-049) |
| Taille d'écran de référence Pixel 10 Pro | 412 × 915 dp supposé, **à confirmer** sur l'appareil |
| Texte exact du dialogue de permission | Imposé par Android ; la maquette 1c est approximative |
| Version Android minimale | **`minSdk` 30** (ADR-005) |
| Source dans la notification / l'écran verrouillé | Le repère graphique est impossible (rendu système). Option : ajouter le nom de la source au sous-titre de la MediaSession. **À décider** (MPL-047) |
| Moteur audio et base de données | `media_kit` (D2), Drift (D3), `audio_service` (ADR-006) ; aucune dépendance réseau |

---

## 10. Plan d'implémentation par lots

Le plan par lots de Design est découpé en tickets du backlog (`docs/backlog.md`). Les lots 1 à 4 refont des écrans déjà livrés ; ils sont cadrés un par un.

| Lot de Design | Ticket |
|---|---|
| 0 · Fondations | MPL-016 |
| 1 · Accès et dossiers | MPL-044 |
| 2 · Bibliothèque | MPL-045 |
| 3 · Disques | MPL-046 |
| 4 · Lecture | MPL-047 |
| 5 · Vues secondaires | MPL-048 |
| 6 · Finitions | MPL-049 |
