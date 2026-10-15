# CLAUDE.md — MusicPlayer (`music-player`)

> Product context and scope live in `PRD.md` (§9 decisions, §10 risks). The backlog and the decision register live in `docs/backlog.md`; `docs/sprints/` holds frozen sprint snapshots. Do not duplicate them here.

## Working with the owner

- Talk to the owner in French. Everything written in the repository follows the language table below.
- Read the real state of the repository before writing. Restore nothing from memory. Invent nothing.
- Never close an item without a real test on the Pixel, release build, confirmed by the owner (D14). Write "not tested" rather than "OK".
- Do not start work outside the item you were given (MPL key). Report gaps and contradictions instead of choosing.

## Git and repository rules

- Never push to `main`. Work on a branch, one reversible commit per fix. Open no pull request unless asked; the owner creates PRs.
- `main` is protected (ruleset `protect-main`, D17). No application code reaches `main` without a code CI job: MPL-017 adds a minimal job (format, analyze, test); MPL-026 completes it (vulnerabilities, licenses, permission allow-list, libmpv checksum).
- Git identity is the owner's name and GitHub noreply address, set locally in each MusicPlayer clone, never globally. Check `git config user.name` and `git config user.email` against the last commits (`git log -1 --format='%an <%ae>'`) before the first commit.
- Two repositories, two clones. Never add one as a remote of the other. `music-player-prototype` is private and never becomes public.
- Nothing private in this public repository: no track titles, artist or album names, file names, device paths, volume or serial identifiers, e-mail addresses. Test exports (CSV, logs, logcat) stay outside the repository (D27).
- Root documents stay at the root and sprint snapshots in `docs/sprints/` are frozen. Keep `.github/scripts/check-repo.sh` passing.

## Language (D28)

| Element | Language |
|---|---|
| Identifiers, files, directories, DB tables and columns, ARB keys | English |
| Code comments, dartdoc, Kotlin comments | English |
| Commit messages (Conventional Commits), branch names | English |
| PR titles and descriptions | English |
| Test names and groups | English |
| Exception messages, logs, diagnostics | English |
| User-visible strings | ARB files, never inline |
| Product and process documents (`PRD.md`, `README.md`, `CHANGELOG.md`, `HOWTO.md`, `docs/sprints/*`) | French |
| New technical reference documents (architecture, dependency exceptions) | English |

Principle: anything that is part of the code base or its history is English; anything the owner reads as product or process prose stays French. A comment explains why, never what.

## Architecture

Ports and adapters, kept light. One Flutter package, `lib/` layout:

```text
lib/
  main.dart        bootstrap only
  app/             composition root: provider wiring (app/providers/), router, theme
  domain/<area>/   pure Dart: model/, ports/ (interfaces), services/ (incl. PlayerController)
  data/<area>/     adapters: Drift database, media_kit engine, scanner
  platform/        Dart side of Android channels (SAF, volume events); Kotlin lives in android/
  features/<name>/ presentation: widgets and Riverpod notifiers
  l10n/            ARB files and generated localizations
```

Dependency rules (enforced by `test/architecture/`, see Tooling):

1. `domain/` imports only `dart:core`, `dart:async`, `dart:math`, `dart:convert`, `package:meta`, `package:collection` and itself. Never Flutter, `dart:io`, `dart:ui`, Drift, Riverpod, `media_kit`, `audio_service`.
2. `data/` and `platform/` import `domain/` only (plus their own third-party package). They never import `features/` or `app/`.
3. `features/` import `domain/`, `l10n/` and `app/providers/` only. Never `data/` or `platform/`.
4. `package:media_kit` is imported only under `data/audio/`. Drift only under `data/db/`. `package:flutter/services.dart` (channels) only under `platform/` and `app/`.
5. Always use package imports (`always_use_package_imports`); no relative imports under `lib/`.
6. One port per real boundary (engine, volume events, source opening, repositories). A fake in `test/` counts as the second implementation. No port without a boundary, no one-class-per-use-case ceremony, no separate application layer.

## Audio engine contract (D2)

`media_kit` is the only engine, behind the `AudioEngine` port in `domain/playback/ports/`. There is no engine selector (`engineFactories` and `switchEngine` are prototype-only and are not ported).

- Write the contract as dartdoc on the interface and as an executable suite `test/contract/audio_engine_contract.dart`, run against `FakeAudioEngine` in CI and against the `media_kit` adapter in `integration_test/` on a device.
- `open` loads without starting playback and may return before the duration is known; the duration arrives on `durationStream`. The `loading` state is not guaranteed.
- `play()` returns once playback is requested. `playing` is the intent and stays true across tracks.
- `completed` is emitted once per track.
- `stop()` returns only after the engine has stopped reading and every resource, file descriptors included, is released. It is idempotent.
- Engine problems are typed: `sealed class EngineIssue` with `EngineFailure` (fatal for the current track: the controller skips or reports) and `EngineWarning` (never changes state, logged and counted). Adapters classify; the controller switches exhaustively. `end-file` with an error reason is always a failure; unclassified messages are warnings of kind `unclassified`. Classification tests use recorded real messages (MPL-010).

