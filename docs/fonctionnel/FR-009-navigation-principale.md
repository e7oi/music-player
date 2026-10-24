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
- Ajout du 2026-10-23 : le retour (flèche et geste) depuis le choix des dossiers ouvert par l'utilisateur, absent de FR-003 (`Active`) et de la spécification de Design (écran 2) ; à confirmer.

## As-built

MPL-016, 2026-10-23. `HomeShell` (`lib/features/shell/`), branché dans `lib/app/app.dart` avec `LibraryPage` et `PlayerBar`. Tests : `test/features/shell/home_shell_test.dart`.

- Le contenu des vues reste dans une `GlobalKey` : à la rotation, la barre devient un rail sans perdre l'état des vues (l'arbre de widgets change, la clé le préserve).
- Le rail affiche les libellés sous les icônes ; la barre du bas hérite de la hauteur de `TsSize.navBar`.
- Retour système : `PopScope` sur la coquille.
- La barre de lecture, montée dans la coquille, est maintenant présente aussi pendant le chargement, le refus de permission et le choix des dossiers ; elle est vide tant que rien ne joue. Avant, elle n'apparaissait que dans la bibliothèque prête ou le choix des dossiers.
- Paysage, vu sur le Pixel le 2026-10-23 avec l'encoche à gauche : le rail laissait une bande vide et le décalage de l'encoche était appliqué une seconde fois aux vues (titre et lignes repoussés de 177 px). Corrigé : le fond du rail couvre tout le bord de l'écran, ses éléments restent à l'écart de l'encoche dans une `SafeArea`, et les vues reçoivent un `MediaQuery` sans ce décalage (3 tests, `home_shell_test.dart`). Le panneau lecteur à droite (maquette 6e) et la mise en page de la liste en largeur ne sont pas faits (MPL-047, MPL-048).
- Hors périmètre, nécessaire pour que les tests de page passent : `playerStateProvider` (`app/providers/player_providers.dart`) s'abonne au flux avant de lire l'état courant. Avant, un état émis entre les deux se perdait (disques disponibles non reçus : pistes grisées à tort). Les tests de page de `library_page_test.dart` étaient rouges sans ce correctif ; `test/app/player_state_provider_test.dart` est un garde qui ne reproduit pas la course de façon déterministe.
- Retour depuis « Dossiers de musique » (ajouté après le test du propriétaire sur le Pixel, 2026-10-23) : ouvert depuis la bibliothèque, le choix des dossiers montre une flèche de retour et le geste Retour du système y répond, au lieu de mettre l'application en arrière-plan ; au premier lancement, où le choix est obligatoire (FR-003.3), il n'y a ni flèche ni retour. `LibraryController.cancelFolderChoice`, `canCancelFolderChoice` ; tests `library_controller_test.dart` et `library_page_test.dart`. Limite : si le choix est ouvert dans Pistes et que l'utilisateur est sur un autre onglet, le geste Retour ferme aussi ce choix avant de revenir sur Pistes.
- **Non testé sur appareil** : paysage, geste Retour entre onglets, sous-écrans (exigence 6, couverte seulement par les écrans existants).
- MPL-047, 2026-10-23 : l'exigence 5 est remplie par `MiniPlayerBar` (FR-016) à la place de la barre provisoire, au même endroit de la coquille. Le panneau lecteur permanent n'est pas fait (voir le backlog : MPL-048). Non testé sur appareil.
- MPL-048, 2026-10-23 : Albums et Artistes ne sont plus « bientôt » (exigence 2) ; chacun a son navigateur dans la coquille et le Retour système y entre avant de ramener sur Pistes (exigence 7, ADR-016). Réglages reste « bientôt » jusqu'à MPL-051. Le panneau lecteur permanent est dans MPL-052. Non testé sur appareil, hors le détail d'un album et son Retour vus sur le Pixel.
