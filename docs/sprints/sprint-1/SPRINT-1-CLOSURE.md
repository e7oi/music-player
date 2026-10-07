# SPRINT-1-CLOSURE — MusicPlayer

**Période :** 02/10/2026 → 05/10/2026 · **Préfixe backlog :** MPL · **Dépôt :** `e7oi/music-player`, branche `mpl-002-audio-prototype`
**Stack :** Flutter 3.47.6 / Dart 3.13.5 · `just_audio`, `media_kit`, `audio_service` · Android uniquement durant ce sprint
**Appareil de test :** Pixel 10 Pro (Android 17, SDK 37), build **release**, téléphone débranché pour les tests d'arrière-plan
**Rôle actif :** architecte Flutter/Dart senior, chef de projet, analyste ; challenge les idées et propose de nouvelles façons de faire

---

## 1. Résumé

Cadrage du produit (lecteur local gratuit, sans pub, sans compte, sans télémétrie, avec l'expérience d'un service de streaming) et prototype audio Android sur appareil réel. Lecture locale, lecture écran verrouillé, notification et contrôles système, persistance après redémarrage : validés sur le Pixel. Windows, macOS et iOS mis en pause. Reste à terminer : Auto-test complet des formats. Prochaine phase : maquettes, fondations du projet de production, indexation.

## 2. Décisions figées (jamais renégociées sans le signaler)

| # | Décision |
|---|---|
| F1 | Stack **Flutter/Dart**, codebase unique |
| F2 | Positionnement : lecteur **local** avec UX de type streaming. Aucun catalogue sous licence, aucune copie de l'identité visuelle de Spotify/Deezer |
| F3 | Priorité actuelle : **Android**. Windows 11 et macOS en pause (MPL-014). iOS hors périmètre (pas d'iPhone) |
| F4 | Android : accès aux pistes via **MediaStore** (`READ_MEDIA_AUDIO`), validé sur stockage interne. Pas de sélecteur de dossier comme voie principale |
| F5 | Android Auto : Épique **P2**, après « Expérience de type streaming ». L'architecture audio (`audio_service` + arbre média) est conçue dès le départ pour le permettre |
| F6 | Identifiant d'organisation **`net.trtl3`** (reverse-domain de trtl3.net) ; BeSolutions retiré |
| F7 | Volume (MPL-011) : **build B3**, sortie par défaut de `media_kit`, sans `ao=audiotrack` (qui produisait un son « doublé »). Écart léger accepté, non bloquant ; la normalisation sera traitée par ReplayGain (MPL-019) |
| F8 | **Valider tout item en build release** avant de le fermer (HOWTO §6) : le debug masque des défauts propres à la réduction des ressources |
| F9 | Aucune requête réseau sortante en usage de base (le build release ne déclare pas `INTERNET`) |

**Décisions provisoires (à confirmer) :**
- **D2 moteur audio** : `media_kit` moteur unique, `just_audio` en repli sur Android. Conditionnel à D1 et à l'Auto-test des formats.

**Décisions ouvertes :** D1 (open source ou non), D3 (état et base de données), D4 (nom définitif), D5 (distribution), D6 (Android Auto et Google Play).

## 3. Inventaire de la bibliothèque de test (2624 pistes)

MP3 2415 (92,0 %) · FLAC 95 · M4A 48 · WMA 32 · WAV 31 · OPUS 2 · OGG 1

## 4. Snapshot du backlog

| Clé | Type | Prio | Titre | Parent | Statut |
|---|---|---|---|---|---|
| MPL-001 | 🗂️ | 🔺 | Épique « Lecture locale » | — | En cours |
| MPL-002 | 🔧 | 🔺 | Prototype audio Android | 001 | En cours (voir §5) |
| MPL-003 | 📖 | 🔺 | Dossiers persistants, avec test disque externe Android | 001 | ⬜ À faire |
| MPL-004 | 🗂️ | 🔸 | Épique « Expérience de type streaming » | — | ⬜ À faire |
| MPL-005 | 🗂️ | ▫️ | Épique « Voiture / Android Auto » 🔗 dépend de 001 ⚠️ D6 | — | ⬜ À faire |
| MPL-006 | 🔧 | 🔺 | Auto-test sur échantillon, isolé, exporté | 001 | 📤 Prompt livré, à amender (voir §5) |
| MPL-007 | 🔧 | 🔺 | Console de test : recherche, tri, filtre par format | 002 | 📤 Prompt livré, inventaire confirmé, reste à vérifier |
| MPL-008 | 🐛 | 🔺 | Lecture coupée après ~1 min écran verrouillé | 002 | ✅ Résolu (cause initiale non déterminée) |
| MPL-009 | 🐛 | ▫️ | WMA non lu par `just_audio` (32 pistes, 1,2 %) | — | 🐞 Bug actif |
| MPL-010 | 🐛 | ▫️ | FLAC avec étiquettes ID3 : avertissement `media_kit` sans effet audible | — | 🐞 Bug actif |
| MPL-011 | 🔧 | ▫️ | Écart de volume entre moteurs | 002 | ✅ Clos (accepté, B3) |
| MPL-012 | 🔧 | 🔺 | Permission de notification | 002 | ✅ Résolu |
| MPL-013 | 🐛 | 🔺 | Icônes `audio_service` supprimées en release | 002 | ✅ Résolu |
| MPL-014 | 🔧 | ▫️ | Prototype audio Windows/macOS | — | ⏸️ En pause |
| MPL-015 | 🔧 | ▫️ | Revoir dialogue et bandeau de permission si le lecteur s'affiche sans elle ⚠️ un seul appareil testé | — | ⬜ À faire |
| MPL-016 | 🔧 | 🔺 | Maquettes UI/UX dans Claude Design | — | ⬜ À faire |
| MPL-017 | 🔧 | 🔺 | Fondations du projet de production (structure, état, navigation, thème) 🔗 dépend de D1, D2, D3 | — | ⬜ À faire |
| MPL-018 | 📖 | 🔺 | Indexation : tags, pochettes, SQLite, test à 10 000 pistes | 001 | ⬜ À faire |
| MPL-019 | 📖 | ▫️ | Normalisation du volume (ReplayGain, préampli) | 004 | ⬜ À faire |

**Priorités à réviser au prochain sprint :** MPL-009 est passé de 🔸 à ▫️ (WMA = 1,2 %) ; MPL-010 est ▫️ (sans effet audible).

## 5. Items en cours

- **MPL-002 (Android)** : critères validés sur le Pixel : lecture écran verrouillé, notification et contrôles, persistance après redémarrage, touches des écouteurs. **Reste :** Auto-test des formats.
  - Auto-test exécuté avec les deux moteurs : **3 pistes seulement (2 MP3 + 1 WAV), 3 OK**. FLAC, M4A, WMA, OPUS et OGG ne sont pas couverts par un Auto-test sur le Pixel. Pourquoi l'échantillon n'a contenu que 3 pistes n'est pas établi (filtre actif ou logique d'échantillonnage) : à vérifier.
  - Fermeture de MPL-002 uniquement après un Auto-test élargi.
