# FR-004 — Accès aux fichiers audio

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-018 · **Lié :** UC-001 · **Ticket lié :** MPL-015

## Besoin

Android exige une autorisation pour lire les fichiers audio du téléphone. L'application la demande au bon moment et reste compréhensible si elle est refusée.

## Exigences

1. L'autorisation (`READ_MEDIA_AUDIO`) est demandée au premier lancement, avant la première indexation, en natif dans `MainActivity`, comme celle des notifications. Pas de `permission_handler`.
2. Accordée : l'indexation démarre (FR-003).
3. Refusée : la liste est remplacée par un message qui explique pourquoi l'accès est nécessaire, et un bouton qui redemande l'accès.
4. Refusée définitivement (Android n'affiche plus la demande) : le bouton ouvre les réglages de l'application.
5. Retirée dans les réglages pendant que l'application tourne : au retour au premier plan, l'application affiche l'état « refusée », sans effacer la bibliothèque.

## Hors périmètre

Présentation définitive du dialogue et du bandeau (MPL-015, MPL-016).

## As-built

MPL-018, 2026-10-15. `MediaStoreChannel.kt` (Kotlin) et `lib/platform/media_store_channel.dart` ; logique dans `LibraryController` (`lib/features/library/library_controller.dart`). Tests : `test/features/library/library_controller_test.dart`, `test/platform/`.

- Android ne distingue « ne plus demander » de « jamais demandé » que si l'application se souvient d'avoir déjà demandé : un indicateur est gardé dans les préférences de l'application.
- Android 11 et 12 (API 30 à 32) : l'autorisation demandée est `READ_EXTERNAL_STORAGE`.
- Code Kotlin sans test unitaire (exception de `CLAUDE.md`) : procédure `HOWTO.md` §11. Non testé sur appareil.
