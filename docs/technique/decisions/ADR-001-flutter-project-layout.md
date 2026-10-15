# ADR-001 — Flutter project at the repository root

**Status:** Active (validated 2026-10-15) · **Date:** 2026-10-15 · **Ticket:** MPL-017 · **Decisions:** D2, D3, D7, D8, D10, D30

## Context

`CLAUDE.md` fixes a single Flutter package with a `lib/` ports-and-adapters layout, enforced by `test/architecture/`. `HOWTO.md` §2 still describes the prototype command, which created the app in a `musicplayer/` subdirectory.

## Decision

- The production app is one Flutter package at the repository root (`pubspec.yaml`, `lib/`, `test/`, `integration_test/`, `android/`), created with `flutter create --org net.trtl3 --platforms=android` (D7). Windows and macOS are not generated while paused (D10, MPL-014).
- Flutter is pinned to the latest stable release on the day the ticket starts, in `pubspec.yaml` (`environment.flutter`) and in CI; `pubspec.lock` is committed (D30). The exact version is recorded in the as-built section.
- Dependencies at start: `flutter_riverpod` (hand-written providers, no code generation), `media_kit` and its Android libs, `meta`, `collection`; dev: `very_good_analysis`, `riverpod_lint`. Drift is not added before MPL-018 needs it.
- `test/architecture/` checks the import rules of `CLAUDE.md` by scanning the `import` directives of `lib/`.
- `HOWTO.md` §2 is updated to the root layout.

## Consequences

- Root documents and the app share the root; `check-repo.sh` keeps working (it only checks documents and forbidden tracked files).
- `.gitignore` gains the Flutter and Android entries (`build/`, `.dart_tool/`, `android/local.properties`, …).

## Alternatives considered

- App in `musicplayer/` (prototype layout): every CI step and command needs a working directory, and the paths of `CLAUDE.md` would be wrong. Rejected.

## As-built

None (not implemented).
