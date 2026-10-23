# BR-006 — Descripteurs ouverts sur un disque amovible

**Statut :** Active (validée le 2026-10-22) · **Créée le :** 2026-10-22 · **Ticket :** MPL-037 (règles), MPL-035 (interruption à l'éjection) · **Décisions :** D25 · **Lié :** BR-002, FR-006, FR-007

## Contexte

Un descripteur resté ouvert sur le volume quand Android l'éjecte fait tuer l'application environ 1 s plus tard (BR-002, contexte). Ce n'est pas seulement la lecture : le parcours et la lecture des tags ouvrent aussi des fichiers du volume. Sur `content://`, `media_kit` ne ferme le sien qu'au ramasse-miettes (un descripteur de plus par piste, `docs/sprints/sprint-2/RESULTS-PROTOTYPE-ANDROID.md` §4.3).

## Règles

1. La lecture donne au moteur un descripteur détaché sous la forme `fd://N` (D25). Le côté natif ne ferme pas ce descripteur de lui-même tant que le moteur peut le lire (BR-002, règle 6).
2. Le nombre de descripteurs ouverts sur le volume ne croît pas avec le nombre de pistes lues : après une série d'ouvertures et d'arrêts, il revient à son niveau de départ.
3. La lecture d'un tag ou d'une pochette ouvre un fichier, le lit, le ferme aussitôt, y compris en cas d'erreur. Aucun descripteur n'est gardé entre deux fichiers.
4. Le nombre de fichiers lus en même temps pour les tags est limité (valeur à mesurer sur le Pixel, ADR-009) pour ne pas saturer le disque ni gêner la lecture en cours.
5. À l'annonce d'éjection d'un disque, le parcours et la lecture des tags de ce disque s'arrêtent et ferment leurs descripteurs avant que le disque soit marqué indisponible, en même temps que l'arrêt du moteur (BR-002, règle 1). Cette règle est livrée avec l'écouteur natif (MPL-035) ; MPL-037 doit seulement permettre d'annuler le parcours et la lecture (annulation prévue dans les ports).
6. Une annulation ne supprime ni piste ni information déjà enregistrée ; elle laisse les pistes concernées « en attente » (FR-007.3).

## À valider (PO)

- BR-002 (`Active`) ne parle que du moteur ; la règle 5 étend le même principe au parcours et à la lecture des tags sans la modifier. À confirmer que cette fiche suffit, sans ligne sur BR-002.

## Écarts constatés à la livraison (À valider, PO)

- Règle 5 : l'arrêt à l'annonce d'éjection n'est pas câblé (MPL-035).

## As-built

MPL-037, 2026-10-22. Règle 1 : `RemovableTrackSourceOpener` rend `DescriptorMediaSource` (le moteur ferme, BR-002) ; Kotlin `openFd` détache le descripteur seulement après l'ouverture réussie. Règle 3 : `readTags` ouvre, lit, ferme dans un `finally`. Règle 4 : `TagIndexer.parallelism` vaut 2 par défaut, **non mesuré**. Règles 5 et 6 : `cancel()` du `TagIndexer` et du parcours arrête entre deux fichiers ou deux dossiers ; ce qui est lu est gardé, le reste reste « en attente ». Tests : `test/platform/removable_storage_channel_test.dart`, `test/domain/library/tag_indexer_test.dart`.

- Aucune lecture native n'est interrompue en cours et il n'y a pas de délai maximal ; une lecture bloquée sur un disque en cours d'éjection bloque la passe (MPL-035).
- **Non testé sur appareil** : règles 2 et 3 (comptage des descripteurs), valeur de la règle 4.
