# Changelog — MusicPlayer

**Dernière MAJ :** 09/10/2026 · Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

**Règle :** une entrée n'est ajoutée qu'après **confirmation par test réel** de l'utilisateur
(jamais sur la seule base d'un rapport de l'outil de génération). Chaque entrée référence la clé
du backlog (`MPL-NNN`). Un changement dans `lib/` sans entrée ici bloquera la pull request (contrôle à mettre en place, MPL-026).

---

## [Non publié]

### Ajouté

- **MPL-012** (05/10/2026) — Demande de la permission de notification (Android 13+) : dialogue explicatif au premier lancement d'une lecture, gestion du refus, bandeau avec lien vers les réglages. Confirmé sur Pixel 10 Pro (build release).
- **MPL-002** (07/10/2026) — Prototype audio Android clos : lecture locale avec deux moteurs (`just_audio` et `media_kit`) ; lecture, pause, seek, lecture écran verrouillé, notification et contrôles, seek depuis la notification, persistance de la liste après fermeture et redémarrage. Voir aussi MPL-008, MPL-012 et MPL-013. Confirmé sur Pixel 10 Pro (build release). **Limites connues :** WMA lisible uniquement avec `media_kit` ; un MP3 de test illisible par les deux moteurs (fichier probablement tronqué, cas témoin).
- **MPL-006** (07/10/2026) — Auto-test sur échantillon : 1 à 2 pistes par format, 20 au plus ; moteur figé pendant le test ; exports `.csv` et journal `.txt`. Validé sur 13 pistes avec chaque moteur ; résultats dans `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md`. Confirmé sur Pixel 10 Pro (build release). **Limites connues :** WMA lisible uniquement avec `media_kit` ; un MP3 de test illisible par les deux moteurs (fichier probablement tronqué, cas témoin).
- **MPL-007** (07/10/2026) — Console de test : recherche, tri, filtre par format ; défilement, recherche et tri fluides sur 2 625 pistes ; liste conservée au redémarrage. Confirmé sur Pixel 10 Pro (build release).
- **MPL-003** (08/10/2026) — Prototype d'accès au stockage amovible par le sélecteur de dossiers Android (SAF), SSD Samsung T7 Shield (exFAT, USB-C) que MediaStore n'indexe pas ; code dans le dépôt privé du prototype (branche non fusionnée). Testé sur Pixel 10 Pro : sélection du dossier, droit d'accès persistant (conservé après fermeture, arrêt forcé, et arrêt forcé avec vidage du cache de l'app), restauration au démarrage, lecture des pistes du SSD avec `just_audio` et `media_kit`, détection du retrait et du rebranchement (sources « indisponibles », puis de nouveau lisibles quelques secondes après le rebranchement, sans nouvelle sélection), lecture manuelle et Auto-test (2 MP3 : `just_audio` 2/2 OK ; `media_kit` 2/2 WARN, dû aux fichiers et non au SSD, voir MPL-010). **Limites connues :** tags non lus pendant le parcours SAF (≈ 39 ms par fichier mesurés, MPL-018) ; retrait du SSD pendant la lecture : sans traitement, Android tue l'app (les deux moteurs) ; arrêt préalable du moteur essayé dans le prototype seulement (5 essais, un appareil), non intégré (MPL-035) ; avertissements `media_kit` sur les deux MP3 testés (MPL-010).

### Corrigé

- **MPL-013** (05/10/2026) — Notification de lecture, canal « Lecture » et contrôles absents en build release : la réduction des ressources supprimait les icônes `audio_service_*`. Règle de conservation ciblée dans `keep.xml` (commit `38cbf32`). Confirmé sur Pixel 10 Pro, `just_audio` et `media_kit` : lecteur dans le panneau et sur l'écran verrouillé, boutons précédent/pause/suivant fonctionnels, canal visible dans les réglages.
- **MPL-008** (05/10/2026) — Lecture interrompue après ~1 minute écran verrouillé. Confirmé sur Pixel 10 Pro avec le build corrigé (service au premier plan, notification visible), `just_audio` et `media_kit` : plus de 15 minutes écran verrouillé avec enchaînement de pistes, téléphone débranché. Cause de l'arrêt initial non déterminée (hypothèse non prouvée : absence de service au premier plan).

