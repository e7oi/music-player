# BR-010 — Regroupement des pistes en albums et en artistes

**Statut :** Brouillon · **Créée le :** 2026-10-23 · **Ticket :** MPL-048 · **Décisions :** D23 · **Lié :** UC-008, FR-020, FR-021, BR-004, BR-008 · **Source :** `docs/design/HANDOFF.md` §4 (« Albums groupés… », « Artistes groupés… »)

## Règles

1. **Artiste de l'album** d'une piste : son `albumArtist` s'il est renseigné, sinon son `artist`, sinon « Artiste inconnu ». Les espaces autour sont ignorés.
2. **Album** : l'ensemble des pistes qui ont la même **clé** (artiste de l'album, titre de l'album). Un titre d'album absent donne « Album inconnu ». Il y a donc un « Album inconnu » par artiste de l'album.
3. **Comparaison** : la clé ignore la casse et les accents (comme l'index de la liste, FR-011.7) et les espaces en trop. L'affichage garde l'écriture la plus fréquente parmi les pistes du groupe, à égalité la première dans l'ordre des pistes.
4. **Plusieurs sources** : un album dont les pistes sont sur le téléphone et sur un disque est un seul album. Il porte les repères de ses sources (au plus trois montrés, FR-012).
5. **Artiste** : l'ensemble des albums qui ont le même artiste de l'album (comparaison de la règle 3). Un artiste qui n'apparaît que comme artiste de piste (« feat. ») n'a pas d'entrée propre ; ses pistes sont sous l'artiste de leur album.
6. **Ordre des pistes d'un album** : numéro de disque (absent = 1), puis numéro de piste (absent après les numérotés), puis titre replié, puis chemin.
7. **Ordre des albums** : artiste de l'album replié, puis année croissante (absente en dernier), puis titre replié. Les artistes sont triés par nom replié. « Artiste inconnu » est dans le groupe « # » avec les noms qui commencent par un chiffre ou un symbole (FR-013, `alphabetKey`).
8. **Année d'un album** : la plus ancienne année renseignée de ses pistes. **Pochette** : celle de la première piste de l'ordre de la règle 6 qui en a une ; sinon la tuile neutre. **Durée** : somme des durées connues.
9. **Disponibilité** (BR-008, règle 1) : un album ou un artiste est indisponible quand toutes ses pistes le sont. Sinon il est disponible et ses pistes indisponibles sont grisées dans le détail.
10. **Mise à jour** : les groupes se recalculent à chaque émission de la liste des pistes (au plus deux par seconde, comme FR-011.11). Une piste retirée de la bibliothèque (BR-004) sort de son groupe ; un groupe vide disparaît.

## Cas limites

- Piste sans aucune étiquette : « Artiste inconnu », « Album inconnu » ; le titre est le nom du fichier.
- Même titre d'album chez deux artistes (« Greatest Hits ») : deux albums.
- Disque d'un album numéroté 0 ou négatif : traité comme absent (comme `NowPlaying`, FR-017.4).

## À valider (PO)

- **Limite connue :** une compilation sans étiquette « artiste de l'album » (un `artist` différent par piste) se découpe en autant d'albums d'une piste qu'il y a d'artistes. La conception le prescrit ainsi. Une compilation étiquetée « Various Artists » reste groupée. À juger sur la bibliothèque réelle ; une règle de rattachement par titre d'album est possible plus tard.
- Règle 2 : un « Album inconnu » par artiste, et non un seul pour toute la bibliothèque comme dans la maquette (« Album inconnu · Artiste inconnu · 37 pistes » ne montre que l'artiste inconnu).
- Règle 8 : année la plus ancienne.

## As-built

À écrire à la livraison.
