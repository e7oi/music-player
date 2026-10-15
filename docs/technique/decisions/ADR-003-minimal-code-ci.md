# ADR-003 — Minimal code CI job

**Status:** Active (validated 2026-10-15) · **Date:** 2026-10-15 · **Ticket:** MPL-017 · **Decisions:** D17, D30 · **Completed by:** MPL-026

## Context

`main` is protected by the `protect-main` ruleset (D17) with the required checks of `docs-ci`. No application code may reach `main` without a code CI job (decision of 2026-10-15).

## Decision

- New workflow `.github/workflows/code-ci.yml`, triggered like `docs-ci` (pull requests and pushes to `main`, manual dispatch), `permissions: contents: read`, actions pinned by commit SHA.
- One job `code-checks` on `ubuntu-24.04`, Flutter pinned to the version of ADR-001:
  1. `flutter pub get` with the committed `pubspec.lock` (`--enforce-lockfile`);
  2. `dart format --set-exit-if-changed .`;
  3. `flutter analyze --fatal-infos`;
  4. `flutter test` (includes `test/architecture/` and the contract suite against the fake).
- No Android build, no vulnerability, licence or permission check in this job: MPL-026.
- Dependabot gains the `pub` ecosystem (weekly, patch and minor grouped, D30).

## Consequences

- `code-checks` is a required check of `protect-main` since 2026-10-15, before the workflow exists. Until `code-ci.yml` reaches `main`, a pull request merges only if it brings the workflow itself: the cadrage documents of MPL-017 therefore travel on the MPL-017 branch.
- The job uses GitHub Actions minutes on every PR, documentation PRs included. Path filters are not used, because a required check that never runs blocks the merge.

## As-built

None (not implemented).
