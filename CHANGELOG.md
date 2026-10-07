# Changelog — MusicPlayer

**Dernière MAJ :** 05/10/2026 · Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

**Règle :** une entrée n'est ajoutée qu'après **confirmation par test réel** de l'utilisateur
(jamais sur la seule base d'un rapport de l'outil de génération). Chaque entrée référence la clé
du backlog (`MPL-NNN`). Un changement dans `lib/` sans entrée ici bloquera la pull request (contrôle à mettre en place, MPL-026).

---

## [Non publié]

### Ajouté

- **MPL-012** (05/10/2026) — Demande de la permission de notification (Android 13+) : dialogue explicatif au premier lancement d'une lecture, gestion du refus, bandeau avec lien vers les réglages. Confirmé sur Pixel 10 Pro (build release).

### Corrigé

- **MPL-013** (05/10/2026) — Notification de lecture, canal « Lecture » et contrôles absents en build release : la réduction des ressources supprimait les icônes `audio_service_*`. Règle de conservation ciblée dans `keep.xml` (commit `38cbf32`). Confirmé sur Pixel 10 Pro, `just_audio` et `media_kit` : lecteur dans le panneau et sur l'écran verrouillé, boutons précédent/pause/suivant fonctionnels, canal visible dans les réglages.
- **MPL-008** (05/10/2026) — Lecture interrompue après ~1 minute écran verrouillé. Confirmé sur Pixel 10 Pro avec le build corrigé (service au premier plan, notification visible), `just_audio` et `media_kit` : plus de 15 minutes écran verrouillé avec enchaînement de pistes, téléphone débranché. Cause de l'arrêt initial non déterminée (hypothèse non prouvée : absence de service au premier plan).

