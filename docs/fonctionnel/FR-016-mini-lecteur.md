# FR-016 — Mini-lecteur

**Statut :** Active (validée le 2026-10-23) · **Créée le :** 2026-10-23 · **Ticket :** MPL-047 · **Lié :** UC-007, FR-001, FR-005, FR-009, FR-010, FR-012, BR-002, BR-007, ADR-010, ADR-015 · **Source :** `docs/design/HANDOFF.md` §5 (écran 5, mini-lecteur), `MiniLecteurs.dc.html`

## Besoin

Voir ce qui joue et le commander depuis chaque vue, sans rien recouvrir. Le mini-lecteur remplace la barre de lecture provisoire (UC-001, FR-009.5).

## Exigences

1. **Présence.** Le composant `MiniPlayer` (`lib/ui/widgets/`, FR-010) est posé par la coquille (FR-009) au-dessus de la barre de navigation, ou en bas de la colonne de contenu à côté du rail en paysage. Il est visible tant que la file a une piste courante, y compris à l'arrêt ; il est absent quand la file est vide. Il n'est pas dans les sous-écrans (Dossiers, Disques, lecteur plein écran), qui couvrent la coquille.
2. **Mesures.** Hauteur 64 dp, marges 8 dp, rayon 16, fond `surfaceContainerHigh`. Au-delà de 1,3 fois l'échelle du texte, la hauteur grandit sans rien couper.
3. **Contenu.** Pochette 48 dp (rayon 8, tuile neutre sans pochette) ; titre en une ligne (nom du fichier sans titre, tronqué) ; deuxième ligne : repère de source (10 dp, FR-012) puis artiste (« Artiste inconnu » sans étiquette) ; précédent, lecture/pause (bouton plein `primary`) et suivant, 48 dp chacun ; fine barre de progression de 2 dp au bas.
4. **Ouvrir le lecteur.** Toucher la partie gauche (pochette et textes) ou glisser vers le haut ouvre le lecteur plein écran (FR-017) ; la pochette est l'élément partagé de la transition.
5. **Commandes.** Précédent, lecture/pause et suivant appellent le contrôleur et suivent FR-001 (« précédent » après 3 s reprend la piste). Aucun bouton n'est désactivé pendant le chargement.
6. **Progression.** La barre suit la position, rafraîchie au plus 4 fois par seconde (ADR-015) ; sans durée connue, elle reste vide.
7. **Source perdue.** Quand la lecture s'est arrêtée parce que le disque de la piste a été retiré (BR-002), la deuxième ligne devient « Arrêt : {disque} débranché » en `tertiary` avec l'icône de prise débranchée, la pochette passe à 50 %, et le bouton montre « Lecture ». Cet état dure jusqu'à ce que l'utilisateur lance une lecture ; il ne se lève pas au rebranchement (décision du 2026-10-15). « Lecture » relance la file : les pistes du disque absent sont sautées (BR-001).
8. **Accessibilité.** La zone d'ouverture a le libellé « Ouvrir le lecteur » et dit titre, artiste et source (« …, source T7 Shield ») ; chaque bouton a un libellé ; le repère est décoratif ; l'état « source perdue » est dit en texte, jamais par la couleur seule (BR-007, règle 3).
9. **Règles d'interface.** Jetons seulement, clair et sombre, animations réduites respectées (BR-007).
10. **Textes.** Dans les fichiers ARB, en français mot pour mot des maquettes (« Ouvrir le lecteur », « Piste précédente », « Lecture », « Pause », « Piste suivante », « Arrêt : {disque} débranché »), avec la version anglaise.

## Hors périmètre

Glisser horizontalement pour changer de piste, fermer ou arrêter depuis le mini-lecteur, panneau lecteur permanent des écrans larges (MPL-048), curseur de position dans le mini-lecteur (réservé au lecteur plein écran).

## À valider (PO)

- Exigence 1 : pas de mini-lecteur dans les sous-écrans Dossiers et Disques (comme la barre actuelle).
- Exigence 7 : l'état « source perdue » reste affiché tant qu'on ne relance pas la lecture, même si le disque revient.
- Exigence 3 : « Artiste inconnu » vient de la maquette ; l'application l'écrit déjà dans la liste (FR-011).
- FR-010, exigence 1, annonce `MiniPlayer` avec ce lot : l'as-built de FR-010 sera complété à la livraison.

## As-built

MPL-047, 2026-10-23, test appareil en attente (D14). `MiniPlayer` et `MiniPlayerProgress` (`lib/ui/widgets/mini_player.dart`), branchés par `MiniPlayerBar` (`lib/features/player/mini_player_bar.dart`) dans la coquille à la place de l'ancienne barre (`player_bar.dart` supprimé). Tests : `test/ui/widgets/mini_player_test.dart`, `test/features/player/player_flow_test.dart`.

- La progression passe par `playerPositionProvider` (au plus 4 mises à jour par seconde) ; le reste du mini-lecteur ne se redessine pas à chaque tic. Il regarde la piste par `trackIndexProvider` (liste limitée à deux émissions par seconde), ce qui règle le reste de MPL-045 sur la barre de lecture.
- « Source perdue » : `stopCauseProvider` garde la dernière cause d'arrêt (éjection ou échecs) jusqu'à ce que `playing` redevienne vrai.
- L'icône de prise remplace le repère de source dans l'état « source perdue ».