## Storage and removable volumes (D25, D23)

- Internal storage: MediaStore and file path. Removable storage: SAF, and `media_kit` reads it through `fd://N` obtained from `openFileDescriptor` + `detachFd`. Never a direct `content://` (leaks a descriptor per track) and never `/proc/self/fd/N` (EACCES).
- Volume ejection goes through the `VolumeEvents` port (`domain/storage/ports/`), implemented in `platform/` over an EventChannel and a native `StorageVolumeCallback`. The controller never imports a channel.
- On `ejecting` for the disk of the current track: `await engine.stop()` first, then mark the disk unavailable. Never close a descriptor the engine still reads. The native side must not close descriptors on its own.
- A track is identified by (disk, relative path); the disk by its filesystem UUID. Tracks of an absent disk stay in the library, greyed, and are skipped during playback with a message.

## Android carry-over rules from the prototype

- Keep `android/app/src/main/res/raw/keep.xml` (notification icons are stripped in release otherwise).
- The adapter's `playing` state means the intent to play, not the engine's momentary state.
- The notification permission is requested natively in `MainActivity`; do not add `permission_handler`.
- No telemetry and no network in release (D15, D26). `INTERNET` is declared only in a dedicated online build variant.

## Testing

- Test first for `domain/` and for state logic (Riverpod notifiers): red, green, refactor. A bug fix starts with a failing test when the bug is reproducible off-device.
- Prefer fakes over mocks for ports. Drift tests use an in-memory database; schema migrations are tested from the committed schema dumps.
- Exceptions to test-first, to be stated in the PR: native Kotlin glue (SAF, storage callbacks) and on-device protocols (background playback, lock screen, ejection, SSD): a written procedure in `HOWTO.md` replaces the unit test and the result is reported as tested or not tested; layout (widget tests check behaviour, no golden files); generated code; trivial wiring in `app/`.
- Untested logic shipped anyway is reported as debt in the PR description, never silently.
- Device tests: Pixel 10 Pro, release build, `adb` over Wi-Fi when the SSD uses the USB-C port, `ANDROID_SERIAL` if several devices, phone unplugged for background tests, do not touch the app during an Auto-test.

## Tooling

Commands below exist once MPL-017 has landed; do not assume them before.

- Format: `dart format --set-exit-if-changed .`
- Analyze: `flutter analyze --fatal-infos`, with `very_good_analysis`, `strict-casts`, `strict-inference`, `strict-raw-types` and the `riverpod_lint` analyzer plugin.
- Tests: `flutter test` (includes `test/architecture/`); device tests with `flutter test integration_test`.
- Generated code: Drift only (`dart run build_runner build --delete-conflicting-outputs`); `*.g.dart` files are committed, marked `linguist-generated`, excluded from analysis, and CI checks they are up to date with `git diff --exit-code` after regeneration. Riverpod providers are written by hand, no Riverpod code generation, no `freezed`.
- Localization: `flutter gen-l10n`; generated files committed under `lib/l10n/`; CI fails on a key missing in any shipped locale.

## Dependencies and versions (D30, provisional)

- Use the latest stable release of languages, tools and libraries, for security, features and performance, as long as the pinned Flutter release supports it. The Flutter tool is the compatibility matrix: Gradle, AGP and Kotlin never go above the `maxKnownAndSupported*` values of `packages/flutter_tools/lib/src/android/gradle_utils.dart` at the pinned Flutter tag, and `compileSdk`, `targetSdk`, `minSdk` and NDK start from the Flutter template defaults (`FlutterExtension.kt`).
- Pin everything: Flutter version in `pubspec.yaml` and CI, `pubspec.lock` committed, Gradle wrapper with `distributionSha256Sum`, GitHub Actions by commit SHA, libmpv by SHA-256 (MPL-026). No `any`, no git or path dependency, no pre-release on `main`.
- Updates by Dependabot (weekly): patch and minor grouped; each major in its own PR; Flutter SDK, Gradle wrapper, AGP and Kotlin bumped by hand.
- A major bump touching playback, storage or notifications (`media_kit`, `audio_service`, Gradle, AGP) needs a device smoke test before merge.
- Security advisories (GitHub Advisory Database, shown by `dart pub get`) are fixed out of cycle. `ignored_advisories` in `pubspec.yaml` needs a written justification. A vulnerability scan on `pubspec.lock` runs in CI (MPL-026).
- A dependency that lags upstream (native libraries, `media_kit` Android libs) is an exception: record package, held version, blocker, and a review date within 90 days in `docs/dependency-exceptions.md`.
- Native libraries (libmpv, FFmpeg) are out of scope here (separate prompt).

## Commits and pull requests

