# FR-012 — Repère de source

**Statut :** Brouillon (2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-045 (repère et affichage dans la liste), MPL-046 (modification), MPL-047 et MPL-048 (autres vues) · **Décisions :** D23 · **Lié :** FR-010, FR-011, BR-004, BR-008, ADR-012 · **Source :** `docs/design/HANDOFF.md` §4

## Besoin

On voit d'un coup d'œil d'où vient une piste, y compris quand le même morceau existe sur le téléphone et sur un disque. L'idée vient du propriétaire (MPL-041).

## Exigences

1. **Une source, un repère** (forme et couleur, jamais la couleur seule) : le stockage interne (« Local ») est un cercle neutre ; chaque disque amovible reçoit un repère propre : carré bleu, losange violet, triangle rose, hexagone olive, puis les mêmes formes en contour au-delà de quatre disques (`SourceMark`, FR-010).
2. **Attribution.** À l'enregistrement d'un disque amovible, son indice de repère (`markIndex`) est le plus petit indice libre parmi les disques déjà enregistrés. Deux disques ne partagent jamais le même repère. L'indice est enregistré dans la base de l'appareil (schéma v3, ADR-012) et ne change pas ensuite.
3. **Disques existants.** À la migration, les disques déjà enregistrés reçoivent les indices 0, 1, 2… dans l'ordre de leur enregistrement. Le stockage interne n'a pas d'indice : son repère est fixe.
4. **Affichage.** Le repère est sur chaque ligne de la liste de pistes, avant l'artiste, et garde sa couleur quand la source est absente (FR-011.6).
5. **TalkBack.** Le libellé de la ligne contient le nom de la source : « …, source T7 Shield » ; « Local » pour le stockage interne. Le repère lui-même est décoratif.
6. **Nom de la source** : le nom du volume donné par Android (FR-006.4) ; « Local » pour le téléphone, par les fichiers ARB.

## Hors périmètre

Choisir ou changer le repère d'un disque, légende dans l'écran des disques (MPL-046) ; repères dans le mini-lecteur, le lecteur, la file, les albums et les artistes (MPL-047, MPL-048) ; renommer un disque.

## À valider (PO)

- Les repères sont attribués dans l'ordre d'enregistrement des disques, sans choix de l'utilisateur avant MPL-046.
- Le nom affiché d'une source est celui d'Android (« T7 Shield »), pas « SSD » comme dans la maquette.

## As-built

À écrire à la livraison de MPL-045.
