---
description: Cadrer un besoin avant de coder — challenge, fiches en Brouillon, ticket au backlog, puis arrêt pour validation du PO
argument-hint: <besoin en une phrase, ou clé d'un ticket existant>
---

Cadre le besoin suivant : $ARGUMENTS

Rôle : analyste. N'écris aucun code applicatif ni aucun test dans cette étape.

1. **Contexte.** Lis `CLAUDE.md`, `docs/backlog.md` (dont la section Décisions), les fiches de
   `docs/fonctionnel/`, les ADR de `docs/technique/decisions/` et les fiches de `docs/technique/`
   liées à la zone touchée.
2. **Challenge.** La demande est-elle imprécise, sous-optimale, en conflit avec une règle critique
   ou une décision actée ? Un chemin plus simple existe-t-il ? Donne d'abord ta recommandation,
   justifiée brièvement. Si une question précise bloque la suite, pose-la (une seule à la fois)
   avant de rédiger.
3. **Fiches.** Crée ou mets à jour les fiches UC/BR/FR concernées dans `docs/fonctionnel/`
   (créer le dossier si absent) et les ADR dans `docs/technique/decisions/`
   (`ADR-NNN-<slug>.md`), toujours au statut `Brouillon`. Ne modifie jamais une fiche `Active` :
   un écart devient une ligne `À valider`.
4. **Ticket.** Dans `docs/backlog.md` : une ligne dans « Actifs » et une section dans « Détails »
   (description, exclusions, critères d'acceptation en Gherkin français, fiches liées). Utilise la
   « Prochaine clé » du fichier, puis incrémente-la et mets à jour « Dernière MAJ ».
5. **Arrêt.** Résume en 5 lignes maximum : recommandation, fiches en `Brouillon`, ticket créé,
   questions ouvertes. Attends la validation du PO. Tu ne passes pas toi-même une fiche à `Active`
   et tu ne commences pas l'implémentation.