- Conventional Commits with the backlog key: `type(scope): imperative summary (MPL-018)`, header at most 72 characters, body explains why.
- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`. Scopes: `library`, `playback`, `storage`, `db`, `ui`, `l10n`, `deps`, `ci`, `android`.
- Several keys when needed: `(MPL-017, MPL-035)`. A breaking change adds `!`.
- PR description (English): what changed, why, how it was tested (device and result, or "not tested"), known gaps. Squash merge; the PR title is the commit header.

## Workflow (Claude Code only)

<!-- workflow-block v5 (code seul), PR variant -->

Role: analyst + tech lead / developer in a single session. The owner (PO) decides and closes tickets. Claude Chat does not write or modify this project (read-only brainstorming at most). Process prose in `docs/` stays French (language table above).

### Frame before coding

Every non-trivial ticket starts with `/cadrer` (`.claude/commands/cadrer.md`), in plan mode: challenge the request, write UC/BR/FR sheets as `Brouillon` in `docs/fonctionnel/`, ADRs in `docs/technique/decisions/` (`ADR-NNN-<slug>.md`), and the ticket in `docs/backlog.md`, then **stop** for the owner's validation. No code until the sheets concerned are `Active`.

- `docs/backlog.md` is written and maintained by you; the owner reviews the diff. Statuses: À faire → En cours (you start) → À tester (you deliver) → Terminé; Bloqué stays possible. You set a ticket to Terminé only on the owner's explicit order ("validé"), after the real device test (D14) **and** after the PR is merged.
- Loose idea ("note au backlog : X"): one "À faire" line in Actifs with a one-line description, no sheets, no `/cadrer`.
- A decision taken in discussion, settled or rejected: one line in the Décisions section (Tranchée / Ouverte / Provisoire / Écartée) with the reason. A discussion without a decision is written nowhere. Do not number a decision yourself: propose the row, the owner assigns `Dn`.
- Sheet missing or `Brouillon` at implementation time: stop and say so. Never change an `Active` BR on your own: a gap or an uncovered case becomes an `À valider` line. Unsettled architecture or scope decision: stop and ask.
- Once `docs/fonctionnel/` has sheets with identifiers, put `@implements` / `@verifies` / `@decision` in dartdoc just above the symbol that implements or tests the rule.

### Branches and pull requests

- One ticket = one branch `mpl-NNN-<slug>`, created from `main` when the ticket goes "En cours". All the ticket's commits (code, sheets, as-built, Livraison block) live there. Never push to `main`.
- Delivering "À tester" = branch pushed, verification green, PR description (what, why, how tested, known gaps) written in the Livraison block. The owner creates the PR and tests on the Pixel.
- On "validé": wait for the owner's squash merge, then `git switch main && git pull`, delete the local and remote branch, and close the ticket (Terminé, moved to Terminés). `main` is protected, so the closure commit (`docs(backlog): close ticket after owner validation (MPL-NNN)`) goes on the next ticket's branch, or on a short `docs/close-mpl-NNN` branch if the owner wants it right away.
- Docs-only changes without a ticket go on a `docs/<slug>` branch, also through a PR.

### Definition of Done

1. Need understood (`Active` sheets read).
2. Implemented, test first for `domain/` and state logic.
3. Verification green and the ticket's Gherkin scenarios green; quote the command and the result. Until MPL-017 lands: `.github/scripts/check-repo.sh`. Afterwards: `dart format --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test`. Anything only verifiable on a device stays "not tested" until the owner confirms (D14).
4. As-built docs of the sheets touched updated in the same commit.
5. QA review ✅ (below), or not required.

A missing point means status ⚠️ in the Livraison block, never ✅.

### QA review: automatic

Except for logic-free quickfixes (style, text, config), run a fresh-context sub-agent in review mode. Give it only the ticket, the sheet IDs and the diff, never your reasoning. Blockers: fix and rerun (2 rounds max), then ⚠️. Playback, storage access, permissions, database migrations: review mandatory, and tell the owner a separate `>>> REVUE` session is possible.

Review mode: observe, fix nothing. Read the sheets and the diff before the developer's delivery. Check: BR/FR respected and Gherkin scenarios covered by a test, edge cases, traceability tags, standards (this file), security and private data (no track titles, paths or volume identifiers in the repository, D27), as-built sheets, out-of-scope changes. Every finding cites the rule ID and file:line. "Non vérifié" is mandatory.

### End of task

Add (or update) a **Livraison** block under the ticket in the "Détails" section of `docs/backlog.md`, committed with the task, and set the ticket to "À tester" (status ⚠️ or ❌: leave it "En cours" or "Bloqué"). Format (French, process prose):

```text
#### Livraison — AAAA-MM-JJ
Statut : ✅ fait / ⚠️ partiel / ❌ bloqué
Résumé : <2-3 lignes>
Fiches touchées : <IDs, as-built mis à jour ou inchangées>
Vérification : <commande> → <résultat : tests unitaires et scénarios>
Test appareil (Pixel, release) : <fait / non testé>
Revue QA : ✅ / ⚠️ / non requise (<motif>) — Non vérifié : <ou « rien »>
Description de PR : <titre = en-tête de commit ; quoi, pourquoi, comment testé, limites>
Décisions prises en route : <ou « aucune »>
À valider (PO) : <ou « aucun »>
```
