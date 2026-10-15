# ADR-005 — MediaStore et autorisation par canal natif ; minSdk 30

**Statut :** Active (validée le 2026-10-15) · **Date :** 2026-10-15 · **Ticket :** MPL-018 · **Décisions :** D25, D30 · **Fiches :** FR-003, FR-004, BR-004

## Contexte

FR-003 lit MediaStore ; FR-004 demande `READ_MEDIA_AUDIO` en natif. `CLAUDE.md` interdit `permission_handler` et place les canaux sous `platform/`, le Kotlin sous `android/`.

## Décision

- Un canal `MethodChannel` écrit dans le projet : côté Kotlin dans `MainActivity` (ou une classe voisine), côté Dart dans `platform/`. Pas de paquet tiers d'accès à MediaStore : leur maintenance n'est pas vérifiée, et le besoin tient en une requête.
- Méthodes : `audioPermissionStatus`, `requestAudioPermission`, `openAppSettings`, `queryInternalAudio`. La dernière renvoie les colonnes des informations de FR-003, exécutée hors du fil principal Android ; le filtrage par dossiers choisis et la liste des dossiers (avec leur nombre de fichiers) se font côté Dart à partir de `RELATIVE_PATH`.
- Port `InternalAudioSource` dans `domain/library/ports/`, implémenté par cet adaptateur ; fake dans `test/`.
- `TrackSourceOpener` pour le stockage interne (ADR-002) : chemin du fichier = racine du stockage interne + chemin relatif, lu par `media_kit` (D25).
- `VolumeEvents` (ADR-002) : adaptateur minimal qui ne connaît que le stockage interne, toujours disponible, sans événement. MPL-035 l'étend aux volumes amovibles.
- **`minSdk` passe de 24 (gabarit Flutter) à 30** : `RELATIVE_PATH` de MediaStore existe depuis l'API 29, `StorageVolumeCallback` (MPL-035) depuis l'API 30, et le seul appareil de test est en Android 17. Écart à la règle D30 (« partir des valeurs du gabarit ») (validé par le propriétaire le 2026-10-15).
- Le câblage dans `app/providers/` relie enfin `PlayerController` au moteur `media_kit` et à ces adaptateurs.

## Conséquences

- Le code Kotlin de liaison est une exception au test d'abord (`CLAUDE.md`) : procédure dans `HOWTO.md`, résultat sur le Pixel « testé » ou « non testé ».
- Les appareils sous Android 10 et antérieurs ne peuvent plus installer l'application.

## As-built

Néant (non implémenté).
