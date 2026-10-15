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

## À valider

- Exigence 4 : quand Android signale « ne plus demander », le bouton tente d'abord la demande d'Android, car ce signal arrive aussi après une demande simplement fermée ; il n'ouvre les réglages que si l'accès n'est toujours pas accordé. Conséquence : un refus explicite à ce moment ouvre aussitôt les réglages. À confirmer.

## As-built

MPL-018, 2026-10-15. `MediaStoreChannel.kt` (Kotlin) et `lib/platform/media_store_channel.dart` ; logique dans `LibraryController` (`lib/features/library/library_controller.dart`). Tests : `test/features/library/library_controller_test.dart`, `test/platform/`.

- Android ne distingue « ne plus demander » de « jamais demandé » que si l'application se souvient d'avoir déjà demandé : un indicateur est gardé dans les préférences de l'application.
- Android 11 et 12 (API 30 à 32) : l'autorisation demandée est `READ_EXTERNAL_STORAGE`.
- Les lancements suivants ne redemandent pas l'accès d'eux-mêmes : seul le premier lancement le fait (état « jamais demandé »).
- Android signale aussi « ne plus demander » quand l'utilisateur a seulement fermé la demande sans répondre. Le bouton tente donc d'abord la demande d'Android, et n'ouvre les réglages que si l'accès n'est toujours pas accordé.
- Retirer l'autorisation dans les réglages redémarre l'application (comportement d'Android) : l'exigence 5 se constate au redémarrage, avec le message d'explication et sans nouvelle demande.
- Code Kotlin sans test unitaire (exception de `CLAUDE.md`) : procédure `HOWTO.md` §11. Non testé sur appareil.
