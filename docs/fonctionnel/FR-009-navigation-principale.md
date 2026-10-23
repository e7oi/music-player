# FR-009 — Navigation principale

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-016 · **Lié :** UC-004, FR-008, FR-010, BR-007, ADR-010 · **Source :** `docs/design/HANDOFF.md` §3

## Besoin

L'utilisateur circule entre les quatre vues principales par une navigation qui s'adapte à la largeur de l'écran.

## Exigences

1. **Onglets** : Pistes, Albums, Artistes, Réglages, dans cet ordre. Onglet de départ : Pistes. Pas d'onglet Recherche, Playlists ou Favoris.
2. **Contenu dans ce ticket** : Pistes montre la bibliothèque actuelle (UC-001) avec ses boutons Dossiers, Disques et Actualiser inchangés ; Albums, Artistes et Réglages affichent leur titre et un message « bientôt ». Le contenu réel vient avec MPL-048.
3. **Largeur** (classes de largeur Material 3) : moins de 600 dp, barre de navigation en bas ; de 600 dp à 839 dp, rail de navigation ; 840 dp et plus, rail de navigation. Le téléphone en paysage (environ 915 dp) est en classe étendue.
4. **Rotation** : l'onglet courant, la position des listes et la lecture ne changent pas.
5. **Barre de lecture** : la barre de lecture actuelle reste au-dessus de la navigation (placement provisoire jusqu'au lot Lecture, MPL-047).
6. **Sous-écrans** : Dossiers et Disques s'ouvrent par-dessus la vue courante, avec retour.
7. **Retour système** : depuis Albums, Artistes ou Réglages, il ramène sur Pistes ; depuis Pistes, il quitte l'application.
8. **Pas de routeur** : les vues se changent sans paquet de routage (ADR-010) ; les noms de routes de `HANDOFF.md` §3.2 sont une référence de documentation.
9. **Libellés** : dans les fichiers ARB, en français (mot pour mot des maquettes) et en anglais.
10. L'onglet courant n'est pas conservé entre deux lancements.

## Hors périmètre

Panneau lecteur permanent et paysage complet (MPL-047, MPL-048), mini-lecteur définitif (MPL-047), recherche, routes nommées.

## À valider (PO)

- Exigence 7 : le geste Retour revient sur Pistes avant de quitter (choix de comportement non précisé par Design).
- Exigence 10 : l'application s'ouvre toujours sur Pistes.

## As-built

MPL-016, 2026-10-23. `HomeShell` (`lib/features/shell/`), branché dans `lib/app/app.dart` avec `LibraryPage` et `PlayerBar`. Tests : `test/features/shell/home_shell_test.dart`.

- Le contenu des vues reste dans une `GlobalKey` : à la rotation, la barre devient un rail sans perdre l'état des vues (l'arbre de widgets change, la clé le préserve).
- Le rail affiche les libellés sous les icônes ; la barre du bas hérite de la hauteur de `TsSize.navBar`.
- Retour système : `PopScope` sur la coquille.
- **Non testé sur appareil** : paysage, geste Retour entre onglets.
