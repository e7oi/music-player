# MusicPlayer

**Version du document :** 0.2 · **Dernière MAJ :** 05/10/2026

Lecteur audio local, **libre, gratuit, sans publicité, sans compte, sans télémétrie**, avec l'expérience d'un service de streaming moderne.

> **Statut :** prototype audio Android en cours de validation. Aucune version livrée. Voir `PRD.md`.

## Plateformes

| Plateforme | État |
|---|---|
| Android | En cours (prototype validé partiellement sur Pixel 10 Pro (lecture, arrière-plan écran verrouillé, notification et contrôles, persistance) ; Auto-test des formats en cours) |
| Windows 11, macOS | Prévus, en pause |
| iOS | Hors périmètre actuel |

## Stack

- Flutter / Dart (codebase unique)
- Moteur audio : `media_kit` (moteur unique) avec `just_audio` en repli Android — **provisoire**, voir `PRD.md` D2
- Contrôles système : `audio_service`
- Base locale : SQLite (bibliothèque indexée, à venir)

## Fonctionnalités visées

- Lecture de fichiers locaux (téléphone, disque interne ou externe)
- Bibliothèque indexée : tags, pochettes, recherche
- File d'attente, lecteur plein écran, contrôles système
- Accueil dynamique et mix automatiques générés à partir de la bibliothèque

## Vie privée

Aucune donnée ne quitte l'appareil. La build release ne déclare pas la permission `INTERNET` (vérifié, voir `docs/sprints/sprint-1/RESULTS.md`).

## Documentation

| Fichier | Contenu |
|---|---|
| `PRD.md` | Problème, périmètre, critères de succès, décisions structurantes |
| `CHANGELOG.md` | Historique des livraisons confirmées par test réel |
| `HOWTO.md` | Procédures pratiques (environnement, build release, validation, Auto-test, flux Git) |
| `docs/sprints/` | Clôtures, démarrages et résultats de sprint (snapshots figés) |

## Installation

À compléter après la première version livrée. En attendant, voir `HOWTO.md` pour préparer l'environnement et compiler.

## Contribuer

`main` est protégée : toute modification passe par une pull request dont les contrôles (format, analyse, tests, sécurité, documentation) sont au vert. Voir `HOWTO.md` §9.

## Licence

Copyright © 2026 Eloi BERTIN. Distribué sous licence GPL-3.0-or-later (voir le fichier `LICENSE`). Le nom de l'application n'est pas encore défini.