- **MPL-006 à amender** (prompt pas encore envoyé à Claude Code) : échantillon pondéré, au moins 10 MP3 variés (débits, VBR/CBR, avec et sans pochette), 3 FLAC, 2 M4A, puis 1 de chaque autre format.
- **MPL-007** : fluidité du défilement (2624 pistes), recherche et tri non rapportés sur le Pixel.
- **Dépôt :** 6 commits locaux d'avance sur `origin` au dernier rapport (à pousser, jamais sur `main`). `CHANGELOG.md` modifié, **non commité**.
- **Documents :** le PRD (v0.1) est à mettre à jour (cibles, inventaire, D2 provisoire).

## 6. Risques ouverts

- **Licence** : `media_kit` (MIT) embarque libmpv/FFmpeg. Android mesuré en LGPL v3. **Windows et macOS non vérifiés** (script `tools/check_libmpv_license.sh`). Une build GPL imposerait de publier l'app sous GPL.
- **Disque externe Android** (clé USB, carte SD) : MediaStore peut ne pas suffire. À valider, avec repli SAF.
- **Un seul appareil testé** (Pixel 10 Pro, Android 17).
- **Cause initiale de l'arrêt à ~1 min (MPL-008) non déterminée.** La lecture tient maintenant avec le service au premier plan.
- **Volume** : écart léger, perçu à l'oreille, jamais mesuré en dB.
- **Sortie OpenSL ES** : à ma connaissance dépréciée côté Android ; à surveiller à chaque version d'Android.
- **Non essayés** : indexation des tags et pochettes, performance SQLite à 10 000 pistes, gapless, fluidité du défilement.
- **Android Auto** : distribution via Google Play probablement requise (D6, à revérifier).
- **WMA** : seul `media_kit` le lit.
- **macOS** : Xcode complet requis ; environ 13 Go libres sur le Mac de développement lors du dernier relevé.

## 7. Règles critiques à ne pas casser

1. **Ne jamais fermer un item sans test réel en build release** et confirmation explicite de l'utilisateur. Écrire « non testé » plutôt que « OK » quand ce n'est pas vérifié.
2. **Conserver `android/app/src/main/res/raw/keep.xml`** (icônes `@drawable/audio_service_*`). Sans lui, la réduction des ressources supprime les icônes et le service audio ne démarre pas (commit `38cbf32`).
3. **Dans l'adaptateur `media_kit`, `playing` = intention de lecture**, pas l'état brut de mpv. Sinon le service perd le premier plan à chaque changement de piste (commit `d6f041c`).
4. **Permission de notification** déclarée et demandée en natif dans `MainActivity` (commit `cf79f4f`). `permission_handler` est retiré, incompatible avec le Gradle de Flutter 3.47.
5. **Pendant un Auto-test, ne pas toucher à l'app** (moteur, scan, écran). Le harnais verrouille le lecteur ; toute interaction fausse les résultats.
6. **Tests d'arrière-plan : téléphone débranché.** Branché en USB, Android ne se comporte pas comme en usage réel.
7. **Chaque correctif dans un commit séparé et annulable.** Ne rien pousser sur `origin` sans accord ; jamais sur `main`.
8. **Aucune télémétrie, aucun réseau sortant.**
9. **Pas de gain de volume arbitraire** ; la normalisation passe par ReplayGain (MPL-019).
10. **`media_kit` sur Android** : utiliser le chemin de fichier des pistes, pas l'URI `content://` (libmpv ne sait pas l'ouvrir).

## 8. Commits repères (branche `mpl-002-audio-prototype`)

`d6f041c` playing = intention (media_kit) · `cf79f4f` permission de notification · `38cbf32` keep.xml des icônes · `8e5c0e9` documentation des résultats Pixel · `4094fcc` diagnostics volume §9.9

## 9. Pour démarrer le Sprint 2

Ordre recommandé :
1. Terminer MPL-002 : amender MPL-006 (échantillon pondéré), exécuter l'Auto-test sur le Pixel pour les deux moteurs, fermer.
2. Commiter `CHANGELOG.md` et pousser la branche.
3. Trancher **D1** (open source ou non), puis **D2**.
4. Lancer **MPL-016** (maquettes), qui ne dépend pas du moteur audio.
5. Puis MPL-017, MPL-018, MPL-003.
