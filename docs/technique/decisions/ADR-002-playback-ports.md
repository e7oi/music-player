# ADR-002 — Playback ports: AudioEngine, VolumeEvents, TrackSourceOpener

**Status:** Active (validated 2026-10-15) · **Date:** 2026-10-15 · **Ticket:** MPL-017 · **Decisions:** D2, D23, D25 · **Sheets:** FR-001, BR-001, BR-002, BR-003

## Context

D2 keeps `media_kit` as the only engine behind an engine-independent `PlayerController`. The prototype's engine selector is not ported. The controller must also react to removable-volume ejection (D25) and skip tracks of absent disks (D23) without importing a channel or a database.

## Decision

Three ports under `domain/`, each at a real boundary, each with a fake in `test/`:

| Port | Location | Production adapter | Delivered by |
|---|---|---|---|
| `AudioEngine` | `domain/playback/ports/` | `data/audio/` over `media_kit` | MPL-017 |
| `VolumeEvents` | `domain/storage/ports/` | `platform/` over an EventChannel and `StorageVolumeCallback` | port and fake: MPL-017; adapter: MPL-035 |
| `TrackSourceOpener` | `domain/storage/ports/` | resolves (disk, relative path) to a file path (internal storage) or `fd://N` (SAF) | port and fake: MPL-017; adapters: MPL-018 / MPL-035 |

`AudioEngine` contract, written as dartdoc on the interface and as the executable suite `test/contract/audio_engine_contract.dart`:

- `open` loads without starting playback and may return before the duration is known; the duration arrives on `durationStream`. The `loading` state is not guaranteed.
- `play()` returns once playback is requested; `playing` is the intent and stays true across tracks.
- `completed` is emitted once per track.
- `stop()` returns only after the engine has stopped reading and released every resource, file descriptors included; it is idempotent.
- Problems are a `sealed class EngineIssue` with `EngineFailure` and `EngineWarning`. The adapter classifies: `end-file` with an error reason is always a failure; unclassified messages are warnings of kind `unclassified`.

The suite runs against `FakeAudioEngine` in CI and against the `media_kit` adapter in `integration_test/` on the Pixel, with a short synthetic audio file generated for the test (no personal content, D27).

`VolumeEvents` exposes the current set of available disks and a stream of `mounted` / `ejecting` / `removed` events keyed by filesystem UUID. Disk availability is held in memory by the controller in MPL-017; persistence comes with MPL-018.

## Consequences

- `PlayerController` is pure Dart and fully testable with fakes (BR-001 to BR-003).
- In MPL-017 the app can only play through the adapter contract test on device; real track sources arrive with MPL-018 and MPL-035.
- Classification tests from recorded real messages stay with MPL-010.

## Alternatives considered

- Keeping an engine selector (`engineFactories`, `switchEngine`): prototype only, rejected by D2.
- Controller listening to a channel directly: breaks rule 2 of the dependency rules and is not testable off device. Rejected.

## As-built

None (not implemented).
