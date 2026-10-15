# BR-002 — Éjection d'un disque amovible

**Statut :** Active (validée le 2026-10-15) · **Créée le :** 2026-10-15 · **Ticket :** MPL-017 (contrôleur), MPL-035 (écouteur natif) · **Décisions :** D23, D25

## Contexte

Sans arrêt préalable du moteur, Android tue l'application environ 1 s après l'annonce d'éjection, car un descripteur reste ouvert sur le volume (`docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3).

## Règle

1. À l'annonce d'éjection du disque de la piste en cours, le contrôleur arrête d'abord le moteur et attend la fin de cet arrêt (moteur arrêté, descripteurs libérés), puis marque le disque indisponible.
2. À l'annonce d'éjection d'un autre disque, le contrôleur marque ce disque indisponible sans toucher au moteur. Ses pistes seront sautées (BR-001).
3. Une annonce d'éjection répétée pour le même disque n'a aucun effet supplémentaire.
4. Au retour d'un disque, le contrôleur le marque disponible. La lecture ne reprend pas d'elle-même (validé par le propriétaire le 2026-10-15).
5. Après l'arrêt dû à l'éjection, la lecture reste arrêtée sur la piste éjectée, avec un signalement ; elle ne passe pas à une piste d'un autre disque (validé par le propriétaire le 2026-10-15).
6. Le contrôleur ne ferme jamais lui-même un descripteur que le moteur lit encore ; le côté natif non plus.

## Hors périmètre

L'écouteur natif (`StorageVolumeCallback`), le canal d'événements et le test sur le Pixel : MPL-035.

## As-built

MPL-017, 2026-10-15. `PlayerController._onVolume`, port `VolumeEvents` (`lib/domain/storage/ports/volume_events.dart`) ; signalement `PlaybackStoppedByEjection`. Tests : groupe « BR-002 », avec un fake ; l'écouteur natif reste à faire (MPL-035).

- Un retrait sans annonce préalable (`VolumeRemoved`) est traité comme une éjection.
- Adaptateur `media_kit` : si mpv n'est pas inactif 5 s après l'arrêt, `stop()` rend la main, mais le descripteur n'est libéré qu'une fois mpv inactif (ADR-002).
- Limite : l'annonce d'éjection attend la fin de la commande en cours (par exemple l'ouverture d'une piste) avant d'arrêter le moteur. Marge non mesurée (MPL-035).
- Non testé sur appareil.
