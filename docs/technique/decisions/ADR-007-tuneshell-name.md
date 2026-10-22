# ADR-007 — Nom TuneShell : nom visible, dépôt et identifiants

**Statut :** Brouillon · **Date :** 2026-10-21 · **Ticket :** MPL-039 · **Décisions :** D4 · **Fiches :** aucune (pas de changement de comportement)

## Contexte

Le propriétaire a choisi le nom définitif de l'application : **TuneShell** (D4, 2026-10-21). Le nom de travail « MusicPlayer » apparaît à trois niveaux :

- nom visible : libellé Android (`android:label="musicplayer"`), clé ARB `appTitle` (« MusicPlayer », en anglais et en français), titres des documents racine et de `CLAUDE.md` ;
- dépôt : `music-player` sur GitHub, remote du clone local, mentions dans `CLAUDE.md` et `docs/backlog.md` ;
- identifiants techniques : `applicationId` et `namespace` Android `net.trtl3.musicplayer`, paquet Kotlin et dossier `android/app/src/main/kotlin/net/trtl3/musicplayer/`, paquet Dart `musicplayer` (imports `package:musicplayer/…` sous `lib/`, `test/`, `integration_test/`, règles de `test/architecture/`), noms des canaux (`net.trtl3.musicplayer/media_store`, canal de notification `net.trtl3.musicplayer.playback`), classes nommées d'après l'application (`MusicPlayerApp`, `MusicPlayerApplication`).

Une décision du 2026-10-15 (registre, « Identifiant Android de production ») fixait `net.trtl3.musicplayer`, le même que le prototype, en attendant D4.

## Décision

Tout renommer, identifiants compris (choix du propriétaire le 2026-10-21) :

- **Nom visible** : « TuneShell », nom propre non traduit. `appTitle` vaut « TuneShell » dans tous les fichiers ARB ; le libellé Android (`android:label`) vaut « TuneShell » dans le manifeste (Android ne lit pas les ARB ; un nom propre n'a pas à être traduit).
- **Dépôt** : `music-player` devient `tuneshell` sur GitHub (renommé par le propriétaire dans les réglages du dépôt ; GitHub redirige l'ancienne adresse). Le remote du clone local est mis à jour. Le dépôt privé du prototype garde son nom (voir « À valider »).
- **Identifiant Android** : `applicationId` et `namespace` `net.trtl3.tuneshell`. Il ne pourra plus changer une fois l'application publiée (D5, D6 ouvertes) ; rien n'est publié, c'est le moment le moins coûteux.
- **Kotlin** : paquet `net.trtl3.tuneshell`, dossier déplacé ; `MusicPlayerApplication` devient `TuneShellApplication`.
- **Dart** : paquet `tuneshell` dans `pubspec.yaml` ; tous les imports `package:musicplayer/` deviennent `package:tuneshell/` ; `MusicPlayerApp` devient `TuneShellApp`.
- **Canaux** : `net.trtl3.tuneshell/media_store` et `net.trtl3.tuneshell.playback`, des deux côtés.
- **Préfixe des clés du backlog** : `MPL` est conservé (identifiants stables, cités dans l'historique Git et les PR) ; voir « À valider ».
- **Inchangés** : snapshots figés de `docs/sprints/`, historique Git, blocs Livraison et entrées de `CHANGELOG.md` déjà écrits (ils décrivent l'état de leur date), nom du fichier de base Drift (`library`).

## Conséquences

- La ligne « Identifiant Android de production : `net.trtl3.musicplayer` » du registre est remplacée : TuneShell s'installe à côté de l'ancienne application (et du prototype) au lieu de la remplacer. Sur le Pixel : désinstaller `net.trtl3.musicplayer`, puis accorder de nouveau l'autorisation audio et choisir les dossiers (FR-004, FR-003) ; la bibliothèque est réindexée, l'identité des pistes repart de zéro (BR-004), sans perte puisqu'aucune donnée utilisateur n'est conservée au-delà de l'index.
- Le changement touche presque tous les fichiers Dart (imports) : il est fait après le merge de MPL-036 pour éviter des conflits sur sa branche, en un commit mécanique (`refactor`) séparé du nom visible.
- `dart format`, les deux analyses, `flutter test` (dont `test/architecture/`) et `check-repo.sh` vérifient le renommage ; un `grep` de `musicplayer` hors des exclusions doit être vide.
- Les procédures de `HOWTO.md` qui citent le paquet (`pidof`, `dumpsys`, `am kill`) changent de nom de paquet.
- Si le propriétaire renomme aussi le dossier local du clone, la mémoire de Claude Code (liée au chemin) est à déplacer.

## Alternatives écartées

- **Nom visible seulement** : garde `net.trtl3.musicplayer` et le paquet Dart ; écarté par le propriétaire, l'identifiant Android deviendrait définitif à la publication.
- **Nom visible et `applicationId` seulement** : laisse un paquet Dart et des canaux au nom de travail ; écarté pour la cohérence, le coût étant mécanique.

## À valider (PO)

- Garder le préfixe `MPL` des clés du backlog (recommandé) ou passer à un nouveau préfixe ?
- Renommer aussi le dépôt privé `music-player-prototype` (recommandé : non, il est figé) ?
- Disponibilité du nom (Google Play, marques) : non vérifiée ; à traiter avec D5 et D6 ?
